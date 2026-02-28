#   Part of class.Find_Dates_in_String.rb

module Date_Clumps_convert_back_to_text_dates
    
    def date_clumps_convert_back_to_text_dates()
        date_clump_S__A.each do | date_clump_S |
#           self.date_clump_S = date_clump_S   # so the string validation routines can see it?  No idea why the validation routine works...
#           SE.q {[ 'date_clump_S.class' ]}
            replace_option = self.option_H[ Find_Dates_in_String::MORALITY_OPTION ][ date_clump_S.morality ]
            case replace_option
            when Find_Dates_in_String::KEEP_ALL                
                self.output_data_O.string[ date_clump_S.uid ]                        = date_clump_S.full_match_string__with_original_dates_and_modifiers
                self.output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''
                date_clump_S.morality_action                                 = Find_Dates_in_String::DATE_KEPT
                                
            when Find_Dates_in_String::REPLACE_ALL                
                self.output_data_O.string[ date_clump_S.uid ]                        = date_clump_S.full_match_string__with_as_dates
                self.output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''
                date_clump_S.morality_action                                 = Find_Dates_in_String::DATE_REPLACED

            when Find_Dates_in_String::REMOVE_FROM_END
#                       The self.output_data_O.string uid's are removed below...
                self.output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''
#               date_clump_S.morality_action    THIS CANNOT BE HERE!!!!  SEE BELOW.
            when Find_Dates_in_String::REMOVE_ALL
                self.output_data_O.string[ date_clump_S.uid ]                        = ''
                self.output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''  
                date_clump_S.morality_action                                 = Find_Dates_in_String::DATE_REMOVED
            else
                SE.puts "#{SE.lineno}: I shouldn't be here, unknown replace_option for morality '#{date_clump_S.morality}' -> "+
                        "'#{self.option_H[ Find_Dates_in_String::MORALITY_OPTION ][ date_clump_S.morality ]}'"
                SE.q { 'date_clump_S' }
                raise
            end
        end
        if ( self.option_H[ Find_Dates_in_String::MORALITY_OPTION ][ :good ] == Find_Dates_in_String::REMOVE_FROM_END ) then
            loop do
                matchdata_O = self.output_data_O.string.match( /(#{self.date_clump_uid_O.pattern_RES})(#{self.begin_delim_RES}|#{self.end_delim_RES})\s*$/ )
                break if ( matchdata_O.nil? )
                date_clump_uid = matchdata_O[ 1 ] 
                date_clump_S = date_clump_S__A[ self.date_clump_uid_O.num_from_uid( date_clump_uid ) - 1 ]  # The number is 1 relative
                self.output_data_O.string[ date_clump_uid ] = 3.chr   # We've got to use the string[ uid ] way because of the validation logic
                self.output_data_O.string.sub!( /#{3.chr}.*$/, '' )
                date_clump_S.morality_action  = Find_Dates_in_String::DATE_REMOVED_FROM_END
            end
            while ( output_data_O.string.match( date_clump_uid_O.pattern_RE ) ) 
                date_clump_uid = $&
                date_clump_S = date_clump_S__A[ self.date_clump_uid_O.num_from_uid( date_clump_uid ) - 1 ]  # The number is 1 relative                                       
                self.output_data_O.string[ date_clump_uid ] = date_clump_S.full_match_string__with_original_dates_and_modifiers
                date_clump_S.morality_action  = Find_Dates_in_String::DATE_KEPT
            end
        end
    end
end
