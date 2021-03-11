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
        @param_H.each_key do | param_H_key |
            case param_H_key
            when :debug_options
                if ( not @param_H[ param_H_key ].is_a?( Array ) ) then
                    Se.puts "#{Se.lineno}: Expected '#{param_H_key}' to be a type Array, not '#{@param_H[ param_H_key ]}'"
                    Se.pp param_H
                    raise
                end
                @param_H[ param_H_key ].each do | element |
                    case element
                    when :print_good_dates
                        Se.puts "#{Se.lineno}: param_H[ :debug_options ][ #{element} ] set."
                    when :print_process_string
                        @uid_string = "FDIS"
                        Se.puts "#{Se.lineno}: param_H[ :debug_options ][ #{element} ] set."
                    else
                        Se.puts "#{Se.lineno}: unknown :debug_options '#{element}'"
                        Se.pp param_H
                        aise
                    end
                end
            when :morality_replace_option
                if ( not @param_H[ param_H_key ].is_a?( Hash ) ) then
                    Se.puts "#{Se.lineno}: Expected '#{param_H_key}' to be a type Hash, not '#{@param_H[ param_H_key ]}'"
                    Se.pp param_H
                    raise
                end
                @param_H[ param_H_key ].each_pair do | key, value |
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

            when :pattern_name_RE
                if ( not @param_H[ param_H_key ].is_a?( Regexp ) ) then
                    Se.puts "#{Se.lineno}: param_H[ :pattern_name_RE ] should be an Regexp"
                    Se.pp param_H
                    raise
                end
            when :default_century
                default_century = @param_H[ param_H_key ]
                if ( not (default_century.integer? and (default_century.length == 2 or (default.century.length == 4 and default_century[ 2..3 ] != "00" )))) then
                    Se.puts "#{Se.lineno}: Expected the :default_century to be NN00 (or NN), not '#{default_century}'"
                    raise
                end
                @param_H[ param_H_key ] = @param_H[ param_H_key ][0..1]
            when :yyyy_min_value
                if ( not (@param_H[ param_H_key ].integer? and @param_H[ param_H_key ].length == 4 )) then
                    Se.puts "#{Se.lineno}: Expected the :yyyy_min_value to be NNNN, not '#{@param_H[ param_H_key ]}'"
                    raise
                end
            when :yyyy_max_value
                if ( not (@param_H[ param_H_key ].integer? and @param_H[ param_H_key ].length == 4 )) then
                    Se.puts "#{Se.lineno}: Expected the :yyyy_max_value to be NNNN, not '#{@param_H[ param_H_key ]}'"
                    raise
                end
            when :date_string_composition
                if ( not (@param_H[ param_H_key ].is_a?( Symbol ) and @param_H[ param_H_key ].in?( [ :only_dates, :dates_in_text ] ))) then
                    Se.puts "#{Se.lineno}: Expected :date_string_composition to be :only_dates or :dates_in_text, not '#{@param_H[ param_H_key ]}'"
                    raise
                end
            when :nn_nn_yyyy_month_day_order
                if ( not (@param_H[ param_H_key ].is_a?( Symbol ) and @param_H[ param_H_key ].in?( [ :mm_dd, :dd_mm ] ))) then
                    Se.puts "#{Se.lineno}: Expected :nn_nn_yyyy_month_day_order to be :mm_dd or :dd_mm, not '#{@param_H[ param_H_key ]}'"
                    raise
                end
            when :nn_nn_nn_date_piece_order
                if ( not (@param_H[ param_H_key ].is_a?( Symbol ) and @param_H[ param_H_key ].in?( [ :mm_dd_yy, :dd_mm_yy ] ))) then
                    Se.puts "#{Se.lineno}: Expected :nn_nn_nn_date_piece_order to be :mm_dd_yy or :dd_mm_yy, not '#{@param_H[ param_H_key ]}'"
                    raise
                end
            when :sort
                if ( not ( [true, false].include?( @param_H[ param_H_key ] ) ) ) then
                    Se.puts "#{Se.lineno}: Expected '#{param_H_key}' to be true or false, not '#{@param_H[ param_H_key ]}'"
                    Se.pp param_H
                    raise
                end
            else
                Se.puts "#{Se.lineno}: invalid param_H option: '#{param_H_key}'"
                pp @param_H
                raise
            end
        end
  
        if ( not @param_H.key?( :debug_options ) )
            @param_H[ :debug_options ] = []
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
        if ( not @param_H.key?( :thru_date_separator ) ) then
            @param_H[ :thru_date_separator ] = '-'
        end
        if ( not @param_H.key?( :pattern_name_RE ) )
        then
            @param_H[ :pattern_name_RE ] = %r{.}
        end
        if ( not @param_H.key?( :default_century ) )
        then
            @param_H[ :default_century ] = "19"
        end
        if ( not @param_H.key?( :date_string_composition ) ) then
            @param_H[ :date_string_composition ] = :dates_in_text
        end
        if ( not @param_H.key?( :yyyy_min_value ) ) then
            @param_H[ :yyyy_min_value ] = '1800'
        end
        if ( not @param_H.key?( :yyyy_max_value ) ) then
            @param_H[ :yyyy_max_value ] = '2100'
        end
        if ( not @param_H.key?( :nn_nn_yyyy_month_day_order ) ) then
            @param_H[ :nn_nn_yyyy_month_day_order ] = :mm_dd
        end
        if ( not @param_H.key?( :nn_nn_nn_date_piece_order ) ) then
            @param_H[ :nn_nn_nn_date_piece_order ] = :mm_dd_yy
        end
        if ( not @param_H.key?( :sort ) ) then
            @param_H[ :sort ] = true
        end
        dash_RE = %r{\s{0,2}-\s{0,2}}.freeze
        dash_slash_RE = %r{\s{0,2}[\-\/]\s{0,2}}.freeze
                           
        comma_RE = %r{\s{0,2},\s{0,3}}.freeze
        spaces_RE = %r{\s{0,3}}.freeze
        
        month_RE = %r{(?:([a-z]{3,11}|[a-z]{3,3}\.)){1}}xi.freeze       # Alpha months
        n_nn_RE = %r{(?:([0-9]|[0-9][0-9])){1}}xi.freeze                # For days and numeric months

        year4_RE = %r{[0-9]{4}}.freeze
        year2_RE = %r{[0-9]{2}}.freeze
        year_xx_RE = %r{(#{year4_RE}|#{year2_RE}){1}}.freeze
        
        extra_date_RE = %r{( (((#{month_RE})#{spaces_RE}      ((#{n_nn_RE}) #{comma_RE}){0,1}){0,1}       (#{year_xx_RE}))
                           | (((#{n_nn_RE})#{dash_slash_RE}   ((#{month_RE})#{dash_slash_RE}){0,1}){0,1}  (#{year_xx_RE}))
                           | (((#{n_nn_RE})#{dash_slash_RE}   ((#{n_nn_RE}) #{dash_slash_RE}){0,1}){0,1}  (#{year_xx_RE}))
                           )}xi.freeze

        @begin_date_delim_RE    = %r{(^|\W|\s){1}\s*}x.freeze
        @end_date_delim_RE      = %r{\s*(\s|\W|$){1}}x.freeze
        @thru_date_separator_RE = %r{(\s{0,2}#{@param_H[ :thru_date_separator ]}\s{0,2}){1}}x.freeze
        
        date_pattern_RE_S = Struct.new( :priority, :pattern_name, :pattern_length, :regex )     # :pattern_name and length are computed and added later
        # NOTE!!! pattern_names ending in __double are prioritized higher than __singles of the same priority
        #         altho it's probably not necessary as _double's are longer anyway.

        initial_date_pattern_RE_A_S = []  
           
                                        #   fmt001 Dates in yy-yy double format only 
                                            
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 40, nil, nil,
                                    /(?<fmt001__yy__double>                                                                                         (?<year_M>#{year2_RE})
                                       #{@thru_date_separator_RE}                                                                              (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
           
                                        #   fmt002 Dates in yyyy format only, single or double  
                                        
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 40, nil, nil,  
                                    /(?<fmt002__yyyy__double>                                                                                       (?<year_M>#{year4_RE})
                                       #{@thru_date_separator_RE}                                                                              (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 40, nil, nil,
                                    /(?<fmt002__yyyy__single>                                                                                       (?<year_M>#{year4_RE}))/x )

                                        #   fmt003 Dates in 'mmm (dd,) yy[yy]' format with spaces between 'mmm' 'dd', with from and thru dates (double)

        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt003__MMM_dd_yyyy__double>  (?<month_M>#{month_RE})#{spaces_RE}      (?<day_M>#{n_nn_RE})#{comma_RE}      (?<year_M>#{year4_RE})
                                       #{@thru_date_separator_RE}(?<thru_month_M>#{month_RE})#{spaces_RE} (?<thru_day_M>#{n_nn_RE})#{comma_RE} (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt003__MMM_dd_yyyy__single>  (?<month_M>#{month_RE})#{spaces_RE}      (?<day_M>#{n_nn_RE})#{comma_RE}      (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt003__MMM_dd_yy__double>    (?<month_M>#{month_RE})#{spaces_RE}      (?<day_M>#{n_nn_RE})#{comma_RE}       (?<year_M>#{year2_RE})
                                       #{@thru_date_separator_RE}(?<thru_month_M>#{month_RE})#{spaces_RE} (?<thru_day_M>#{n_nn_RE})#{comma_RE}  (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt003__MMM_dd_yy__single>    (?<month_M>#{month_RE})#{spaces_RE}      (?<day_M>#{n_nn_RE})#{comma_RE}       (?<year_M>#{year2_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt003__MMM_yyyy__double>     (?<month_M>#{month_RE})#{spaces_RE}                                            (?<year_M>#{year4_RE})
                                       #{@thru_date_separator_RE}(?<thru_month_M>#{month_RE})#{spaces_RE}                                       (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt003__MMM_yyyy__single>     (?<month_M>#{month_RE})#{spaces_RE}                                            (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt003__MMM_yy__double>       (?<month_M>#{month_RE})#{spaces_RE}                                            (?<year_M>#{year2_RE})
                                       #{@thru_date_separator_RE}(?<thru_month_M>#{month_RE})#{spaces_RE}                                       (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt003__MMM_yy__single>       (?<month_M>#{month_RE})#{spaces_RE}                                            (?<year_M>#{year2_RE}))/x )
    
                                        #   fmt004 = Dates in 'dd [-/] mmm [-/] yy[yy]' format, with from and thru dates (double)
                                        
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt004__dd_MMM_yyyy__double>  (?<day_M>#{n_nn_RE})#{dash_slash_RE}     (?<month_M>#{month_RE})#{dash_slash_RE}       (?<year_M>#{year4_RE})
                                       #{@thru_date_separator_RE}(?<thru_day_M>#{n_nn_RE})#{dash_slash_RE}(?<thru_month_M>#{month_RE})#{dash_slash_RE}  (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt004__dd_MMM_yyyy__single>  (?<day_M>#{n_nn_RE})#{dash_slash_RE}     (?<month_M>#{month_RE})#{dash_slash_RE}       (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt004__dd_MMM_yy__double>    (?<day_M>#{n_nn_RE})#{dash_slash_RE}     (?<month_M>#{month_RE})#{dash_slash_RE}       (?<year_M>#{year2_RE})
                                       #{@thru_date_separator_RE}(?<thru_day_M>#{n_nn_RE})#{dash_slash_RE}(?<thru_month_M>#{month_RE})#{dash_slash_RE}  (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt004__dd_MMM_yy__single>    (?<day_M>#{n_nn_RE})#{dash_slash_RE}     (?<month_M>#{month_RE})#{dash_slash_RE}       (?<year_M>#{year2_RE}))/x )
 
                                        #   fmt005 = Dates in 'mmm - yy[yy]' format, with from and thru dates (double)
     
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt005__MMM_yyyy__double>                                              (?<month_M>#{month_RE})#{dash_RE}             (?<year_M>#{year4_RE})
                                       #{@thru_date_separator_RE}                                         (?<thru_month_M>#{month_RE})#{dash_RE}        (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt005__MMM_yyyy__single>                                             (?<month_M>#{month_RE})#{dash_RE}              (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt005__MMM_yy__double>                                                (?<month_M>#{month_RE})#{dash_RE}             (?<year_M>#{year2_RE})
                                       #{@thru_date_separator_RE}                                         (?<thru_month_M>#{month_RE})#{dash_RE}        (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil, 
                                    /(?<fmt005__MMM_yy__single>                                                (?<month_M>#{month_RE})#{dash_RE}             (?<year_M>#{year2_RE}))/x )

                                        #   fmt006 = Dates in 'mmm  dd - yy[yy]' format, but no doubles
                                        
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil,
                                    /(?<fmt006__MMM_dd_yyyy__single> (?<month_M>#{month_RE})#{spaces_RE}     (?<day_M>#{n_nn_RE})#{dash_RE}       (?<year_M>#{year4_RE}))/x )
    
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 60, nil, nil,
                                    /(?<fmt006__MMM_dd_yy__single>   (?<month_M>#{month_RE})#{spaces_RE}     (?<day_M>#{n_nn_RE})#{dash_RE}       (?<year_M>#{year2_RE}))/x )
        
                                        #   fmt007 = Dates in 'mmm dd - dd, yy[yy] format (hybid double)
                                        
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt007__MMM_dd_dd_yyyy>      (?<month_M>#{month_RE})#{spaces_RE}      (?<day_M>#{n_nn_RE})
                                       #{@thru_date_separator_RE}                                        (?<thru_day_M>#{n_nn_RE})#{comma_RE}     (?<year_M>#{year4_RE}))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt007__MMM_dd_dd_yy>        (?<month_M>#{month_RE})#{spaces_RE}      (?<day_M>#{n_nn_RE})
                                       #{@thru_date_separator_RE}                                        (?<thru_day_M>#{n_nn_RE})#{comma_RE}     (?<year_M>#{year2_RE}))/x )

                                        #   fmt007 = Dates in 'mmm dd - mmm dd, yy[yy] format (hybid double)
                                        
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt007__MMM_dd_MMM_dd_yyyy>   (?<month_M>#{month_RE})#{spaces_RE}     (?<day_M>#{n_nn_RE})
                                       #{@thru_date_separator_RE}(?<thru_month_M>#{month_RE})#{spaces_RE}(?<thru_day_M>#{n_nn_RE})#{comma_RE}     (?<year_M>#{year4_RE}))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt007__MMM_dd_MMM_dd_yy>     (?<month_M>#{month_RE})#{spaces_RE}     (?<day_M>#{n_nn_RE})
                                       #{@thru_date_separator_RE}(?<thru_month_M>#{month_RE})#{spaces_RE}(?<thru_day_M>#{n_nn_RE})#{comma_RE}     (?<year_M>#{year2_RE}))/x )

                                        #   fmt008 = Dates in 'mmm-mmm yy[yy] format (hybid double) Note there's NO COMMA after the month  
                                        
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt008__MMM_MMM_yyyy>         (?<month_M>#{month_RE})#{spaces_RE}
                                       #{@thru_date_separator_RE}(?<thru_month_M>#{month_RE})#{spaces_RE}    (?<year_M>#{year4_RE}))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 70, nil, nil,
                                    /(?<fmt008__MMM_MMM_yy>           (?<month_M>#{month_RE})#{spaces_RE}
                                      #{@thru_date_separator_RE} (?<thru_month_M>#{month_RE})#{spaces_RE}    (?<year_M>#{year2_RE}))/x )
            

                                        #   fmt009 = All numeric dates 'nn [-/] nn [-/] yyyy' format, with from and thru dates (double)
                                        
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt009__nn_nn_yyyy__double>   (?<nn_1st_M>#{n_nn_RE})#{dash_slash_RE}       (?<nn_2nd_M>#{n_nn_RE})#{dash_slash_RE}       (?<year_M>#{year4_RE})
                                       #{@thru_date_separator_RE}(?<thru_nn_1st_M>#{n_nn_RE})#{dash_slash_RE}  (?<thru_nn_2nd_M>#{n_nn_RE})#{dash_slash_RE}  (?<thru_year_M>#{year_xx_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt009__nn_nn_yyyy__single>   (?<nn_1st_M>#{n_nn_RE})#{dash_slash_RE}       (?<nn_2nd_M>#{n_nn_RE})#{dash_slash_RE}       (?<year_M>#{year4_RE}))/x )

                                        #   fmt010 = All numeric dates 'yyyy [-/] nn [-/] nn ' format, with from and thru dates (double)
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt010__yyyy_nn_nn__double>    (?<year_M>#{year4_RE})#{dash_slash_RE}        (?<month_M>#{n_nn_RE})#{dash_slash_RE}         (?<day_M>#{n_nn_RE})      
                                       #{@thru_date_separator_RE} (?<thru_year_M>#{year_xx_RE})#{dash_slash_RE} (?<thru_month_M>#{n_nn_RE})#{dash_slash_RE}    (?<thru_day_M>#{n_nn_RE}) 
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt010__yyyy_nn_nn__single>    (?<year_M>#{year4_RE})#{dash_slash_RE}        (?<month_M>#{n_nn_RE})#{dash_slash_RE}         (?<day_M>#{n_nn_RE}))/x )

                                        #   fmt011 = All numeric dates 'nn [-/] nn [-/] nn ' format (2-digit years ONLY), with from and thru dates (double)
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt011__nn_nn_nn__double>     (?<nn_1st_M>#{n_nn_RE})#{dash_slash_RE}       (?<nn_2nd_M>#{n_nn_RE})#{dash_slash_RE}      (?<nn_3rd_M>#{n_nn_RE})
                                       #{@thru_date_separator_RE}(?<thru_nn_1st_M>#{n_nn_RE})#{dash_slash_RE}  (?<thru_nn_2nd_M>#{n_nn_RE})#{dash_slash_RE} (?<thru_nn_3rd_M>#{n_nn_RE})
                     (?<extra_dates_M>(#{@thru_date_separator_RE}#{extra_date_RE})*))/x )
        initial_date_pattern_RE_A_S << date_pattern_RE_S.new( 50, nil, nil,
                                    /(?<fmt011__nn_nn_nn__single>     (?<nn_1st_M>#{n_nn_RE})#{dash_slash_RE}       (?<nn_2nd_M>#{n_nn_RE})#{dash_slash_RE}      (?<nn_3rd_M>#{n_nn_RE}))/x )
                  
#       Set the pattern_name and length    
        initial_date_pattern_RE_A_S.each_index do | date_pattern_idx |  
            stringer = initial_date_pattern_RE_A_S[ date_pattern_idx ].regex.inspect.gsub( / /,"" )
            pattern_name = stringer[ stringer.index( '<' ) + 1 .. stringer.index( '>' ) - 1 ]
            if ( not pattern_name.match?( /^fmt[0-9]{3}__/ ) ) then
                Se.puts "#{Se.lineno}: I shouldn't be here: pattern_name doesn't start with /fmtNNN__'#{pattern_name}'"
                raise
            end             
            initial_date_pattern_RE_A_S[ date_pattern_idx ].pattern_length = stringer.length
            initial_date_pattern_RE_A_S[ date_pattern_idx ].pattern_name = pattern_name
        end

#       Load date patterns to use        
        @date_pattern_RE_A_S = [ ]
        initial_date_pattern_RE_A_S.each_index do | date_pattern_idx |
            pattern_name = initial_date_pattern_RE_A_S[ date_pattern_idx ].pattern_name
            if ( pattern_name.match?( @param_H[ :pattern_name_RE ] )) then
                @date_pattern_RE_A_S.push( initial_date_pattern_RE_A_S[ date_pattern_idx ] )
            end
        end
        if ( @date_pattern_RE_A_S.length == 0 ) then
            Se.puts "#{Se.lineno}: No patterns selected based on RE: #{@param_H[ :pattern_name_RE ]}"
            raise
        end

        @date_pattern_RE_A_S = @date_pattern_RE_A_S.sort_by do | element_S | 
            [ 0.0 - element_S.priority - ((element_S.pattern_name =~ /__double$/i) ? 0.1 : 0.0), 0 - element_S.pattern_length ] 
        end

#       Check for duplicate pattern names
        dup_check_H = {}
        @date_pattern_RE_A_S.each_index do | date_pattern_idx |
            pattern_name = date_pattern_RE_A_S[ date_pattern_idx ].pattern_name
            if ( dup_check_H.key?( pattern_name ) ) then
                Se.puts "#{Se.lineno}: I shouldn't be here: duplicate pattern_name '#{pattern_name}'"
                raise
            end   
            dup_check_H[ pattern_name ] = date_pattern_idx
            # Se.puts "idx = #{date_pattern_idx} #{pattern_name}"
        end       
        # pp @date_pattern_RE_A_S; exit
    end
    attr_reader :date_pattern_RE_A_S
    
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
                    throw :next_date if ( offset > process_string.maxoffset )
                    
                    pattern_RE = %r{(?<begin_M>#{@begin_date_delim_RE})(?<date_M>#{date_pattern_RE})(?<end_M>#{@end_date_delim_RE})}
                    # Se.p pattern_RE.inspect.gsub(/ /,"")
                    pattern_RE_match_O = process_string.match( pattern_RE, offset )
                    throw :next_date if ( pattern_RE_match_O == nil )
                    
                    if ( @param_H[ :debug_options ].include?( :print_process_string )) then
                        Se.puts ""
                        Se.puts process_string
                    end
                    pattern_RE_named_captures = pattern_RE_match_O.named_captures                    
                    date_found_S = Struct.new(  :morality, 
                                                :replace_uid, 
                                                :as_date_S,
                                             ).new( K.undefined,
                                                    replace_uid = pattern_RE_named_captures[ 'begin_M' ] + 
                                                                  @uid_string + "_" + "%010d" % (@date_found_A_S.length + 1 ),
                                                    Struct.new( :pattern_piece_A,
                                                                :pattern_name,
                                                                :from_date,
                                                                :thru_date,
                                                                :error_msg,
                                                              ) do
                                                                    def all_pieces
                                                                        pattern_piece_A.join('')
                                                                    end
                                                                    def piece( num )
                                                                        if ( num.is_a?( Integer )) then
                                                                            return pattern_piece_A[ num ]
                                                                        end
                                                                        if ( num.is_a?( Range )) then
                                                                            return pattern_piece_A[ num ].join('')
                                                                        end
                                                                        raise "Was expect a number or range"
                                                                    end
                                                                end.new(    [ pattern_RE_named_captures[ 'begin_M' ], 
                                                                              pattern_RE_named_captures[ 'date_M' ], 
                                                                              pattern_RE_named_captures[ 'end_M'  ],
                                                                            ],
                                                                            pattern_RE_match_O.names[ 2 ],
                                                                            "",
                                                                            "",
                                                                            K.undefined,
                                                                       ) 
                                                  )
                                                                                                                                                                                                                                                     
                    repl_offset_start = pattern_RE_match_O.offset( :begin_M )[0]                                                                                                       
                    process_string[ repl_offset_start .. repl_offset_start + date_found_S.as_date_S.piece(0..1).maxoffset ] = date_found_S.replace_uid 
                    offset = pattern_RE_match_O.offset( :begin_M )[0] + date_found_S.replace_uid.length
                    
                    s_C = Struct.new( :date, :strptime_O )
                    date_validation_S = Struct.new( :from, :thru ).new( s_C.new( "", nil ), s_C.new( "", nil ) )
                    
                    date_validation_S.each_pair do | ft_sym, s |    # ft_sym = from_thru_symbol. Can't be "each" as that just passes out the value, and members doesn't seem to work.
                        case ft_sym
                        when :from
                            if ( date_found_S.as_date_S.pattern_name.match?( /__nn_nn_nn_/ ) ) then
                                case @param_H[ :nn_nn_nn_date_piece_order ] 
                                when :mm_dd_yy 
                                    month = pattern_RE_named_captures[ 'nn_1st_M' ]
                                    day   = pattern_RE_named_captures[ 'nn_2nd_M' ]
                                    year  = pattern_RE_named_captures[ 'nn_3rd_M' ]
                                when :dd_mm_yy
                                    day   = pattern_RE_named_captures[ 'nn_1st_M' ]
                                    month = pattern_RE_named_captures[ 'nn_2nd_M' ]
                                    year  = pattern_RE_named_captures[ 'nn_3rd_M' ]
                                when :yy_mm_dd
                                    year  = pattern_RE_named_captures[ 'nn_1st_M' ]
                                    month = pattern_RE_named_captures[ 'nn_2nd_M' ]
                                    day   = pattern_RE_named_captures[ 'nn_3rd_M' ]
                                else 
                                    Se.puts "#{Se.lineno}: I shouldn't be here: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                         "'#{date_found_S.as_date_S.all_pieces}' > "+
                                                         "'#{date_found_S.as_date_S.piece( 1 )}' "+
                                                         "invalid :nn_nn_nn_date_piece_order value '#{@param_H[ :nn_nn_nn_date_piece_order ]}'"
                                    raise
                                end
                            elsif ( date_found_S.as_date_S.pattern_name.match?( /__nn_nn_yyyy_/ ) )  then
                                year =  pattern_RE_named_captures[ 'year_M' ]
                                case @param_H[ :nn_nn_yyyy_month_day_order ] 
                                when :mm_dd 
                                    month = pattern_RE_named_captures[ 'nn_1st_M' ]
                                    day   = pattern_RE_named_captures[ 'nn_2nd_M' ]
                                when :dd_mm
                                    day   = pattern_RE_named_captures[ 'nn_1st_M' ]
                                    month = pattern_RE_named_captures[ 'nn_2nd_M' ]
                                else 
                                    Se.puts "#{Se.lineno}: I shouldn't be here: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                         "'#{date_found_S.as_date_S.all_pieces}' > "+
                                                         "'#{date_found_S.as_date_S.piece( 1 )}' "+
                                                         "invalid :nn_nn_yyyy_month_day_order value '#{@param_H[ :nn_nn_yyyy_month_day_order ]}'"
                                    raise
                                end
                            else                    
                                year =  pattern_RE_named_captures[ 'year_M' ]
                                month = pattern_RE_named_captures[ 'month_M' ]
                                day =   pattern_RE_named_captures[ 'day_M' ] 
                            end
                        when :thru
                            break if ( date_found_S.as_date_S.pattern_name.match?( /__single/ ) ) 
                            
                            if ( date_found_S.as_date_S.pattern_name.match?( /__nn_nn_nn_/ ) ) then
                                case @param_H[ :nn_nn_nn_date_piece_order ] 
                                when :mm_dd_yy 
                                    month = pattern_RE_named_captures[ 'thru_nn_1st_M' ]
                                    day   = pattern_RE_named_captures[ 'thru_nn_2nd_M' ]
                                    year  = pattern_RE_named_captures[ 'thru_nn_3rd_M' ]
                                when :dd_mm_yy
                                    day   = pattern_RE_named_captures[ 'thru_nn_1st_M' ]
                                    month = pattern_RE_named_captures[ 'thru_nn_2nd_M' ]
                                    year  = pattern_RE_named_captures[ 'thru_nn_3rd_M' ]
                                when :yy_mm_dd
                                    year  = pattern_RE_named_captures[ 'thru_nn_1st_M' ]
                                    month = pattern_RE_named_captures[ 'thru_nn_2nd_M' ]
                                    day   = pattern_RE_named_captures[ 'thru_nn_3rd_M' ]
                                else 
                                    Se.puts "#{Se.lineno}: I shouldn't be here: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                         "'#{date_found_S.as_date_S.all_pieces}' > "+
                                                         "'#{date_found_S.as_date_S.piece( 1 )}' "+
                                                         "invalid :nn_nn_nn_date_piece_order value '#{@param_H[ :nn_nn_nn_date_piece_order ]}'"
                                    raise
                                end
                            elsif ( date_found_S.as_date_S.pattern_name.match?( /__nn_nn_yyyy_/ ) ) then
                                year =  pattern_RE_named_captures[ 'thru_year_M' ]
                                case @param_H[ :nn_nn_yyyy_month_day_order ] 
                                when :mm_dd 
                                    month = pattern_RE_named_captures[ 'thru_nn_1st_M' ]
                                    day   = pattern_RE_named_captures[ 'thru_nn_2nd_M' ]
                                when :dd_mm
                                    day   = pattern_RE_named_captures[ 'thru_nn_1st_M' ]
                                    month = pattern_RE_named_captures[ 'thru_nn_2nd_M' ]
                                else 
                                    Se.puts "#{Se.lineno}: I shouldn't be here: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                         "'#{date_found_S.as_date_S.all_pieces}' > "+
                                                         "'#{date_found_S.as_date_S.piece( 1 )}' "+
                                                         "invalid :nn_nn_yyyy_month_day_order value '#{@param_H[ :nn_nn_yyyy_month_day_order ]}'"
                                    raise
                                end
                            elsif ( date_found_S.as_date_S.pattern_name.match?( /(__MMM_dd_dd_yy|__MMM_dd_MMM_dd_yy|__MMM_MMM_yy)/ )) then  # These will pickup the _yyyy pattern too.
                                year =  pattern_RE_named_captures[ 'year_M' ]
                                if ( pattern_RE_named_captures.key?( 'thru_month_M' )) then
                                    month = pattern_RE_named_captures[ 'thru_month_M' ]
                                else
                                    month = pattern_RE_named_captures[ 'month_M' ]
                                end
                                if ( pattern_RE_named_captures.key?( 'thru_day_M' )) then
                                    day = pattern_RE_named_captures[ 'thru_day_M' ]
                                else
                                    day = pattern_RE_named_captures[ 'day_M' ]
                                end
                            else
                                year =  pattern_RE_named_captures[ 'thru_year_M' ]
                                month = pattern_RE_named_captures[ 'thru_month_M' ]
                                day =   pattern_RE_named_captures[ 'thru_day_M' ] 
                            end                         
                        else
                            Se.puts "#{Se.lineno}: I shouldn't be here: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                 "'#{date_found_S.as_date_S.all_pieces}' > "+
                                                 "'#{date_found_S.as_date_S.piece( 1 )}' ft_sym not :from or :thru"
                            raise
                        end #case
                        
                        # p month, day, year
                        if ( year == nil or ( month == nil and day )) then
                            Se.puts "#{Se.lineno}: I shouldn't be here: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                 "'#{date_found_S.as_date_S.all_pieces}' > "+
                                                 "'#{date_found_S.as_date_S.piece( 1 )}' year == nil or ( month == nil and day)!"
                            Se.pp pattern_RE_match_O
                            raise
                        end     
                        if ( year.length == 4 and month == nil and day == nil )
                            if ( year < @param_H[ :yyyy_min_value] ) then
                                stringer = "#{Se.lineno}: Warning possible date dropped: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                        "'#{date_found_S.as_date_S.all_pieces}' -> "+
                                                        "'#{date_found_S.as_date_S.piece( 1 )}' isolated 4 digit number < #{@param_H[ :yyyy_min_value]}" 
                                Se.puts stringer
                                date_found_S.morality = :unjudged
                                date_found_S.as_date_S.error_msg = stringer
                                @date_found_A_S << date_found_S                                
                                throw :next_date
                            end
                            if ( year > @param_H[ :yyyy_max_value] ) then
                                stringer = "#{Se.lineno}: Warning possible date dropped: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                        "'#{date_found_S.as_date_S.all_pieces}' -> "+
                                                        "'#{date_found_S.as_date_S.piece( 1 )}' isolated 4 digit number > #{@param_H[ :yyyy_max_value]}" 
                                Se.puts stringer
                                date_found_S.morality = :unjudged
                                date_found_S.as_date_S.error_msg = stringer
                                @date_found_A_S << date_found_S         
                                throw :next_date
                            end
                        end
                        if ( year.length == 2 and month == nil and day == nil and 
                            not date_found_S.as_date_S.pattern_name.in?( ['fmt001__yy__double', 'fmt002__yyyy__double' ] ) ) then
                            stringer = "#{Se.lineno}: bad date: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                    "'#{date_found_S.as_date_S.all_pieces}' -> "+
                                                    "'#{date_found_S.as_date_S.piece( 1 )}' isolated 2 digit number" 
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end   
                        if ( day and not day.integer? ) then
                            stringer = "#{Se.lineno}: bad date: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                    "'#{date_found_S.as_date_S.all_pieces}' -> "+
                                                    "'#{date_found_S.as_date_S.piece( 1 )}' day not numeric: '#{day}'" 
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                        if ( not year.integer? ) then
                            stringer = "#{Se.lineno}: bad date: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                    "'#{date_found_S.as_date_S.all_pieces}' -> "+
                                                    "'#{date_found_S.as_date_S.piece( 1 )}' year not numeric: '#{year}'"
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
                        
                        if ( month and not month.integer? ) then
                            month_RE_match_O = month.match( /^(?<month_M>#{K.month_RE})/ )
                            if ( not month_RE_match_O == nil ) then
                                month_RE_named_captures = month_RE_match_O.named_captures
                                month = month_RE_named_captures[ 'month_M' ]
                            end
                            month.sub!( /\.$/, "" )           # Take the period off the months (eg Feb.)
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
                            Se.puts "#{Se.lineno}: I shouldn't be here: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                 "'#{date_found_S.as_date_S.all_pieces}' > "+
                                                 "'#{date_found_S.as_date_S.piece( 1 )}' ft_sym not :from or :thru"
                            raise
                        end 
                        
                        if ( month and month.integer? ) then
                            strptime_fmt = '%Y %m %d'
                        else
                            strptime_fmt = '%Y %b %d'
                        end
                        begin
                            strptime_O = Date::strptime( testdate, strptime_fmt )
                        rescue
                            stringer = "#{Se.lineno}: bad date: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                    "'#{date_found_S.as_date_S.all_pieces}' -> "+
                                                    "'#{date_found_S.as_date_S.piece( 1 )}' -> "+
                                                    "'#{testdate}' -> '#{strptime_fmt}' strptime conversion failed"
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                        if ( strptime_O.year < 0 ) then
                            stringer = "#{Se.lineno}: bad date: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                    "'#{date_found_S.as_date_S.all_pieces}' -> "+
                                                    "'#{date_found_S.as_date_S.piece( 1 )}' -> '#{strptime_O}' negative year"
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                        if ( day == nil and strptime_O.day != 1 ) then
                            Se.puts "#{Se.lineno}: I shouldn't be here: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: "+
                                                 "'#{date_found_S.as_date_S.all_pieces}' -> "+
                                                 "'#{date_found_S.as_date_S.piece( 1 )}' -> '#{strptime_O} day != 1"
                            raise
                        end
                        if ( day == nil and ft_sym == :thru ) then
                            strptime_O = strptime_O.last_day_of_month
                        end
                        # Se.puts "#{Se.lineno}: good date: #{date_found_S.as_date_S.pattern_name},#{ft_sym}: '#{date_found_S.as_date_S.all_pieces}' -> '#{strptime_O}'"
                        as_date_yyyy_mm_dd  = strptime_O.strftime( '%Y' )
                        as_date_yyyy_mm_dd += strptime_O.strftime( '-%m' ) if ( month )
                        as_date_yyyy_mm_dd += strptime_O.strftime( '-%d' ) if ( day )
                        date_validation_S[ ft_sym ].date = as_date_yyyy_mm_dd
                        date_validation_S[ ft_sym ].strptime_O = as_date_yyyy_mm_dd
                        
                        date_found_S.as_date_S.from_date = date_validation_S.from.date
                        date_found_S.as_date_S.thru_date = date_validation_S.thru.date
    
                        if ( ft_sym == :from and date_found_S.as_date_S.piece( 0 ) =~ /#{@thru_date_separator_RE}/ ) then
                            stringer = "#{Se.lineno}: bad date: #{date_found_S.as_date_S.pattern_name}: '#{date_found_S.as_date_S.all_pieces}' -> "+
                                                    "'#{date_found_S.as_date_S.piece( 1 )}' dangling thru-date pattern in begin_M '#{date_found_S.as_date_S.piece( 0 )}'" 
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                        
                        if ( ft_sym == :from and date_found_S.as_date_S.piece( 2 ) =~ /#{@thru_date_separator_RE}/ ) then
                            stringer = "#{Se.lineno}: bad date: #{date_found_S.as_date_S.pattern_name}: '#{date_found_S.as_date_S.all_pieces}' -> "+
                                                    "'#{date_found_S.as_date_S.piece( 1 )}' dangling thru-date pattern in end_M '#{date_found_S.as_date_S.piece( 2 )}'" 
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                        if ( ft_sym == :thru and pattern_RE_named_captures.key?( 'extra_dates_M' ) and pattern_RE_named_captures[ 'extra_dates_M' ] != "" ) then
                            stringer = "#{Se.lineno}: bad date: #{date_found_S.as_date_S.pattern_name}: '#{date_found_S.as_date_S.all_pieces}' -> "+
                                                    "'#{date_found_S.as_date_S.piece( 1 )}' extra thru dates found '#{pattern_RE_named_captures[ 'extra_dates_M' ]}'" 
                            Se.puts stringer
                            date_found_S.morality = :bad
                            date_found_S.as_date_S.error_msg = stringer
                            @date_found_A_S << date_found_S
                            throw :next_date
                        end
                    end
                    if ( date_validation_S.thru[ 1 ] and date_validation_S.from[ 1 ] > date_validation_S.thru[ 1 ] ) then
                        stringer = "#{Se.lineno}: bad date: #{date_found_S.as_date_S.pattern_name}: '#{date_found_S.as_date_S.all_pieces}' "+
                                                "From date > thru date"
                        Se.puts stringer
                        date_found_S.morality = :bad
                        date_found_S.as_date_S.error_msg = stringer
                        @date_found_A_S << date_found_S
                        throw :next_date
                    end

                    # Se.pp @date_found_A_S 
                    if ( @param_H[ :debug_options ].include?( :print_good_dates ) ) then
                        stringer = "#{Se.lineno}: good date: #{date_found_S.as_date_S.pattern_name}: '#{date_found_S.as_date_S.all_pieces}'"
                        Se.puts stringer
                    end
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
            morality = date_found_S.morality
            if ( morality == :unjudged ) then
                replace_option = :keep
            else
                replace_option = @param_H[ :morality_replace_option ][ date_found_S.morality ]
            end
            case replace_option
            when :keep
                begin
                    stringer = date_found_S.as_date_S.pattern_piece_A[ 0 ] + date_found_S.as_date_S.pattern_piece_A[ 1 ]
                    if ( date_found_S.as_date_S.pattern_piece_A[ 0 ].match?( /^#{@thru_date_separator_RE}/ ) ) then
                        stringer = "  (date?)" + stringer
                    end
                    if ( date_found_S.as_date_S.pattern_piece_A[ 2 ].match?( /#{@thru_date_separator_RE}$/ ) ) then
                        stringer = stringer + "(date?)  "
                    end
                    process_string[ date_found_S.replace_uid ]                        = stringer
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
                Se.puts "#{Se.lineno}: I shouldn't be here, unknown replace_option for morality '#{date_found_S.morality}' -> "+
                                     "'#{@param_H[ :morality_replace_option ][ date_found_S.morality ]}'"
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
            when :unjudged
#               Skip it
            else
                Se.puts "#{Se.lineno}: I shouldn't be here: amoral date: '#{date_found_S.morality}', #{date_found_S}"
                raise
            end
        end
        if ( @param_H[ :sort ] ) then
            @good_date_A_S = @good_date_A_S.sort_by { | element_S | [ element_S.from_date ] }
            prev_date=''
            @good_date_A_S.each_with_index do | element_S, idx |
                if ( element_S.from_date < prev_date ) then
                    Se.puts "#Se.lineno: Warning: Dates overlap! good from-date '#{element_S.from_date} at element #{idx} "+
                            "< previous date #{prev_date}, there may be others."
                    break
                end
                prev_date = (element_S.thru_date = '') ? element_S.from_date : element_S.thru_date
            end
        end
        # Se.pp process_string    
        case @param_H[ :date_string_composition ]
        when :dates_in_text 
            if (process_string_with_all_dates_removed =~ K.month_RE ) then
                Se.puts "#{Se.lineno}: Warning possible ummatched date in '#{process_string_with_all_dates_removed}'"
            end
        when :only_dates
            if (process_string_with_all_dates_removed !~ /^\s*$/ ) then
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

end


