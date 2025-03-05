#   Part of class.Find_Dates_in_String.rb

module Date_Clumps_convert_back_to_text_dates
    
    def date_clumps_convert_back_to_text_dates()
        date_clump_S__A.each do | date_clump_S |
#           self.date_clump_S = date_clump_S   # so the string validation routines can see it?  No idea why the validation routine works...
#           SE.q {[ 'date_clump_S.class' ]}
            replace_option = option_H[ :morality_replace_option ][ date_clump_S.morality ]
            case replace_option
            when :keep                
                output_data_O.string[ date_clump_S.uid ]                        = date_clump_S.full_match_string__with_original_dates
                output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''
                                
            when :replace                
                output_data_O.string[ date_clump_S.uid ]                        = date_clump_S.full_match_string__with_as_dates
                output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''

            when :remove_from_end
                    #   output_data_O.string uid's removed below...
                output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''

            when :remove
                output_data_O.string[ date_clump_S.uid ]                        = ''
                output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''                
            else
                SE.puts "#{SE.lineno}: I shouldn't be here, unknown replace_option for morality '#{date_clump_S.morality}' -> "+
                                     "'#{option_H[ :morality_replace_option ][ date_clump_S.morality ]}'"
                SE.q { 'date_clump_S' }
                raise
            end
        end
        if ( option_H[ :morality_replace_option ][ :good ] == :remove_from_end ) then
            look_ahead_RES = "(?=([^#{date_clump_uid_O.date_clump_punct_chars[ 0 ]}#{date_clump_uid_O.date_clump_punct_chars[ 1 ]}]))"
            loop do
                output_data_O.string.sub!( /#{look_ahead_RES}#{thru_date_end_delim_RES}\s*$/, ' ' )  #  There need to be at least one space at the end!
                if ( output_data_O.string.match( /(#{date_clump_uid_O.pattern_RES})\s*$/ ) ) then
                    date_clump_uid = $&                   
                    output_data_O.string[ date_clump_uid ] = ''
                    output_data_O.string.sub!( /#{look_ahead_RES}#{begin_delim_RES}\s*$/, ' ' )  #  There need to be at least one space at the end!
                else
                    break
                end
            end
            while ( output_data_O.string.match( date_clump_uid_O.pattern_RE ) ) 
                date_clump_uid = $&
                date_clump_S = date_clump_S__A[ date_clump_uid_O.num_from_uid( date_clump_uid ) - 1 ]  # The number is 1 relative                      
                output_data_O.string[ date_clump_uid ] = date_clump_S.full_match_string__with_original_dates
            end
        end
    end
end
