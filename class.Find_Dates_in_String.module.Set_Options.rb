#   Part of class.Find_Dates_in_String.rb

module Set_Options

    public  attr_reader :option_H
    private attr_writer :option_H
    
    # def param__option_H=( options_to_set_H )
        # SE.puts "I can never have this method because the date formats are setup at initialization"
        # SE.puts "and it's way to easy to think that setting an option will change the behavior"
        # SE.puts "when - in fact - the behavior is in the formats.  You then spend hours trying to"
        # SE.puts "figure out why changing the { :default_century_pivot_ccyymmdd => '1900' } with this method"
        # SE.puts "doesn't change how the program finds dates."
        # raise
    # end

    def set_options( param__option_H  )
        if ( not param__option_H.is_a?( Hash ) ) then
            SE.puts "#{SE.lineno}: Expected param to be a type HASH."
            SE.q { 'param__option_H' }
            raise
        end
        
        self.option_H = param__option_H.merge( {} )
        self.option_H.each_key do | option_H_key |
            case option_H_key
            when :debug_options
                case true
                when self.option_H[ option_H_key ].is_a?( Hash )
                    self.option_H[ option_H_key ].each_pair do | key, value |
                        if ( not key.is_a?( Symbol ) ) then
                            SE.puts "#{SE.lineno}: Expected '#{key}' to be of type 'Symbol', not '#{key.class}'"
                            SE.q { 'key' }
                            SE.q { 'param__option_H' }
                            raise
                        end
                        SE.puts "#{SE.lineno}: Debug option: ':#{key}' = '#{value}' set.  Note: Option spelling is NOT checked!!!"
                    end
                when self.option_H[ option_H_key ].is_a?( Symbol )  
                    h = { self.option_H[ option_H_key ] => nil }
                    SE.puts "#{SE.lineno}: Debug option: ':#{self.option_H[ option_H_key]}' = 'nil' set.  Note: Option spelling is NOT checked!!!"
                    self.option_H[ option_H_key ] = h
                when self.option_H[ option_H_key ].is_a?( Array )
                    h = {}
                    self.option_H[ option_H_key ].each do | element |
                        if ( not element.is_a?( Symbol ) ) then
                            SE.puts "#{SE.lineno}: Expected '#{element}' to be of type 'Symbol', not '#{element.class}'"
                            SE.q { 'element' }
                            SE.q { 'param__option_H' }
                            raise
                        end
                        SE.puts "#{SE.lineno}: Debug option: ':#{element}' = 'nil' set.  Note: Option spelling is NOT checked!!!"
                        h[ element ] = nil                        
                    end
                    self.option_H[ option_H_key ] = h
                else
                    SE.puts "#{SE.lineno}: Expected '#{option_H_key}' to be of type Symbol, Hash, or Array, not '#{self.option_H[ option_H_key ].class}'"
                    SE.q { 'param__option_H' }
                    raise
                end               
            when Find_Dates_in_String::MORALITY_OPTION
                if ( not self.option_H[ option_H_key ].is_a?( Hash ) ) then
                    SE.puts "#{SE.lineno}: Expected '#{option_H_key}' to be a type Hash, not '#{self.option_H[ option_H_key ].class}'"
                    SE.q { 'param__option_H' }
                    raise
                end
                self.option_H[ option_H_key ].each_pair do | key, value |
                    case key
                    when :good
                        if ( not ( value.is_a?( Symbol ) and value.in?( [ Find_Dates_in_String::KEEP_ALL, Find_Dates_in_String::REPLACE_ALL, Find_Dates_in_String::REMOVE_ALL, Find_Dates_in_String::REMOVE_FROM_END ] ) ) ) then
                            SE.puts "#{SE.lineno}: param__option_H[ Find_Dates_in_String::MORALITY_OPTION ][ #{key} ] should be [ Find_Dates_in_String::KEEP_ALL, Find_Dates_in_String::REPLACE_ALL, Find_Dates_in_String::REMOVE_ALL, Find_Dates_in_String::REMOVE_FROM_END ]"
                            SE.q { 'param__option_H' }
                            raise
                        end
                    when :bad
                        if ( not ( value.is_a?( Symbol ) and value.in?( [ Find_Dates_in_String::KEEP_ALL, Find_Dates_in_String::REMOVE_ALL ] ) ) ) then
                            SE.puts "#{SE.lineno}: param__option_H[ Find_Dates_in_String::MORALITY_OPTION ][ #{key} ] should be [ Find_Dates_in_String::KEEP_ALL, Find_Dates_in_String::REMOVE_ALL ]"
                            SE.q { 'param__option_H' }
                            raise
                        end
                    else
                        SE.puts "#{SE.lineno}: unknown Find_Dates_in_String::MORALITY_OPTION '#{key}', it should either be :good or :bad (obviously)"
                        SE.q { 'param__option_H' }
                        raise
                    end
                end
            when :thru_date_separators
                case true
                when self.option_H[ option_H_key ].is_a?( Array ) then
                    ary = []
                    self.option_H[ option_H_key ].each do | separator |
                        separator.strip!
                        ary << separator
                    end
                    self.option_H[ option_H_key ] = ary.join( '|' ) 
                when self.option_H[ option_H_key ].is_a?( String )
                    # keep going...
                else
                    SE.puts "#{SE.lineno}: Expected '#{option_H_key}' to be of type Array or String not '#{self.option_H[ option_H_key ].class}'"
                    SE.puts "#{SE.lineno}: If an array, it will be join with a '|'. The default is: '[-]| to | thru | through '."
                    SE.q { 'param__option_H' }
                    raise
                end  
                self.separation_punctuation_O.reserve_punctuation_chars( /#{self.option_H[ option_H_key ]}/ )
            when :date_text_separators
                if ( self.option_H[ option_H_key ].is_a?( Symbol ) ) then
                    if ( self.option_H[ option_H_key ] == :none ) then
                        self.option_H[ :date_text_separators ] = 29.chr                        #  Use 29.chr for none
                    else
                        SE.puts "#{SE.lineno}: param__option_H[ :date_text_separators ] should be :none, or [xyz] (where xyz = some separators)."
                        SE.puts "#{SE.lineno}: The default is '[\|]| and '"
                        SE.q { 'param__option_H' }
                        raise
                    end
                else
                    self.separation_punctuation_O.reserve_punctuation_chars( /#{self.option_H[ option_H_key ]}/ )
                end
            when :pattern_name_RES
                if ( not self.option_H[ option_H_key ].is_a?( String ) ) then
                    SE.puts "#{SE.lineno}: param__option_H[ :pattern_name_RES ] should be an String that will convert to a regexp."
                    SE.q { 'param__option_H' }
                    raise
                end
            when :default_century_pivot_ccyymmdd      #pivot date.  
                case self.option_H[ option_H_key ].to_s.length
                when 2 
                    testdate = "#{self.option_H[ option_H_key ]}000101"     # 19 -> 1900/01/01
                when 4
                    testdate = "#{self.option_H[ option_H_key ]}0101"
                when 6
                    testdate = "#{self.option_H[ option_H_key ]}01"
                when 8
                    testdate = "#{self.option_H[ option_H_key ]}"
                else
                    SE.puts "#{SE.lineno}: Expected the :default_century_pivot_ccyymmdd to in 'cc[yy[mm[dd]]]' format not '#{self.option_H[ option_H_key ]}'"
                    raise
                end
                strptime_O = do_strptime( testdate, '%Y%m%d' )
                if ( do_strptime( testdate, '%Y%m%d' ).nil? ) then
                    SE.puts "#{SE.lineno}: The :default_century_pivot_ccyymmdd (#{self.option_H[ option_H_key ]}) is invalid."
                    raise
                end
                self.option_H[ option_H_key ] = strptime_O 
            when :yyyymmdd_min_value 
                case self.option_H[ option_H_key ].to_s.length
                when 4
                    testdate = "#{self.option_H[ option_H_key ]}0101"
                when 6
                    testdate = "#{self.option_H[ option_H_key ]}01"
                when 8
                    testdate = "#{self.option_H[ option_H_key ]}"
                else
                    SE.puts "#{SE.lineno}: Expected the :yyyymmdd_min_value to in 'yyyy[mm[dd]]' format not '#{self.option_H[ option_H_key ]}'"
                    raise
                end
                strptime_O = do_strptime( testdate, '%Y%m%d' )
                if ( do_strptime( testdate, '%Y%m%d' ).nil? ) then
                    SE.puts "#{SE.lineno}: The :yyyymmdd_min_value (#{self.option_H[ option_H_key ]}) is an invalid date."
                    raise
                end
                self.option_H[ option_H_key ] = strptime_O                
            when :yyyymmdd_max_value 
                case self.option_H[ option_H_key ].to_s.length
                when 4
                    testdate = "#{self.option_H[ option_H_key ]}1201"  # Dec 01 - Set to 'last_day_of_month' below.
                when 6
                    testdate = "#{self.option_H[ option_H_key ]}01"    # 1st day of month - Set to 'last_day_of_month' below.
                when 8
                    testdate = "#{self.option_H[ option_H_key ]}"
                else
                    SE.puts "#{SE.lineno}: Expected the :yyyymmdd_max_value to in 'yyyymmdd' format not '#{self.option_H[ option_H_key ]}'"
                    raise
                end
                strptime_O = do_strptime( testdate, '%Y%m%d' )
                if ( do_strptime( testdate, '%Y%m%d' ).nil? ) then
                    SE.puts "#{SE.lineno}: The :yyyymmdd_max_value (#{self.option_H[ option_H_key ]}) is an invalid date."
                    raise
                end
                self.option_H[ option_H_key ] = strptime_O.last_day_of_month         
            when :date_string_composition
                if ( not (self.option_H[ option_H_key ].is_a?( Symbol ) and self.option_H[ option_H_key ].in?( [ :only_dates, :dates_in_text ] ))) then
                    SE.puts "#{SE.lineno}: Expected :date_string_composition to be :only_dates or :dates_in_text, not '#{self.option_H[ option_H_key ]}'"
                    raise
                end
            when :nn_mmm_nn_day_year_order
                if ( not (self.option_H[ option_H_key ].is_a?( Symbol ) and self.option_H[ option_H_key ].in?( [ :dd_mm_yy, :yy_mm_dd ] ))) then
                    SE.puts "#{SE.lineno}: Expected :nn_mmm_nn_day_year_order to be :dd_mm_yy or :yy_mm_dd, not '#{self.option_H[ option_H_key ]}'"
                    raise
                end
            when :nn_nn_nn_date_order
                if ( not (self.option_H[ option_H_key ].is_a?( Symbol ) and self.option_H[ option_H_key ].in?( [ :mm_dd_yy, :dd_mm_yy, :yy_mm_dd ] ))) then
                    SE.puts "#{SE.lineno}: Expected :nn_nn_nn_date_order to be :mm_dd_yy, :dd_mm_yy, or :yy_mm_dd not '#{self.option_H[ option_H_key ]}'"
                    raise
                end
            when :sort
                if ( not ( [true, false].include?( self.option_H[ option_H_key ] ) ) ) then
                    SE.puts "#{SE.lineno}: Expected '#{option_H_key}' to be true or false, not '#{self.option_H[ option_H_key ]}'"
                    SE.q { 'param__option_H' }
                    raise
                end
            else
                SE.puts "#{SE.lineno}: invalid param__option_H option: '#{option_H_key}'"
                SE.q { 'self.option_H' }
                SE.puts ''
                SE.puts "Here are the 'Find_Dates_in_String' allowed options, with default values:"
                SE.ap Find_Dates_in_String.new( ).self.option_H
                raise
            end
        end

        if ( not self.option_H.key?( :debug_options ) )
            self.option_H[ :debug_options ] = []
        end
        if ( not self.option_H.key?( Find_Dates_in_String::MORALITY_OPTION ) )
            self.option_H[ Find_Dates_in_String::MORALITY_OPTION ] = { }
        end
        if ( not self.option_H[ Find_Dates_in_String::MORALITY_OPTION ].key?( :good ) ) then
            self.option_H[ Find_Dates_in_String::MORALITY_OPTION ][ :good ] = Find_Dates_in_String::REMOVE_FROM_END
        end
        if ( not self.option_H[ Find_Dates_in_String::MORALITY_OPTION ].key?( :bad ) ) then
            self.option_H[ Find_Dates_in_String::MORALITY_OPTION ][ :bad ] = Find_Dates_in_String::KEEP_ALL
        end
        if ( not self.option_H.key?( :thru_date_separators ) ) then
            self.option_H[ :thru_date_separators ] = '[-]| to | thru | through '    # Beware of different dashes in the data! Do:  echo '-—–' | od -ctx1
            self.separation_punctuation_O.reserve_punctuation_chars( /#{self.option_H[ :thru_date_separators ]}/ )
        end
        if ( not self.option_H.key?( :date_text_separators ) ) then
            self.option_H[ :date_text_separators ] = '[\|]| and '  
            self.separation_punctuation_O.reserve_punctuation_chars( /#{self.option_H[ :date_text_separators ]}/ )            
        end
        if ( not self.option_H.key?( :pattern_name_RES ) )
        then
            self.option_H[ :pattern_name_RES ] = '.'
        end
        if ( not self.option_H.key?( :default_century_pivot_ccyymmdd ) )
        then
            self.option_H[ :default_century_pivot_ccyymmdd ] = nil              # If the default century is nil, only look for 4 digit dates.
        end
        if ( not self.option_H.key?( :date_string_composition ) ) then
            self.option_H[ :date_string_composition ] = :dates_in_text
        end
        if ( not self.option_H.key?( :yyyymmdd_min_value ) ) then
            self.option_H[ :yyyymmdd_min_value ] = do_strptime( '18000101', '%Y%m%d' )
        end
        if ( not self.option_H.key?( :yyyymmdd_max_value ) ) then
            self.option_H[ :yyyymmdd_max_value ] = do_strptime( '20991231', '%Y%m%d' )
        end
        if ( not self.option_H.key?( :nn_mmm_nn_day_year_order ) ) then
            self.option_H[ :nn_mmm_nn_day_year_order ] = :dd_mm_yy
        end
        if ( not self.option_H.key?( :nn_nn_nn_date_order ) ) then
            self.option_H[ :nn_nn_nn_date_order ] = :mm_dd_yy
        end
        if ( not self.option_H.key?( :sort ) ) then
            self.option_H[ :sort ] = true
        end        
    end
       
end
