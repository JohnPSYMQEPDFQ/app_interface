require 'Date'
require 'class.Date.extend.rb'
require 'class.Array.extend.rb'
require 'class.Object.extend.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'

class Find_Dates_in_String
    def initialize( option_H = {})
    
        binding.pry if ( respond_to? :pry )
        
        if ( not option_H.is_a?( Hash ) ) then
            SE.puts "#{SE.lineno}: Expected param to be a type HASH."
            SE.q { 'option_H' }
            raise
        end

        @option_H = option_H.merge( {} )
        @option_H.each_key do | option_H_key |
            case option_H_key
            when :debug_options
                case true
                when @option_H[ option_H_key ].is_a?( Hash )
                    @option_H[ option_H_key ].each_pair do | key, value |
                        if ( not key.is_a?( Symbol ) ) then
                            SE.puts "#{SE.lineno}: Expected '#{key}' to be of type 'Symbol', not '#{key.class}'"
                            SE.q { 'key' }
                            SE.q { 'option_H' }
                            raise
                        end
                        SE.puts "#{SE.lineno}: Debug option: ':#{key}' = '#{value}' set.  Note: Option spelling is NOT checked!!!"
                    end
                when @option_H[ option_H_key ].is_a?( Symbol )  
                    h = { @option_H[ option_H_key ] => nil }
                    SE.puts "#{SE.lineno}: Debug option: ':#{@option_H[ option_H_key]}' = 'nil' set.  Note: Option spelling is NOT checked!!!"
                    @option_H[ option_H_key ] = h
                when @option_H[ option_H_key ].is_a?( Array )
                    h = {}
                    @option_H[ option_H_key ].each do | element |
                        if ( not element.is_a?( Symbol ) ) then
                            SE.puts "#{SE.lineno}: Expected '#{element}' to be of type 'Symbol', not '#{element.class}'"
                            SE.q { 'element' }
                            SE.q { 'option_H' }
                            raise
                        end
                        SE.puts "#{SE.lineno}: Debug option: ':#{element}' = 'nil' set.  Note: Option spelling is NOT checked!!!"
                        h[ element ] = nil                        
                    end
                    @option_H[ option_H_key ] = h
                else
                    SE.puts "#{SE.lineno}: Expected '#{option_H_key}' to be of type Symbol, Hash, or Array, not '#{@option_H[ option_H_key ].class}'"
                    SE.q { 'option_H' }
                    raise
                end               
            when :morality_replace_option
                if ( not @option_H[ option_H_key ].is_a?( Hash ) ) then
                    SE.puts "#{SE.lineno}: Expected '#{option_H_key}' to be a type Hash, not '#{@option_H[ option_H_key ].class}'"
                    SE.q { 'option_H' }
                    raise
                end
                @option_H[ option_H_key ].each_pair do | key, value |
                    case key
                    when :good
                        if ( not ( value.is_a?( Symbol ) and value.in?( [ :keep, :replace, :remove, :remove_from_end ] ) ) ) then
                            SE.puts "#{SE.lineno}: option_H[ :morality_replace_option ][ #{key} ] should be [ :keep, :replace, :remove, :remove_from_end ]"
                            SE.q { 'option_H' }
                            raise
                        end
                    when :bad
                        if ( not ( value.is_a?( Symbol ) and value.in?( [ :keep, :remove ] ) ) ) then
                            SE.puts "#{SE.lineno}: option_H[ :morality_replace_option ][ #{key} ] should be [ :keep, :remove ]"
                            SE.q { 'option_H' }
                            raise
                        end
                    else
                        SE.puts "#{SE.lineno}: unknown :morality_replace_option '#{key}', it should either be :good or :bad (obviously)"
                        SE.q { 'option_H' }
                        raise
                    end
                end
            when :thru_date_separators
                case true
                when @option_H[ option_H_key ].is_a?( Array ) then
                    ary = []
                    @option_H[ option_H_key ].each do | separator |
                        separator.strip!
                        ary << Regexp::escape( separator )
                    end
                    @option_H[ option_H_key ] = ary.join("|") 
                when @option_H[ option_H_key ].is_a?( String )
                    @option_H[ option_H_key ] = Regexp::escape( @option_H[ option_H_key ] )
                else
                    SE.puts "#{SE.lineno}: Expected '#{option_H_key}' to be of type Array or String not '#{@option_H[ option_H_key ].class}'"
                    SE.puts "#{SE.lineno}: If more than one is needed, pass them in as an array.  The default is: '-| to | through '."
                    SE.q { 'option_H' }
                    raise
                end            
            when :date_text_separators
                if ( @option_H[ option_H_key ].is_a?( Symbol ) ) then
                    if ( @option_H[ option_H_key ] == :none ) then
                        @option_H[ :date_text_separators ] = 255.chr                        #  Use 255.chr \xFF for none
                    else
                        SE.puts "#{SE.lineno}: option_H[ :date_text_separators ] should be :none, or [xyz] (where xyz = some separators)."
                        SE.q { 'option_H' }
                        raise
                    end
                else
                    if ( not ( @option_H[ option_H_key ].length > 1 and @option_H[ option_H_key ] =~ /\[\W\]+/ ) ) then
                        SE.puts "#{SE.lineno}: option_H[ :date_text_separators ] should be :none, or [xyz] (where xyz = some separators)."
                        SE.q { 'option_H' }
                        raise
                    end
                end
            when :pattern_name_RES
                if ( not @option_H[ option_H_key ].is_a?( String ) ) then
                    SE.puts "#{SE.lineno}: option_H[ :pattern_name_RES ] should be an String that will convert to a regexp."
                    SE.q { 'option_H' }
                    raise
                end
            when :default_century
                default_century = @option_H[ option_H_key ]
                if ( not (default_century.integer? and (default_century.length == 2 or (default_century.length == 4 and default_century[ 2..3 ] == "00" )))) then
                    SE.puts "#{SE.lineno}: Expected the :default_century to be NN00 (or NN), not '#{default_century}'"
                    raise
                end
                @option_H[ option_H_key ] = @option_H[ option_H_key ][0..1]
            when :yyyy_min_value
                if ( not (@option_H[ option_H_key ].integer? and @option_H[ option_H_key ].length == 4 )) then
                    SE.puts "#{SE.lineno}: Expected the :yyyy_min_value to be NNNN, not '#{@option_H[ option_H_key ]}'"
                    raise
                end
            when :yyyy_max_value
                if ( not (@option_H[ option_H_key ].integer? and @option_H[ option_H_key ].length == 4 )) then
                    SE.puts "#{SE.lineno}: Expected the :yyyy_max_value to be NNNN, not '#{@option_H[ option_H_key ]}'"
                    raise
                end
            when :date_string_composition
                if ( not (@option_H[ option_H_key ].is_a?( Symbol ) and @option_H[ option_H_key ].in?( [ :only_dates, :dates_in_text ] ))) then
                    SE.puts "#{SE.lineno}: Expected :date_string_composition to be :only_dates or :dates_in_text, not '#{@option_H[ option_H_key ]}'"
                    raise
                end
            when :nn_mmm_nn_day_year_order
                if ( not (@option_H[ option_H_key ].is_a?( Symbol ) and @option_H[ option_H_key ].in?( [ :dd_mm_yy, :yy_mm_dd ] ))) then
                    SE.puts "#{SE.lineno}: Expected :nn_mmm_nn_day_year_order to be :dd_mm_yy or :yy_mm_dd, not '#{@option_H[ option_H_key ]}'"
                    raise
                end
            when :nn_nn_nn_date_order
                if ( not (@option_H[ option_H_key ].is_a?( Symbol ) and @option_H[ option_H_key ].in?( [ :mm_dd_yy, :dd_mm_yy, :yy_mm_dd ] ))) then
                    SE.puts "#{SE.lineno}: Expected :nn_nn_nn_date_order to be :mm_dd_yy, :dd_mm_yy, or :yy_mm_dd not '#{@option_H[ option_H_key ]}'"
                    raise
                end
            when :sort
                if ( not ( [true, false].include?( @option_H[ option_H_key ] ) ) ) then
                    SE.puts "#{SE.lineno}: Expected '#{option_H_key}' to be true or false, not '#{@option_H[ option_H_key ]}'"
                    SE.q { 'option_H' }
                    raise
                end
            else
                SE.puts "#{SE.lineno}: invalid option_H option: '#{option_H_key}'"
                SE.q { '@option_H' }
                raise
            end
        end

        if ( not @option_H.key?( :debug_options ) )
            @option_H[ :debug_options ] = []
        end
        if ( not @option_H.key?( :morality_replace_option ) )
            @option_H[ :morality_replace_option ] = { }
        end
        if ( not @option_H[ :morality_replace_option ].key?( :good ) ) then
            @option_H[ :morality_replace_option ][ :good ] = :remove_from_end
        end
        if ( not @option_H[ :morality_replace_option ].key?( :bad ) ) then
            @option_H[ :morality_replace_option ][ :bad ] = :keep
        end
        if ( not @option_H.key?( :thru_date_separators ) ) then
            @option_H[ :thru_date_separators ] = '-|/| to | through '
        end
        if ( not @option_H.key?( :date_text_separators ) ) then
            @option_H[ :date_text_separators ] = '[|]| and '           
        end
        if ( not @option_H.key?( :pattern_name_RES ) )
        then
            @option_H[ :pattern_name_RES ] = '.'
        end
        if ( not @option_H.key?( :default_century ) )
        then
            @option_H[ :default_century ] = ""              # If the default century is blank, only look for 4 digit dates.
        end
        if ( not @option_H.key?( :date_string_composition ) ) then
            @option_H[ :date_string_composition ] = :dates_in_text
        end
        if ( not @option_H.key?( :yyyy_min_value ) ) then
            @option_H[ :yyyy_min_value ] = '1800'
        end
        if ( not @option_H.key?( :yyyy_max_value ) ) then
            @option_H[ :yyyy_max_value ] = '2100'
        end
        if ( not @option_H.key?( :nn_mmm_nn_day_year_order ) ) then
            @option_H[ :nn_mmm_nn_day_year_order ] = :dd_mm_yy
        end
        if ( not @option_H.key?( :nn_nn_nn_date_order ) ) then
            @option_H[ :nn_nn_nn_date_order ] = :mm_dd_yy
        end
        if ( not @option_H.key?( :sort ) ) then
            @option_H[ :sort ] = true
        end

#       dash_RES                    = "\\s{0,2}-\\s{0,2}"
        slash_dash_RES              = "\\s{0,2}(?:-|/){1}\\s{0,2}"          # Note the \\ because it's a double quoted string.
        space_dash_RES              = "\\s{0,2}(?:\\s|-){1}\\s{0,2}"
        space_dash_slash_RES        = "\\s{0,2}(?:\\s|-|/){1}\\s{0,2}"
        comma_RES                   = "\\s{0,2},\\s{0,2}"
        space_comma_RES             = "\\s{0,2}(?:\\s|,){1}\\s{0,2}"
        space_RES                   = "\\s{0,3}" 

        n_nn_RES                    = "(?:#{K.day_RES}|#{K.numeric_month_RES})" 
        year_RES                    = ( @option_H[ :default_century ].empty? ) ? "#{K.year4_RES}" : "(#{K.year2_RES}|#{K.year4_RES})"  
                                                                            # For possible year positions
                                                                            # If no default year, only look for 4 digit years.

        @thru_date_separator_RES    = "(?:\\s{0,2}(?:#{@option_H[ :thru_date_separators ]})\\s{0,2}){1}"
        @thru_date_begin_delim_RES  = "^\\s*"
#       @begin_delim_RES            = "(?:(?:\\A|\\s|#{@option_H[ :date_text_separators ]}))*"    
        @begin_delim_RES            = "(?:(?:\\A|\\s+|\\W|\\s*#{@option_H[ :date_text_separators ]}\\s*))"    
        @end_delim_RES              = "\\s*(?:#{@thru_date_separator_RES}|\\W|\\Z){1}"     # The \\W will match any separators

        date_pattern_RES_S = Struct.new( :pattern_name, :pattern_RES )      # The :pattern_name and length are computed and added later.
                                                                            # Literal spaces in the pattern are removed.  Spaces are just
                                                                            # for ease of reading. To match a space, use \\s instead.
                                                                            # And, it HAS to be \\ because it's a double quoted string.

        initial__date_pattern_RES_S__A = []

                                        #   fmt002__ = possible year 

        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt002__yyyy>           (?<year_M>#{year_RES}))" )
 

                                        #   fmt003__ = Dates in 'MMM dd, yyyy' format with spaces between 'MMM' 'dd'

        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt003__MMM_dd_yyyy>    (?<month_M>#{K.alpha_month_RES})#{space_RES}     (?<day_M>#{n_nn_RES})#{comma_RES}     (?<year_M>#{year_RES}))" )


                                        #   fmt005__ = Dates in 'MMM yyyy' or 'MMM-yyyy' format
                                        
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt005__MMM_yyyy>       (?<month_M>#{K.alpha_month_RES})#{space_dash_RES}     (?<year_M>#{year_RES}))" )
                
                
                                        #   fmt006__ = Dates in 'mm yyyy' or 'mm-yyyy' format
                                        
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt006__mm_yyyy>        (?<month_M>#{K.numeric_month_RES})#{slash_dash_RES}   (?<year_M>#{year_RES}))" )

         
                                        #   fmt007__ = Dates in 'yyyy MMM' or 'yyyy-MMM' format
                                        
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt007__yyyy_MMM>       (?<year_M>#{year_RES})#{space_dash_RES}    (?<month_M>#{K.alpha_month_RES}))" )

         
                                        #   fmt008__ = Dates in 'yyyy mm' or 'yyyy-mm' format
                                        
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt008__yyyy_mm>        (?<year_M>#{year_RES})#{slash_dash_RES}    (?<month_M>#{K.numeric_month_RES}))" )


                                        #   fmt009__ = Dates in 'dd [-/] MMM [-/] yyyy' or ' yyyy [-/] MMM [-/] dd' format

        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt009__nn_MMM_nn>  (?:" +    
                    "   (?: (?<nn_1st_M>#{n_nn_RES})#{space_dash_slash_RES} (?<month_M>#{K.alpha_month_RES})#{space_dash_slash_RES} (?<nn_3rd_M>#{n_nn_RES}))" +
                    "|  (?: (?<nn_1st_M>#{n_nn_RES})#{space_dash_slash_RES} (?<month_M>#{K.alpha_month_RES})#{space_dash_slash_RES} (?<nn_3rd_M>#{year_RES}))" +
                    "|  (?: (?<nn_1st_M>#{year_RES})#{space_dash_slash_RES} (?<month_M>#{K.alpha_month_RES})#{space_dash_slash_RES} (?<nn_3rd_M>#{n_nn_RES}))" +
                "  ) )" )


                                         #   fmt011__ = Dates in 'MMM dd - dd, yyyy format (hybid double)

        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt011__MMM_dd_dd_yyyy>     (?<month_M>#{K.alpha_month_RES})#{space_RES}    (?<day_M>#{n_nn_RES})"+
                                                              "#{@thru_date_separator_RES} (?<thru_day_M>#{n_nn_RES})#{space_comma_RES}  (?<year_M>#{year_RES}))" )


                                         #   fmt012__ = Dates in 'MMM dd - MMM dd, yyyy format (hybid double)
                                         
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt012__MMM_dd_MMM_dd_yyyy> (?<month_M>#{K.alpha_month_RES})#{space_RES}             (?<day_M>#{n_nn_RES})"+
              "#{@thru_date_separator_RES} (?<thru_month_M>#{K.alpha_month_RES})#{space_comma_RES}  (?<thru_day_M>#{n_nn_RES})#{comma_RES}(?<year_M>#{year_RES}))" )

                                        #   fmt013__ = Dates in 'MMM-MMMM yy[yy] format (hybid double) Note there's NO COMMA after the month

        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt013__MMM_MMM_yyyy>       (?<month_M>#{K.alpha_month_RES})#{space_RES}"+
              "#{@thru_date_separator_RES} (?<thru_month_M>#{K.alpha_month_RES})#{space_RES}                                              (?<year_M>#{year_RES}))" )


                                        #   fmt014__ = All numeric dates 'nn [-/] nn [-/] nn ' format,  the 1st and 3rd positions could be 1 or 4 digets (days or years)
                                        
         initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt014__nn_nn_nn>   (?:" +
                    "   (?: (?<nn_1st_M>#{n_nn_RES})#{slash_dash_RES}  (?<nn_2nd_M>#{n_nn_RES})#{slash_dash_RES}   (?<nn_3rd_M>#{year_RES}))" +
#                   "|  (?: (?<nn_1st_M>#{n_nn_RES})#{slash_dash_RES}  (?<nn_2nd_M>#{n_nn_RES})#{slash_dash_RES}   (?<nn_3rd_M>#{year_RES}))" +
                    "|  (?: (?<nn_1st_M>#{year_RES})#{slash_dash_RES}  (?<nn_2nd_M>#{n_nn_RES})#{slash_dash_RES}   (?<nn_3rd_M>#{n_nn_RES}))" +
                "  ) )" )

#       Set the pattern_name and length
        initial__date_pattern_RES_S__A.each_index do | idx |
            stringer = initial__date_pattern_RES_S__A[ idx ].pattern_RES.gsub( / /,'' )
            pattern_name = stringer[ stringer.index( '<' ) + 1 .. stringer.index( '>' ) - 1 ]
            if ( not pattern_name.match?( /^fmt\d{3}__/ ) ) then
                SE.puts "#{SE.lineno}: I shouldn't be here: pattern_name doesn't start with /fmtNNN__'#{pattern_name}'"
                raise
            end
            initial__date_pattern_RES_S__A[ idx ].pattern_RES  = stringer          # get rid of the literal spaces.
            initial__date_pattern_RES_S__A[ idx ].pattern_name = pattern_name
        end

#       Load date patterns to use
        @date_pattern_RES_S__A = [ ]
        initial__date_pattern_RES_S__A.each_index do | idx |
            pattern_name = initial__date_pattern_RES_S__A[ idx ].pattern_name
            if ( pattern_name.match?( /#{@option_H[ :pattern_name_RES ]}/ )) then
                @date_pattern_RES_S__A.push( initial__date_pattern_RES_S__A[ idx ] )
            end
        end
        if ( @date_pattern_RES_S__A.length == 0 ) then
            SE.puts "#{SE.lineno}: No patterns selected based on RE: #{@option_H[ :pattern_name_RES ]}"
            raise
        end

#       Check for duplicate pattern names
        @pattern_cnt_H = {}
        @date_pattern_RES_S__A.each_index do | idx |
            pattern_name = date_pattern_RES_S__A[ idx ].pattern_name
            if ( @pattern_cnt_H.key?( pattern_name ) ) then
                SE.puts "#{SE.lineno}: I shouldn't be here: duplicate pattern_name '#{pattern_name}'"
                raise
            end
            @pattern_cnt_H[ pattern_name ] = 0
        end

        
        @possible_date_C = Struct.new( :pattern_name,
                                       :regexp,
                                       :match_O,
                                     )
        
        @date_clump_C = Struct.new( :full_match_string,
                                    :uid,                       
                                    :beginning_offset,   
                                    :date_match_S__A,
                                    :morality,
                                    :error_msg,
                                    keyword_init: true
                                    )   do
                                            def judge_date( judgement, input_error_msg, print = true )
                                                SE.puts input_error_msg if ( print )
                                                SE.puts ""              if ( print )
                                                self.error_msg  = ""    if ( error_msg == nil )
                                                self.error_msg += "  "  if ( error_msg != "")
                                                self.error_msg += input_error_msg
                                                return if ( judgement == nil )
                                                if ( morality == nil ) then
                                                    self.morality = judgement
                                                    return
                                                end
                                                if ( morality == :bad ) then
                                                    return if ( judgement == :bad )
                                                    SE.puts "#{SE.lineno}: Date morality was already bad, not changed to #{judgement}"
                                                    return
                                                end
                                                SE.puts "#{SE.lineno}: Date morality was already #{morality}, changed to #{judgement}"
                                                self.morality = judgement
                                                return
                                            end
                                            def from
                                                return date_match_S__A[ 0 ]
                                            end
                                            def thru
                                                return date_match_S__A[ 1 ]
                                            end      
                                            def from_date
                                                date_match_S = from
                                                if ( date_match_S == nil ) then
                                                    SE.puts "#{SE.lineno}: I shouldn't be here: date_clump_S without a from date"
                                                    SE.q { :self }
                                                    raise
                                                else
                                                    return date_match_S.as_date
                                                end
                                            end
                                            def thru_date
                                                date_match_S = thru
                                                if ( date_match_S == nil ) then
                                                    return ""
                                                else
                                                    return date_match_S.as_date
                                                end
                                            end    
                                     
                                        end
        
        @date_match_C = Struct.new( :match_O,
                                    :pattern_name,
                                    :regexp,
                                    :ymd_S,
                                    :strptime_O,
                                    :as_date,
                                  ) do
                                        def all_pieces
                                            return  match_O.named_captures[ 'begin_M' ] +
                                                    match_O.named_captures[ 'date_M' ] +
                                                    match_O.named_captures[ 'end_M' ]
                                        end
                                        def piece( num )
                                            piece_A = [ match_O.named_captures[ 'begin_M' ],
                                                        match_O.named_captures[ 'date_M' ],
                                                        match_O.named_captures[ 'end_M' ],
                                                      ]
                                            if ( num.is_a?( Integer )) then
                                                return piece_A[ num ]
                                            end
                                            if ( num.is_a?( Range )) then
                                                return piece_A[ num ].join('')
                                            end
                                            raise "#{SE.lineno}: I shouldn't be here: Was expect a number or range."
                                        end
                                        alias_method :pieces, :piece
                                    end
                            
        @ymd_C = Struct.new( :year, :month, :day )
        return                            
        
    end
    attr_reader :option_H, :date_pattern_RES_S__A, :pattern_cnt_H
    
    def new_date_clump_uid_string( num )
        return '<DATE_CLUMP_#:' + '%010d' % num + '>'
    end
    def date_clump_uid_string_RE( )     
        return '<DATE_CLUMP_#:' + '[0-9]{10}'   + '>'
    end
    def date_clump_uid_num( string )
        if ( string.length == 25 and string[ 0, 14 ] == '<DATE_CLUMP_#:' and string[ 24, 1 ] == '>' ) then
            return string[ 14, 10 ].to_i
        else
            SE.puts "#{SE.lineno}: NOT ( string.length == 25 and string[ 0, 14 ] == '<DATE_CLUMP_#:' and string[ 24, 1 ] == '>' )"
            SE.q {[ 'string' ]}
        end
    end
    
    def option_H=( options_to_set_H )
        SE.puts "I can never have this method because the date formats are setup at initialization"
        SE.puts "and it's way to easy to think that setting an option will change the behavior"
        SE.puts "when - in fact - the behavior is in the formats.  You then spend hours trying to"
        SE.puts "figure out why changing the { :default_century => '1900' } with this method"
        SE.puts "doesn't change how the program finds dates."
        raise
    end
    
    def get_tree_of__possible_date_S__A_A( input_string, initial_offset, looking_for_a_thru_date = false, level = 0 )
        tree_of__possible_date_S__A_A = [ ]
        if ( level > 10 ) then
            SE.puts "#{SE.lineno}: In to deep"
            SE.q { 'tree_of__possible_date_S__A_A' }
            raise
        end
        @date_pattern_RES_S__A.each do | date_pattern_RES_S |
            if ( looking_for_a_thru_date ) then
                regexp = %r{(?<begin_M>#{@thru_date_begin_delim_RES})(?<date_M>#{date_pattern_RES_S.pattern_RES})(?<end_M>#{@end_delim_RES})}xi
            else
                regexp = %r{(?<begin_M>#{@begin_delim_RES})(?<date_M>#{date_pattern_RES_S.pattern_RES})(?=([^\>]|$))(?<end_M>#{@end_delim_RES})}xi
#                                                                                
#                           The lookahead '(?=([^\>]|$))' keeps the pattern from seeing the NNNN> of the date-clump literals
#                           and turning the NNNN into a year (with the '>' acting as a separator matched on \W).                   
            end
            scan_begin_offset = initial_offset + 0
            loop do
                break if ( scan_begin_offset >= input_string.maxoffset )
                match_O = input_string.match( regexp, scan_begin_offset )
                break if ( match_O == nil )
                match_string = match_O.named_captures[ 'begin_M' ] +
                               match_O.named_captures[ 'date_M' ] +
                               match_O.named_captures[ 'end_M' ]
                match_offset = match_O.offset( :begin_M )[0]
                match_length = match_string.length
                if ( match_O.named_captures[ 'end_M' ] =~ /#{@thru_date_separator_RES}/ix ) then
                    result = get_tree_of__possible_date_S__A_A( input_string[ match_offset + match_length .. -1 ], 0, true, level + 1 )
                    tree_of__possible_date_S__A_A << [ @possible_date_C.new( date_pattern_RES_S.pattern_name, regexp, match_O ), result ]
                else
                    tree_of__possible_date_S__A_A << [ @possible_date_C.new( date_pattern_RES_S.pattern_name, regexp, match_O ), [ ] ]
                end
                scan_begin_offset = match_offset + match_length
            end
        end
        return tree_of__possible_date_S__A_A
    end
    
    def get_combinations_of__possible_date_S__A_A( tree_of__possible_date_S__A_A, combinations_of__possible_date_S__A_A = [], predecessors_A = [] )
        tree_of__possible_date_S__A_A.each do | tree_of__possible_date_S__A |
            new_predecessors_A = []
            new_predecessors_A.concat( predecessors_A )
            new_predecessors_A.append( tree_of__possible_date_S__A[0] )
            if ( tree_of__possible_date_S__A[1].length > 0 ) then
                get_combinations_of__possible_date_S__A_A( tree_of__possible_date_S__A[1], combinations_of__possible_date_S__A_A, new_predecessors_A)
            else
                combinations_of__possible_date_S__A_A << new_predecessors_A
            end
        end
        return combinations_of__possible_date_S__A_A
    end

    def get_the_longest_date( input_string, initial_offset = 0 )
        tree_of__possible_date_S__A_A = get_tree_of__possible_date_S__A_A( input_string, initial_offset )
        if ( @option_H[ :debug_options ].include?( :print_date_tree )) then
            SE.puts ""
            SE.q { 'tree_of__possible_date_S__A_A' }
        end  
        
        return [ ] if ( tree_of__possible_date_S__A_A.empty? )
        
        combinations_of__possible_date_S__A_A = get_combinations_of__possible_date_S__A_A( tree_of__possible_date_S__A_A )
        if ( @option_H[ :debug_options ].include?( :print_unsorted_combinations )) then
            SE.puts ""
            SE.q { 'combinations_of__possible_date_S__A_A' }
        end
        
        sorted_combinations_of__possible_date_S__A_A = combinations_of__possible_date_S__A_A.sort_by do | combinations_of__possible_date_S__A | 
                            [   
                                0 - combinations_of__possible_date_S__A.sum { | possible_date_S | possible_date_S.match_O[0].gsub( /\s/,"" ).length },
                                0 + combinations_of__possible_date_S__A.length,                                                
                                0 + combinations_of__possible_date_S__A[ 0 ].match_O.offset( :begin_M )[0],
                            ]
                            end
        if ( @option_H[ :debug_options ].include?( :print_sorted_combinations )) then
            SE.puts ""
            SE.q { 'sorted_combinations_of__possible_date_S__A_A' }
        end
#
#       Return only the longest date ( element 0 after sorting) of all the dates found.
        date_match_S__A = [ ]
        sorted_combinations_of__possible_date_S__A_A[ 0 ].each do | possible_date_S |             
            date_match_S = @date_match_C.new(   possible_date_S.match_O,
                                                possible_date_S.pattern_name,
                                                possible_date_S.regexp,
                                             )
            date_match_S__A << date_match_S
        end
        return date_match_S__A         
    end
    

    def do_find( param_input_string )
        date_clump_S__A = [ ]

        process_input_string = "" + param_input_string   # Make a new string, not a pointer.
        ld = SE::Loop_detector.new( 100 )
        loop do   
            ld.loop
            if ( @option_H[ :debug_options ].include?( :print_process_input_string )) then
                SE.puts ""
                SE.q { 'process_input_string' }
            end     
            
#           date_match_S__A is the from date [element 0] and (optional) thru date [element 1].  
            date_match_S__A = get_the_longest_date( process_input_string )
            break if ( date_match_S__A.empty? )
            
            date_clump_S = @date_clump_C.new( full_match_string: "", 
                                              date_match_S__A: date_match_S__A,
                                            )
            date_clump_S__A << date_clump_S
            
            date_clump_S.date_match_S__A.each_with_index do | date_match_S, date_match_I|
                if ( date_match_I == 0 ) then
                    date_clump_S.uid                = new_date_clump_uid_string( date_clump_S__A.length )
                    date_clump_S.beginning_offset   = date_match_S.match_O.offset( :begin_M )[0]   
                end    
                if ( date_match_I == date_clump_S.date_match_S__A.maxindex ) then    # If we're on the last one...   
                    stringer                        = date_match_S.piece( 0..1 )     # Drop the ending delimiter from the match
                else
                    stringer                        = date_match_S.all_pieces
                end    
                
                date_clump_S.full_match_string     += stringer               
                @pattern_cnt_H[ date_match_S.pattern_name ] += 1
 
                date_match_S.ymd_S = @ymd_C.new( ) 
                if ( date_match_S.pattern_name.match?( /__nn_nn_nn/ ) ) then
                    if ( date_match_S.match_O.named_captures[ 'nn_1st_M' ].length == 4 ) then
                        date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                        date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'nn_2nd_M' ]
                        date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                    else
                        case @option_H[ :nn_nn_nn_date_order ]
                        when :mm_dd_yy
                            date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                            date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_2nd_M' ]
                            date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                        when :dd_mm_yy
                            date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                            date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'nn_2nd_M' ]
                            date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                        when :yy_mm_dd
                            date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                            date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'nn_2nd_M' ]
                            date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                        else
                            SE.puts "#{SE.lineno}: I shouldn't be here: #{date_match_S.pattern_name}: "+
                                                 "'#{date_match_S.all_pieces}' > "+
                                                 "invalid :nn_nn_nn_date_order value '#{@option_H[ :nn_nn_nn_date_order ]}'"
                            raise
                        end
                    end
                elsif ( date_match_S.pattern_name.match?( /__nn_MMM_nn/ ) ) then
                    case @option_H[ :nn_mmm_nn_day_year_order ]
                    when :yy_mm_dd
                        date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                        date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'month_M' ]
                        date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                    when :dd_mm_yy
                        date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                        date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'month_M' ]
                        date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                    else
                        SE.puts "#{SE.lineno}: I shouldn't be here: #{date_match_S.pattern_name}: "+
                                             "'#{date_match_S.all_pieces}' > "+
                                             "invalid :nn_mmm_nn_day_year_order value '#{@option_H[ :nn_mmm_nn_day_year_order ]}'"
                        raise
                    end
                elsif ( date_match_S.pattern_name.match?( /__(MMM_dd_dd_yy|MMM_dd_MMM_dd_yy|MMM_MMM_yy)/ )) then  
                    date_match_S.ymd_S.year  =  date_match_S.match_O.named_captures[ 'year_M' ]
                    date_match_S.ymd_S.month =  date_match_S.match_O.named_captures[ 'month_M' ]
                    date_match_S.ymd_S.day   =  date_match_S.match_O.named_captures[ 'day_M' ]
                    
                    generated_thru_date_match_S = @date_match_C.new( date_match_S.match_O )
                    generated_thru_date_match_S.pattern_name = date_match_S.pattern_name
                    generated_thru_date_match_S.ymd_S = @ymd_C.new( )
                    generated_thru_date_match_S.ymd_S.year =  date_match_S.match_O.named_captures[ 'year_M' ]
                    if ( date_match_S.match_O.named_captures.key?( 'thru_month_M' )) then
                        generated_thru_date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'thru_month_M' ]
                    else
                        generated_thru_date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'month_M' ]
                    end
                    if ( date_match_S.match_O.named_captures.key?( 'thru_day_M' )) then
                        generated_thru_date_match_S.ymd_S.day = date_match_S.match_O.named_captures[ 'thru_day_M' ]
                    else
                        generated_thru_date_match_S.ymd_S.day = date_match_S.match_O.named_captures[ 'day_M' ]
                    end
                    date_clump_S.date_match_S__A << generated_thru_date_match_S
                else
                    date_match_S.ymd_S.year  =  date_match_S.match_O.named_captures[ 'year_M' ]
                    date_match_S.ymd_S.month =  date_match_S.match_O.named_captures[ 'month_M' ]
                    date_match_S.ymd_S.day   =  date_match_S.match_O.named_captures[ 'day_M' ]
                end
                
                break if (date_match_S.piece( 2 ) !~ /#{@thru_date_separator_RES}/ix ) 
            end                                                           
            process_input_string[ date_clump_S.beginning_offset, date_clump_S.full_match_string.length ] = date_clump_S.uid
        end


        date_clump_S__A.each do | date_clump_S |

            date_clump_S.date_match_S__A.each_with_index do | date_match_S, date_match_I |

                year   = date_match_S.ymd_S.year
                month  = date_match_S.ymd_S.month
                day    = date_match_S.ymd_S.day
                
                if ( year == nil or ( month == nil and day )) then
                    SE.puts "#{SE.lineno}: I shouldn't be here: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                         "'#{date_match_S.all_pieces}' -> "+
                                         "'#{date_match_S.piece( 1 )}' year == nil or ( month == nil and day)!"
                    SE.q { 'date_clump_S' }
                    raise
                end
                
                if ( day and day.integer? and day.length == 4 and year.length.between?( 1, 2 ) ) then       
                    stringer = "#{SE.lineno}: Swapped day and year: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+                                            
                                            "'#{date_match_S.piece( 1 )}' -> "+
                                            "#{year+' '+month+' '+day}"
                    date_clump_S.judge_date( nil, stringer )
                    year, day               = day, year
                    date_match_S.ymd_S.year = year
                    date_match_S.ymd_S.day  = day
                end
                
                if ( year.length == 1 or year.length == 3 ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' bad year."
                    SE.puts "#{SE.lineno}: #{param_input_string}"                        
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( month and month.integer? and month.length == 3 ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' bad month."
                    date_clump_S.judge_date( :bad, stringer )
                    SE.puts "#{SE.lineno}: #{param_input_string}"
                    next
                end

                if ( year.length == 4 )
                    if ( year < @option_H[ :yyyy_min_value] ) then
                        stringer = "#{SE.lineno}: Date dropped: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                                "'#{date_match_S.all_pieces}' -> "+
                                                "'#{date_match_S.piece( 1 )}' year < min value #{@option_H[ :yyyy_min_value]}"
                        SE.puts "#{SE.lineno}: #{param_input_string}"
                        date_clump_S.judge_date( :bad, stringer )
                        next
                    end
                    if ( year > @option_H[ :yyyy_max_value] ) then
                        stringer = "#{SE.lineno}: Date dropped: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                                "'#{date_match_S.all_pieces}' -> "+
                                                "'#{date_match_S.piece( 1 )}' year > max value #{@option_H[ :yyyy_max_value]}"
                        SE.puts "#{SE.lineno}: #{param_input_string}"
                        date_clump_S.judge_date( :bad, stringer )
                        next
                    end
                end
                if ( day and not day.integer? ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' day not numeric: '#{day}'"
                    SE.puts "#{SE.lineno}: #{param_input_string}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( not year.integer? ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' year not numeric: '#{year}'"
                    SE.puts "#{SE.lineno}: #{param_input_string}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( year.length == 2 ) then
                    if ( date_match_I == 0 ) then
                        year = @option_H[ :default_century ] + year             # These are strings
                    else
                        if ( date_clump_S.from.strptime_O ) then
                            year = date_clump_S.from_date[ 0 .. 1] + year       # Take the century from the converted from_year, which is already in YYYY format
                        else
                            year = @option_H[ :default_century ] + year  
                        end
                    end
                end

                if ( month and not month.integer? ) then
                    # month_match_O = month.match( /^(?<month_M>#{K.alpha_month_RES})/ )  # Only need for 'soft months' , which isn't programmed
                    # if ( not month_match_O == nil ) then
                        # month_named_captures = month_match_O.named_captures
                        # month = month_named_captures[ 'month_M' ]
                    # end
                    month.sub!( /\.$/, "" )                         # Take the period off the months (eg Feb.)
                end

                testdate = year
                if ( date_match_I == 0 )
                    testdate += (month) ? " #{month}" : " Jan"
                    testdate += (day)   ? " #{day}"   : " 01"
                else
                    testdate += (month) ? " #{month}" : " Dec"
                    testdate += (day)   ? " #{day}"   : " 01"       # This will be set to the end-of-month below
                end

                if ( month and month.integer? ) then
                    strptime_fmt = '%Y %m %d'
                else
                    strptime_fmt = '%Y %b %d'
                end
                begin
                    date_match_S.strptime_O = Date::strptime( testdate, strptime_fmt )
                rescue
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' -> "+
                                            "'#{testdate}' -> '#{strptime_fmt}' strptime conversion failed"
                    SE.puts "#{SE.lineno}: #{param_input_string}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( date_match_S.strptime_O.year < 0 ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' -> '#{date_match_S.strptime_O}' negative year"
                    SE.puts "#{SE.lineno}: #{param_input_string}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( day == nil and date_match_S.strptime_O.day != 1 ) then
                    SE.puts "#{SE.lineno}: I shouldn't be here: #{date_match_S.pattern_name}, idx=#{date_match_I}: "+
                                         "'#{date_match_S.all_pieces}' -> "+
                                         "'#{date_match_S.piece( 1 )}' -> '#{date_match_S.strptime_O} day != 1"
                    SE.puts "#{SE.lineno}: #{param_input_string}"
                    raise
                end
                if ( day == nil and date_match_I > 0 ) then
                    date_match_S.strptime_O = date_match_S.strptime_O.last_day_of_month
                end
                
                date_match_S.as_date  = date_match_S.strptime_O.strftime( '%Y' )
                date_match_S.as_date += date_match_S.strptime_O.strftime( '-%m' ) if ( month )
                date_match_S.as_date += date_match_S.strptime_O.strftime( '-%d' ) if ( day )
            end
            next if ( date_clump_S.morality == :bad )
            
            if ( date_clump_S.date_match_S__A.length > 2 ) then                 
                stringer = "#{SE.lineno}: #{date_clump_S.date_match_S__A.length} run-on thru dates: "
                date_clump_S.date_match_S__A.each do | date_match_S |
                    stringer += "'#{date_match_S.all_pieces}' "
                end
                SE.puts "#{SE.lineno}: #{param_input_string}"
                date_clump_S.judge_date( :bad, stringer )
                next
            end      
            if ( date_clump_S.date_match_S__A.length == 1 and date_clump_S.from.ymd_S.year.length == 2 and date_clump_S.from.ymd_S.month == nil and date_clump_S.from.ymd_S.day == nil ) then
                stringer = "#{SE.lineno}: probable bad date: #{date_clump_S.from.pattern_name}: "+
                                        "'#{date_clump_S.from.all_pieces}' -> "+
                                        "'#{date_clump_S.from.piece( 1 )}' isolated 2 digit number."
                SE.puts "#{SE.lineno}: #{param_input_string}"
                date_clump_S.judge_date( :bad, stringer )
                next
            end
            
            if ( date_clump_S.date_match_S__A.length == 2 and date_clump_S.from.strptime_O and date_clump_S.thru.strptime_O ) then
                if (date_clump_S.from.strptime_O > date_clump_S.thru.strptime_O ) then
                    stringer = "#{SE.lineno}: From date '#{date_clump_S.from_date}' > Thru date '#{date_clump_S.thru_date}'"
                    SE.puts "#{SE.lineno}: #{param_input_string}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
            end

            if ( @option_H[ :debug_options ].include?( :print_good_dates ) ) then
                stringer = "#{SE.lineno}: good date: #{date_match_S.pattern_name}: '#{date_match_S.all_pieces}'"
                SE.puts stringer
            end
            date_clump_S.morality = :good
            date_clump_S.error_msg = ""

        end

        process_input_string_with_all_dates_removed = process_input_string + ""
        date_clump_S__A.each do | date_clump_S |
            replace_option = @option_H[ :morality_replace_option ][ date_clump_S.morality ]
            case replace_option
            when :keep
                begin
                    process_input_string[ date_clump_S.uid ]                        = date_clump_S.full_match_string
                    process_input_string_with_all_dates_removed[ date_clump_S.uid ] = ""
                rescue
                    SE.puts "#{SE.lineno}: uid replace failed"
                    SE.puts "#{SE.lineno}: process_input_string = #{process_input_string}"
                    SE.q { 'date_clump_S' }
                    raise
                end
            when :replace
                begin
                    process_input_string[ date_clump_S.uid ]                        = date_clump_S.date_match_S__A.join( ' - ' )
                    process_input_string_with_all_dates_removed[ date_clump_S.uid ] = ""
                rescue
                    SE.puts "#{SE.lineno}: uid replace failed"
                    SE.puts "#{SE.lineno}: process_input_string = #{process_input_string}"
                    SE.q { 'date_clump_S' }
                    raise
                end
            when :remove_from_end
                begin
                    #   date_clump_S.uid's removed below...
                    process_input_string_with_all_dates_removed[ date_clump_S.uid ] = ""
                rescue
                    SE.puts "#{SE.lineno}: uid replace failed"
                    SE.puts "#{SE.lineno}: process_input_string = #{process_input_string}"
                    SE.q { 'date_clump_S' }
                    raise
                end
            when :remove
                begin
                    process_input_string[ date_clump_S.uid ]                        = ""
                    process_input_string_with_all_dates_removed[ date_clump_S.uid ] = ""
                rescue
                    SE.puts "#{SE.lineno}: uid replace failed"
                    SE.puts "#{SE.lineno}: process_input_string = #{process_input_string}"
                    SE.q { 'date_clump_S' }
                    raise
                end
            else
                SE.puts "#{SE.lineno}: I shouldn't be here, unknown replace_option for morality '#{date_clump_S.morality}' -> "+
                                     "'#{@option_H[ :morality_replace_option ][ date_clump_S.morality ]}'"
                SE.q { 'date_clump_S' }
                raise
            end
        end
        if ( @option_H[ :morality_replace_option ][ :good ] == :remove_from_end ) then
            loop do
                process_input_string.sub!( /([\.,;])\s*\Z/, '' )
                break if ( not process_input_string.sub!( /#{date_clump_uid_string_RE}\s*\Z/, '' ) )
            end
            while ( process_input_string.match( /#{date_clump_uid_string_RE}/ ) ) 
                date_clump_uid_string = $&
                date_clump_S = date_clump_S__A[ date_clump_uid_num( date_clump_uid_string ) - 1 ]  # The number is 1 relative
                begin
                    process_input_string[ date_clump_uid_string ] = date_clump_S.full_match_string
                rescue
                    SE.puts "#{SE.lineno}: uid replace failed"
                    SE.puts "#{SE.lineno}: process_input_string = #{process_input_string}"
                    SE.q { 'date_clump_S' }
                    raise
                end
            end
        end

        @good__date_clump_S__A = [ ]
        @bad__date_clump_S__A = [ ]
        date_clump_S__A.each do | date_clump_S |
            case date_clump_S.morality
            when :good
                @good__date_clump_S__A << date_clump_S
            when :bad
                @bad__date_clump_S__A << date_clump_S
            else
                SE.puts "#{SE.lineno}: I shouldn't be here: amoral date: '#{date_clump_S.morality}', #{date_clump_S}"
                raise
            end
        end
        if ( @option_H[ :sort ] ) then
            @good__date_clump_S__A = @good__date_clump_S__A.sort_by { | date_clump_S | [ date_clump_S.from_date ] }
            prev_date=''
            @good__date_clump_S__A.each_with_index do | date_clump_S, idx |
                if ( date_clump_S.from_date < prev_date ) then
                    SE.puts "#{SE.lineno}: Warning: Dates overlap! good from-date '#{date_clump_S.from_date} at element #{idx} "+
                            "< previous date #{prev_date}, there may be others."
                    SE.puts param_input_string
                    SE.puts ""
                    break
                end
                prev_date = (date_clump_S.thru_date == '') ? date_clump_S.from_date : date_clump_S.thru_date
            end
        end

        case @option_H[ :date_string_composition ]
        when :dates_in_text
            if (process_input_string_with_all_dates_removed =~ %r~#{K.alpha_month_RES}#( |/|-)~i ) then
                SE.puts "#{SE.lineno}: Warning possible unmatched date '#{$~}' in '#{process_input_string_with_all_dates_removed}'"
                SE.puts ""
            end
        when :only_dates
            if (process_input_string_with_all_dates_removed !~ /^\s*$/ ) then
                SE.puts "#{SE.lineno}: Unconverted dates in: '#{param_input_string}'"
                SE.puts "#{SE.lineno}: Extra text:           '#{process_input_string_with_all_dates_removed}'"  if ( param_input_string != process_input_string_with_all_dates_removed )
                if ( @good__date_clump_S__A.length > 0 ) then
                    stringer = @good__date_clump_S__A.map do | date_clump_S |
                        date_clump_S.date_match_S__A.map do | date_match_S |
                            date_match_S.as_date
                        end
                    end.join( "','")
                    SE.puts "#{SE.lineno}: Good dates: '#{stringer}' moved to bad-dates array after row #{@bad__date_clump_S__A.length}"
                    @bad__date_clump_S__A += @good__date_clump_S__A
                    @good__date_clump_S__A = [ ]
                end
                SE.puts ""
                process_input_string = param_input_string
            end
        end

        return process_input_string

    end
    attr_reader :good__date_clump_S__A, :bad__date_clump_S__A
    
end



