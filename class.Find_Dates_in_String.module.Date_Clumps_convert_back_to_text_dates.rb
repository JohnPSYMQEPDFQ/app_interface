#   Part of class.Find_Dates_in_String.rb

module Date_Clumps_convert_back_to_text_dates
    
    def date_clumps_convert_back_to_text_dates()
        date_clump_S__A.each do | date_clump_S |
#           self.date_clump_S = date_clump_S   # so the string validation routines can see it?  No idea why the validation routine works...
#           SE.q {[ 'date_clump_S.class' ]}
            replace_option = self.option_H[ :morality_replace_option ][ date_clump_S.morality ]
            case replace_option
            when :keep                
                self.output_data_O.string[ date_clump_S.uid ]                        = date_clump_S.full_match_string__with_original_dates_and_modifiers
                self.output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''
                                
            when :replace                
                self.output_data_O.string[ date_clump_S.uid ]                        = date_clump_S.full_match_string__with_as_dates
                self.output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''

            when :remove_from_end
                    #   self.output_data_O.string uid's removed below...
                self.output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''

            when :remove
                self.output_data_O.string[ date_clump_S.uid ]                        = ''
                self.output_data_with_all_dates_removed_O.string[ date_clump_S.uid ] = ''                
            else
                SE.puts "#{SE.lineno}: I shouldn't be here, unknown replace_option for morality '#{date_clump_S.morality}' -> "+
                                     "'#{self.option_H[ :morality_replace_option ][ date_clump_S.morality ]}'"
                SE.q { 'date_clump_S' }
                raise
            end
        end
        if ( self.option_H[ :morality_replace_option ][ :good ] == :remove_from_end ) then
            loop do
                matchdata_O = self.output_data_O.string.match( /(#{self.date_clump_uid_O.pattern_RES})(#{self.begin_delim_RES}|#{self.end_delim_RES})\s*$/ )
                break if ( matchdata_O.nil? )
                date_clump_uid = matchdata_O[ 1 ] 
                self.output_data_O.string[ date_clump_uid ] = 3.chr   # We've got to use the string[ uid ] way because of the validation logic
                self.output_data_O.string.sub!( /#{3.chr}.*$/, '' )
            end
            while ( output_data_O.string.match( date_clump_uid_O.pattern_RE ) ) 
                date_clump_uid = $&
                date_clump_S = date_clump_S__A[ self.date_clump_uid_O.num_from_uid( date_clump_uid ) - 1 ]  # The number is 1 relative                      
                self.output_data_O.string[ date_clump_uid ] = date_clump_S.full_match_string__with_original_dates_and_modifiers
            end
        end
    end
end
