require 'pp'
require 'Date'
require 'class.Date.extend.rb'
require 'class.Array.extend.rb'
require 'class.Symbol.extend.rb'
require 'module.Se.rb'
require 'module.ArchivesSpace.Konstants.rb'

class Find_Dates_in_String
    def initialize( param_H = {})
        if ( not param_H.is_a?( Hash ) ) then
            Se.puts "#{Se.lineno}: Expected param to be a type HASH."
            Se.pp param_H
            raise
        end

        @uid_string = "find_dates_in_string".upcase
        @param_H = param_H.merge( {} )        
        @param_H.keys do | param_H_key |
            case param_H_key
            when :morality_replace_option
                if ( not @param_H[ param_H_key ].is_a?( Hash ) ) then
                    Se.puts "#{Se.lineno}: Expected '#{param_H_key}' to be a type Hash, not '#{@param_H[ param_H_key ]}'"
                    Se.pp param_H
                    raise
                end
                @param_H[ param_H_key ].keys do | key, value |
                    case key
                    when :good
                        if ( not ( value.is_a?( Symbol ) and value.in?( [ :keep, :remove ] ) ) ) then
                            Se.puts "#{Se.lineno}: param_H[ :morality_replace_option ][ #{key} ] should be [ :keep, :remove ]"
                            Se.pp param_H
                            raise
                        end
                    when :bad
                        if ( not ( value.is_a?( Symbol ) and value.in?( [ :keep, :remove ] ) ) ) then
                            Se.puts "#{Se.lineno}: param_H[ :morality_replace_option ][ #{key} ] should be [ :keep, :remove ]"
                            Se.pp param_H
                            raise
                        end
                    else
                        Se.puts "#{Se.lineno}: unknown :morality_replace_option '#{key}', it should either be :good or :bad (obviously)"
                        Se.pp param_H
                        aise
                    end
                end
            when :thru_date_separator
#               nothing to check?
            when :only_do_these_pattern_names_A
                if ( not @param_H[ param_H_key ].is_a?( Array ) ) then
                    Se.puts "#{Se.lineno}: param_H[ :only_do_these_pattern_names_A ] should be an Array"
                    Se.pp param_H
                    raise
                end
            when :pattern_name_RE_A
                if ( not @param_H[ param_H_key ].is_a?( Array ) ) then
                    Se.puts "#{Se.lineno}: param_H[ :pattern_name_RE_A ] should be an Array"
                    Se.pp param_H
                    raise
                end
            when :default_century
                default_century = @param_H[ param_H_key ]
                if ( not (default_century.integer? and (default_century.length = 2 or (default.century.length = 4 and default_century[ 2..3 ] != "00" )))) then
                    Se.puts "#{Se.lineno}: Expected the :default_century to be NN00 (or NN), not '#{default_century}'"
                    raise
                end
                @param_H[ :default_century ] = @param_H[ param_H_key ][0..1]
            when :date_string_composition
                date_string_composition = @param_H[ param_H_key ]
                if ( not (date_string_composition.is_a?( Symbol ) and date_string_composition.in?( :only_dates, :dates_in_text ))) then
                    Se.puts "#{Se.lineno}: Expected :date_string_composition to be :only_dates or :dates_in_text, not '#{date_string_composition}'"
                    raise
                end
                @param_H[ :default_century ] = @param_H[ param_H_key ][0..1]
            else
                Se.puts "#{Se.lineno}: invalid param_H option: '#{param_H_key}'"
                pp @param_H
                raise
            end
        end
        if ( not @param_H.key?( :morality_replace_option ) )
            @param_H[ :morality_replace_option ] = { }
        end
        if ( not @param_H[ :morality_replace_option ].key?( :good ) ) then
            @param_H[ :morality_replace_option ][ :good ] = :remove
        end
        if ( not @param_H[ :morality_replace_option ].key?( :bad ) ) then
            @param_H[ :morality_replace_option ][ :bad ] = :keep
        end
        if ( not @param_H[ :thru_date_separator ] ) then
            @param_H[ :thru_date_separator ] = '-'
        end
        if ( not @param_H[ :only_do_these_pattern_names_A ] )
        then
            @param_H[ :only_do_these_pattern_names_A ] = [ ]
        end
        if ( not @param_H[ :pattern_name_RE_A ] )
        then
            @param_H[ :pattern_name_RE_A ] = [ %r{.} ]
        end
        if ( not @param_H[ :default_century ] )
        then
            @param_H[ :default_century ] = "19"
        end
        if ( not @param_H[ :date_string_composition ] ) then
            @param_H[ :date_string_composition ] = :dates_in_text
        end
        
        month_RE = %r{(?:([a-z]{3,11}|[a-z]{3,3}\.)){1}}xi.freeze      
        day_RE = %r{(?:([0-9]|[0-9][0-9])){1}}xi.freeze
        year4_RE = %r{[0-9]{4}}.freeze
        year2_RE = %r{[0-9]{2}}.freeze
        year_xx_RE = %r{(#{year4_RE}|#{year2_RE}){1}}.freeze
        extra_date_RE = %r{( (((#{month_RE})\s{0,3}              ((#{day_RE})\s{0,2},\s{0,3}){0,1}){0,1}      (#{year_xx_RE}))
                           | (((#{day_RE})\s{0,2}[\-\/]\s{0,2} ((#{month_RE})s{0,2}[\-\/]\s{0,2}){0,1}){0,1}  (#{year_xx_RE})))}xi.freeze

        @begin_date_delim_RE = %r{(^|,|\s){1}\s*}x
        @end_date_delim_RE   = %r{\s*(\s|,|$){1}}x
        thru_date_separator_RE = %r{(\s{0,2}#{@param_H[ :thru_date_separator ]}\s{0,2}){1}}x
        
        date_pattern_RE_S = Struct.new( :priority, :pattern_name, :length, :regex )     # :pattern_name and length are computed and added later
        # NOTE!!! pattern_names ending in __double are prioritized higher than __singles of the same priority.

        initial_date_pattern_RE_A_S = []  
        
                                        #  fmt001 Dates in '(mmm) (dd,) yy[yy]' format with spaces between 'mmm' 'dd', with from and thru dates (double)

        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt001__mmm_dd_yyyy__double> (?<month_M>#{month_RE})\s{0,3}       (?<day_M>#{day_RE})\s{0,2},\s{0,3}      (?<year_M>#{year4_RE})\
                                       #{thru_date_separator_RE}(?<thru_month_M>#{month_RE})\s{0,3}  (?<thru_day_M>#{day_RE})\s{0,2},\s{0,3} (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt001__mmm_dd_yyyy__single> (?<month_M>#{month_RE})\s{0,3}       (?<day_M>#{day_RE})\s{0,2},\s{0,3}      (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt001__mmm_dd_yy__double>   (?<month_M>#{month_RE})\s{0,3}       (?<day_M>#{day_RE})\s{0,2},\s{0,3}       (?<year_M>#{year2_RE})\
                                       #{thru_date_separator_RE}(?<thru_month_M>#{month_RE})\s{0,3}  (?<thru_day_M>#{day_RE})\s{0,2},\s{0,3}  (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt001__mmm_dd_yy__single>   (?<month_M>#{month_RE})\s{0,3}       (?<day_M>#{day_RE})\s{0,2},\s{0,3}       (?<year_M>#{year2_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt001__mmm_yyyy__double>    (?<month_M>#{month_RE})\s{0,3}                                                 (?<year_M>#{year4_RE})\
                                       #{thru_date_separator_RE}(?<thru_month_M>#{month_RE})\s{0,3}                                            (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt001__mmm_yyyy__single>    (?<month_M>#{month_RE})\s{0,3}                                                 (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt001__mmm_yy__double>      (?<month_M>#{month_RE})\s{0,3}                                                 (?<year_M>#{year2_RE})\
                                       #{thru_date_separator_RE}(?<thru_month_M>#{month_RE})\s{0,3}                                            (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt001__mmm_yy__single>      (?<month_M>#{month_RE})\s{0,3}                                                 (?<year_M>#{year2_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,  
                                    /(?<fmt001__yyyy__double>                                                                                       (?<year_M>#{year4_RE})\
                                       #{thru_date_separator_RE}                                                                               (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt001__yyyy__single>                                                                                       (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt001__yy__double>                                                                                          (?<year_M>#{year2_RE})\
                                       #{thru_date_separator_RE}                                                                                (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
    

                                        #  fmt002 = Dates in 'mmm [-/] (dd) [-/] yy[yy]' format, but a dash only between 'mmm-yy', with from and thru dates (double)
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil,
                                    /(?<fmt002__dd_mmm_yyyy__double> (?<day_M>#{day_RE})\s{0,2}[\-\/]\s{0,2}     (?<month_M>#{month_RE})\s{0,2}[\-\/]\s{0,2}       (?<year_M>#{year4_RE})\
                                       #{thru_date_separator_RE}(?<thru_day_M>#{day_RE})\s{0,2}[\-\/]\s{0,2}(?<thru_month_M>#{month_RE})\s{0,2}[\-\/]\s{0,2}  (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil,
                                    /(?<fmt002__dd_mmm_yyyy__single> (?<day_M>#{day_RE})\s{0,2}[\-\/]\s{0,2}     (?<month_M>#{month_RE})\s{0,2}[\-\/]\s{0,2}       (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil,
                                    /(?<fmt002__dd_mmm_yy__double>   (?<day_M>#{day_RE})\s{0,2}[\-\/]\s{0,2}     (?<month_M>#{month_RE})\s{0,2}[\-\/]\s{0,2}       (?<year_M>#{year2_RE})\
                                       #{thru_date_separator_RE}(?<thru_day_M>#{day_RE})\s{0,2}[\-\/]\s{0,2}(?<thru_month_M>#{month_RE})\s{0,2}[\-\/]\s{0,2}  (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil,
                                    /(?<fmt002__dd_mmm_yy__single>   (?<day_M>#{day_RE})\s{0,2}[\-\/]\s{0,2}     (?<month_M>#{month_RE})\s{0,2}[\-\/]\s{0,2}       (?<year_M>#{year2_RE}))/x )
    
     
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil, 
                                    /(?<fmt002__mmm_yyyy__double>                                                (?<month_M>#{month_RE})\s{0,2}-\s{0,2}            (?<year_M>#{year4_RE})\
                                       #{thru_date_separator_RE}                                            (?<thru_month_M>#{month_RE})\s{0,2}-\s{0,2}       (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil, 
                                    /(?<fmt002__mmm_yyyy__single>                                                (?<month_M>#{month_RE})\s{0,2}-\s{0,2}            (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil,
                                    /(?<fmt002__mmm_yy__double>                                                  (?<month_M>#{month_RE})\s{0,2}-\s{0,2}            (?<year_M>#{year2_RE})\
                                       #{thru_date_separator_RE}                                            (?<thru_month_M>#{month_RE})\s{0,2}-\s{0,2}       (?<thru_year_M>#{year_xx_RE})\
                     (?<extra_dates_M>(#{thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil, 
                                    /(?<fmt002__mmm_yy__single>                                                  (?<month_M>#{month_RE})\s{0,2}-\s{0,2}            (?<year_M>#{year2_RE}))/x )

                                        #  fmt003 = Dates in 'mmm  dd - yy[yy]' format, but no doubles
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt003__mmm_dd_yyyy__single>(?<month_M>#{month_RE})\s{0,3}     (?<day_M>#{day_RE})\s{0,1}-\s{0,1}     (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt003__mmm_dd_yy__single>  (?<month_M>#{month_RE})\s{0,3}     (?<day_M>#{day_RE})\s{0,1}-\s{0,1}     (?<year_M>#{year2_RE}))/x )
        
                                        #  fmt004 = Dates in 'mmm dd - dd, yy[yy] format (hybid double)
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt004__mmm_dd_dd_yyyy>     (?<month_M>#{month_RE})\s{0,3}     (?<day_M>#{day_RE})\
                                       #{thru_date_separator_RE}                                  (?<thru_day_M>#{day_RE})\s{0,2},\s{0,3}     (?<year_M>#{year4_RE}))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt004__mmm_dd_dd_yy>       (?<month_M>#{month_RE})\s{0,3}     (?<day_M>#{day_RE})\
                                      #{thru_date_separator_RE}                                   (?<thru_day_M>#{day_RE})\s{0,2},\s{0,3}     (?<year_M>#{year2_RE}))/x )
    
    
        initial_date_pattern_RE_A_S.each_index do | date_pattern_idx |  
            stringer = initial_date_pattern_RE_A_S[ date_pattern_idx ].regex.inspect.gsub( / /,"" )
            pattern_name = stringer[ stringer.index( '<' ) + 1 .. stringer.index( '>' ) - 1 ]
            if ( not pattern_name.match?( /^fmt[0-9]{3}__/ ) ) then
                Se.puts "#{Se.lineno}: I shouldn't be here: pattern_name doesn't start with /fmtNNN__'#{pattern_name}'"
                raise
            end             
            initial_date_pattern_RE_A_S[ date_pattern_idx ].length = stringer.length
            initial_date_pattern_RE_A_S[ date_pattern_idx ].pattern_name = pattern_name
        end
        
        @date_pattern_name_H_of_pattern_RE_A_idx = {}
        @date_pattern_RE_A_S = [ ]
        initial_date_pattern_RE_A_S.each_index do | date_pattern_idx |
            pattern_name = initial_date_pattern_RE_A_S[ date_pattern_idx ].pattern_name
            @param_H[ :pattern_name_RE_A ].each do | pattern_name_RE |
                if ( pattern_name =~ pattern_name_RE ) then
                    @date_pattern_RE_A_S.push( initial_date_pattern_RE_A_S[ date_pattern_idx ] )
                    if ( @date_pattern_name_H_of_pattern_RE_A_idx.key?( pattern_name ) ) then
                        Se.puts "#{Se.lineno}: I shouldn't be here: duplicate pattern_name '#{pattern_name}'"
                        raise
                    end   
                    @date_pattern_name_H_of_pattern_RE_A_idx[ pattern_name ] = @date_pattern_RE_A_S.maxindex
                    break
                end
            end
        end

        @date_pattern_RE_A_S = @date_pattern_RE_A_S.sort_by { | e_S | [ 0.0 - e_S.priority - ((e_S.pattern_name =~ /__double$/i) ? 0.1 : 0.0), 0 - e_S.length ] }
        # pp @date_pattern_RE_A_S; exit
    end
    attr_reader :date_pattern_name_H_of_pattern_RE_A_idx, :date_pattern_RE_A_S
    
    def do_find( param_string_with_dates )
        @date_found_A_S = [ ] 
        process_string = "" + param_string_with_dates
        # Se.puts "Starting string = #{process_string}"
        
        @date_pattern_RE_A_S.each do | date_pattern_RE_S |  
            date_pattern_RE = date_pattern_RE_S.regex
            # Se.puts date_pattern_RE.inspect.gsub(/ /,"")
            # Se.puts '-------------------------------------------------------------------------------'
            # Se.puts 
            offset = 0
            loop_detector = 0
            catch :next_date do
                loop do
                    if ( (loop_detector += 1) > 100) then
                        Se.puts "#{Se.lineno}: I shouldn't be here: loop_detector > 100"
                        raise
                    end   
                        
                    throw :next_date if ( offset > process_string.maxindex )
                    pattern_RE = %r{(?<begin_M>#{@begin_date_delim_RE})(?<date_M>#{date_pattern_RE})(?<end_M>#{@end_date_delim_RE})}
                    # Se.p pattern_RE.inspect.gsub(/ /,"")
                    pattern_RE_match_O = process_string.match( pattern_RE, offset )
                    throw :next_date if ( pattern_RE_match_O == nil )
                    offset = pattern_RE_match_O.offset( :date_M )[1] - 1
                    pattern_name = pattern_RE_match_O.names[ 2 ]
                    if ( @param_H[ :only_do_these_pattern_names_A ].length > 0 and not pattern_name.in?( @param_H[ :only_do_these_pattern_names_A ] )) then
                        Se.puts "Marched to: #{pattern_name}, but skipping..."
                        throw :next_date
                    end

                    # Se.puts "Doing pattern: #{pattern_name}"
                    # Se.puts "process_string = '#{process_string}'"
                    # Se.pp pattern_RE_match_O.named_captures
                    pattern_RE_named_captures = pattern_RE_match_O.named_captures
                    begin_M = pattern_RE_named_captures[ 'begin_M' ]
                    date_M = pattern_RE_named_captures[ 'date_M' ]
                    end_M = pattern_RE_named_captures[ 'end_M' ]
                    begin_M_and_date_MM = begin_M + date_M
                    replace_uid = begin_M + @uid_string + "_" + "%010d" % (@date_found_A_S.length + 1 )
                    # pp pattern_RE_match_O.offset( :begin_M )
                    # pp pattern_RE_match_O.offset( :date_M )
                    # pp pattern_RE_match_O.offset( :end_M )
                    # pp "offset = #{offset}"
                    # puts "begin_M_and_date_MM = '#{begin_M_and_date_MM}'"

                    repl_offset_start = pattern_RE_match_O.offset( :begin_M )[0]
                    process_string[ repl_offset_start .. repl_offset_start + begin_M_and_date_MM.maxindex ] = replace_uid 
                    offset = pattern_RE_match_O.offset( :begin_M )[0] + replace_uid.length
                    # Se.puts "#{Se.lineno}: matched on #{pattern_name}, '#{pattern_RE_named_captures[ 'begin_M' ]}' '#{date_M}' '#{pattern_RE_named_captures[ 'end_M' ]}'"
                    
                    date_found_S = Struct.new(  :morality,
                                                :replace_uid,
                                                :as_date_S ).new(   K.undefined,
                                                                    replace_uid,
                                                                    Struct.new( :pattern_piece_A,
                                                                                :pattern_name,
                                                                                :from_date,
                                                                                :thru_date,
                                                                                :error_msg ).new(   [ begin_M, date_M, end_M ],
                                                                                                    pattern_name,
                                                                                                    "",
                                                                                                    "",
                                                                                                    K.undefined   ))

                    s_C = Struct.new( :date, :strptime_O )
                    date_validation_S = Struct.new( :from, :thru ).new( s_C.new( "", nil ), s_C.new( "", nil ) )
                    
                    date_validation_S.each_pair do | ft_sym, s |    # ft_sym = from_thru_symbol. Can't be "each" as that just passes out the value, and members doesn't seem to work.
                        case ft_sym
                        when :from
                            year =  pattern_RE_named_captures[ 'year_M' ]
                            month = pattern_RE_named_captures[ 'month_M' ]
                            if ( not month == nil ) then
                                month_RE_match_O = month.match( /^(?<month_M>#{K.month_RE})/, 0 )
                                if ( not month_RE_match_O == nil ) then
                                    month_RE_named_captures = month_RE_match_O.named_captures
                                    month = month_RE_named_captures[ 'month_M' ]
                                end
                            end
                            day =   pattern_RE_named_captures[ 'day_M' ] 
                        when :thru
                            if ( pattern_name.match?( /_mmm_dd_dd_/i )) then
                                year =  pattern_RE_named_captures[ 'year_M' ]
                                month = pattern_RE_named_captures[ 'month_M' ]
                                day =   pattern_RE_named_captures[ 'thru_day_M' ] 
                            else
                                year =  pattern_RE_named_captures[ 'thru_year_M' ]
                                month = pattern_RE_named_captures[ 'thru_month_M' ]
                                if ( not month == nil ) then
                                    month_RE_match_O = month.match( /^(?<month_M>#{K.month_RE})/, 0 )
                                    if ( not month_RE_match_O == nil ) then
                                        month_RE_named_captures = month_RE_match_O.named_captures
                                        month = month_RE_named_captures[ 'month_M' ]
                                    end
                                end
                                day =   pattern_RE_named_captures[ 'thru_day_M' ] 
                                break if ( pattern_name.match?( /__single/i ) and ( year == nil and month == nil and day == nil ) ) 
                            end
                        else
                            Se.puts "#{Se.lineno}: I shouldn't be here: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' > '#{date_M}' ft_sym not :from or :thru"
                            raise
                        end   
                        # p month, day, year
                        if ( year == nil or ( month == nil and day )) then
                            Se.puts "#{Se.lineno}: I shouldn't be here: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' > '#{date_M}' year == nil or ( month == nil and day)!"
                            Se.pp pattern_RE_match_O
                            raise
                        end     

                        if ( year.length == 2 and month == nil and day == nil and not pattern_name.in?( ['fmt001__yy__double', 'fmt001__yyyy__double' ] ) ) then
                            stringer = "#{Se.lineno}: bad date: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' -> '#{date_M}' isolated 2 digit number" 
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
    
                        if ( day and not day.integer? ) then
                            stringer = "#{Se.lineno}: bad date: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' -> '#{date_M}' day not numeric: '#{day}'" 
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                        if ( not year.integer? ) then
                            stringer = "#{Se.lineno}: bad date: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' -> '#{date_M}' year not numeric: '#{year}'"
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end      
                        if ( year.length == 2 ) then
                            case ft_sym
                            when :from
                                year = @param_H[ :default_century ] + year             # These are strings
                            when :thru
                                year = date_validation_S.from.date[ 0 .. 1] + year     # Take the century from the converted from_year, it might have been YYYY
                            end
                        end

                        testdate = year
                        case ft_sym
                        when :from 
                            testdate += (month) ? " #{month}" : " Jan"
                            testdate += (day)   ? " #{day}"   : " 01"
                        when :thru
                            testdate += (month) ? " #{month}" : " Dec"
                            testdate += (day)   ? " #{day}"   : " 01"       # This will be set to the end-of-month below
                        else
                            Se.puts "#{Se.lineno}: I shouldn't be here: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' > '#{date_M}' ft_sym not :from or :thru"
                            raise
                        end 
                        testdate.sub!( /\./, "" )           # Take the period off the months (eg Feb.)
                        begin
                            strptime_O = Date::strptime( testdate, "%Y %b %d" )
                        rescue
                            stringer = "#{Se.lineno}: bad date: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' -> '#{date_M}' -> '#{testdate}' strptime conversion failed"
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                        if ( strptime_O.year < 0 ) then
                            stringer = "#{Se.lineno}: bad date: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' -> '#{date_M}' -> '#{strptime_O}' negative year"
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                        if ( day == nil and strptime_O.day != 1 ) then
                            Se.puts "#{Se.lineno}: I shouldn't be here: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' -> '#{date_M}' -> '#{strptime_O} day != 1"
                            raise
                        end
                        if ( day == nil and ft_sym == :thru ) then
                            strptime_O = strptime_O.last_day_of_month
                        end
                        # Se.puts "#{Se.lineno}: good date: #{pattern_name},#{ft_sym}: '#{begin_M_and_date_MM}' -> '#{strptime_O}'"
                        as_date_yyyy_mm_dd  = strptime_O.strftime( '%Y' )
                        as_date_yyyy_mm_dd += strptime_O.strftime( '-%m' ) if ( month )
                        as_date_yyyy_mm_dd += strptime_O.strftime( '-%d' ) if ( day )
                        date_validation_S[ ft_sym ].date = as_date_yyyy_mm_dd
                        date_validation_S[ ft_sym ].strptime_O = as_date_yyyy_mm_dd
                        
                        date_found_S.as_date_S.from_date = date_validation_S.from.date
                        date_found_S.as_date_S.thru_date = date_validation_S.thru.date
    
                        if ( ft_sym == :thru and pattern_RE_named_captures.key?( 'extra_dates_M' ) and pattern_RE_named_captures[ 'extra_dates_M' ] != "" ) then
                            stringer = "#{Se.lineno}: bad date: #{pattern_name}: '#{begin_M_and_date_MM}' -> '#{date_M}' extra thru dates found '#{pattern_RE_named_captures[ 'extra_dates_M' ]}'" 
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                    end
                    if ( date_validation_S.thru[ 1 ] and date_validation_S.from[ 1 ] > date_validation_S.thru[ 1 ] ) then
                        stringer = "#{Se.lineno}: bad date: #{r_idx}: '#{begin_M_and_date_MM}' From date > thru date"
                        Se.puts stringer
                        date_found_S.morality = :bad
                        date_found_S.as_date_S.error_msg = stringer
                        @date_found_A_S << date_found_S
                        throw :next_date
                    end
                    # Se.pp @date_found_A_S 
                    date_found_S.morality = :good
                    date_found_S.as_date_S.error_msg = ""
                    @date_found_A_S << date_found_S
                end
            end 
        end 
        # Se.puts "Before replace, process_string = #{process_string}"
        # Se.pp @date_found_A_S
        # exit
        
        process_string_with_all_dates_removed = process_string + ""
        @date_found_A_S.each do | date_found_S |
            case @param_H[ :morality_replace_option ][ date_found_S.morality ]
            when :keep
                begin
                    process_string[ date_found_S.replace_uid ]                        = date_found_S.as_date_S.pattern_piece_A[ 0 ] + date_found_S.as_date_S.pattern_piece_A[ 1 ]
                    process_string_with_all_dates_removed[ date_found_S.replace_uid ] = ""
                rescue
                    Se.puts "#{Se.lineno}: replace_uid failed"
                    Se.puts "process_string = #{process_string}"
                    Se.pp date_found_S
                    raise
                end
            when :remove
                begin
                    process_string[ date_found_S.replace_uid ]                        = ""
                    process_string_with_all_dates_removed[ date_found_S.replace_uid ] = ""
                rescue
                    Se.puts "#{Se.lineno}: replace_uid failed"
                    Se.puts "process_string = #{process_string}"
                    Se.pp date_found_S
                    raise
                end
            else
                Se.puts "#{Se.lineno}: I shouldn't be here, unknown replace_option for morality '#{date_found_S.morality}' -> '#{@param_H[ :morality_replace_option ][ date_found_S.morality ]}'"
                Se.pp pattern_found_A
                raise
            end
        end
        
        @good_date_A_S = [ ]
        @bad_date_A_S = [ ]
        @date_found_A_S.each do | date_found_S |
            case date_found_S.morality
            when :good 
                @good_date_A_S << date_found_S.as_date_S
            when :bad
                @bad_date_A_S << date_found_S.as_date_S
            else
                Se.puts "#{Se.lineno}: I shouldn't be here: amoral date: '#{date_found_S.morality}', #{date_found_S}"
                raise
            end
        end
        # pp process_string    
        case @param_H[ :date_string_composition ]
        when :dates_in_text 
            if (process_string_with_all_dates_removed =~ K.month_RE ) then
                Se.puts "#{Se.lineno}: Warning possible ummatched date in '#{process_string_with_all_dates_removed}'"
            end
        when :only_dates
            if (process_string_with_all_dates_removed != "" ) then
                Se.puts "#{Se.lineno}: Date error  '#{param_string_with_dates}'"
                Se.puts "#{Se.lineno}: Extra text: '#{process_string_with_all_dates_removed}'"  if ( param_string_with_dates != process_string_with_all_dates_removed )
                if ( @good_date_A_S.length > 0 ) then
                    Se.puts "#{Se.lineno}: #{@good_date_A_S.length} good-dates moved to bad-dates array after row #{@bad_date_A_S.length}"
                    @bad_date_A_S += @good_date_A_S
                    @good_date_A_S = [ ]
                end
                process_string = param_string_with_dates
            end
        end
        return process_string
    end
    attr_reader :date_found_A_S, :good_date_A_S, :bad_date_A_S

    def good_date_A_S?
        return (self.good_date_A_S.length > 0)
    end
    
    def bad_date_A_S?
        return (self.bad_date_A_S.length > 0)
    end

end


