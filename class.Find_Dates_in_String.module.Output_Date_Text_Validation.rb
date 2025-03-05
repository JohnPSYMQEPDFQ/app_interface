#   Part of class.Find_Dates_in_String.rb

module Output_Date_Text_Validation
    
    def before_change_validate( before_change_string, argv )
        if ( option_H[ :debug_options ].include?( :print_before )) then
            SE.puts "==========================================================="    
            SE.q {[ 'SE.stack( SE.my_source_code_path )' ]}    
            SE.q {[ 'before_change_string' ]}
            SE.q {[ 'argv' ]}
        end
      # SE.q {[ 'date_clump_S.class' ]}
      # SE.q {[ 'date_clump_S' ]}            
        if ( argv.first.is_a?( String ) and argv.first.match( date_clump_uid_O.pattern_RE ) ) then
            date_clump_uid__from_argv = $&
            if  ( output_data_uid_H.has_no_key?( date_clump_uid__from_argv ) ) then
                SE.puts "#{SE.lineno}: output_data_uid_H['#{date_clump_uid__from_argv}'] is missing."
                SE.q {[ 'before_change_string' ]}
                SE.q {[ 'argv' ]}
                SE.q {[ 'output_data_uid_H' ]}
                raise
            end            
            if ( before_change_string.index( date_clump_uid__from_argv ).nil? ) then
                SE.puts "#{SE.lineno}: Unable to find uid '#{date_clump_uid__from_argv}' in 'before_change_string'"
                SE.q {[ 'before_change_string' ]}
                SE.q {[ 'argv' ]}
                raise
            end
        end
        if ( argv.last.is_a?( String) and argv.last.match( date_clump_uid_O.pattern_RE ) ) then
            date_clump_uid__from_argv = $&
            if  ( output_data_uid_H.has_key?( date_clump_uid__from_argv ) ) then
                SE.puts "#{SE.lineno}: Found an already existing uid '#{date_clump_uid__from_argv}' in 'output_data_uid_H'"
                SE.q {[ 'before_change_string' ]}
                SE.q {[ 'argv' ]}
                SE.q {[ 'output_data_uid_H[ date_clump_uid__from_argv ]' ]}
                raise
            end
        end
        output_data_uid_H.keys.each do | date_clump_uid | 
            if ( before_change_string.index( date_clump_uid ).nil? ) then
                SE.puts "#{SE.lineno}: Unable to find uid '#{date_clump_uid}' from 'output_data_uid_H' in 'before_change_string'"
                SE.q {[ 'before_change_string' ]}
                SE.q {[ 'argv' ]}
                SE.q {[ 'date_clump_S__A[ date_clump_uid_O.num_from_uid( date_clump_uid__from_argv ) - 1 ]' ]} if ( date_clump_uid__from_argv )
                SE.q {[ 'output_data_uid_H[ date_clump_uid ]' ]}
                raise
            end
        end
    end    

    def after_change_validate( before_change_string, after_change_string, argv )  
        if ( option_H[ :debug_options ].include?( :print_after )) then
            SE.puts "==========================================================="
            SE.q {[ 'SE.stack( SE.my_source_code_path )' ]}
            SE.q {[ 'before_change_string']}
            SE.q {[ 'after_change_string' ]}
            SE.q {[ 'argv' ]}
        end
        return if ( argv.is_a?( String ) )   #  This is the initial assign which doesn't need checking.
        date_clump_uid__from_argv = nil
        if ( argv.first.is_a?( String) and argv.first.match( date_clump_uid_O.pattern_RE ) ) then
            date_clump_uid__from_argv = $&
            if  ( output_data_uid_H.has_no_key?( date_clump_uid__from_argv ) ) then
                SE.puts "#{SE.lineno}: output_data_uid_H['#{date_clump_uid__from_argv}'] is missing."
                SE.q {[ 'before_change_string' ]}
                SE.q {[ 'after_change_string' ]}
                SE.q {[ 'argv' ]}
                SE.q {[ 'output_data_uid_H' ]}
                raise
            end      
          # SE.puts "#{SE.lineno}: Deleted '#{date_clump_uid__from_argv}'"
            output_data_uid_H.delete( date_clump_uid__from_argv )
        end
        if ( argv.last.is_a?( String) and argv.last.match( date_clump_uid_O.pattern_RE ) ) then
            date_clump_uid__from_argv = $&
            if ( after_change_string.index( date_clump_uid__from_argv ).nil? ) then
                SE.puts "#{SE.lineno}: Couldn't find the just added uid '#{date_clump_uid__from_argv}' in 'after_change_string'"
                SE.q {[ 'before_change_string' ]}
                SE.q {[ 'after_change_string' ]}
                SE.q {[ 'argv' ]}
                SE.q {[ 'output_data_uid_H' ]}
                raise
            end
            date_clump_S = date_clump_S__A[ date_clump_uid_O.num_from_uid( date_clump_uid__from_argv ) - 1 ]  # The number is 1 relative
            if ( not ( date_clump_S.not_nil? and date_clump_S.uid == date_clump_uid__from_argv ) ) then
                SE.puts "#{SE.lineno}: Couldn't find the just added uid '#{date_clump_uid__from_argv}' in 'date_clump_S__A'"
                SE.q {[ 'before_change_string' ]}
                SE.q {[ 'after_change_string' ]}
                SE.q {[ 'argv' ]}
                SE.q {[ 'date_clump_S' ]}
                SE.q {[ 'output_data_uid_H' ]}               
                SE.q {[ 'date_clump_S__A' ]}
                raise                
            end
            output_data_uid_H[ date_clump_uid__from_argv ] = date_clump_S
          # SE.puts "#{SE.lineno}: Added '#{date_clump_uid__from_argv}'"            
        end
        
        cnt = 0
        output_data_uid_H.keys.each do | date_clump_uid | 
            if ( after_change_string.index( date_clump_uid ).nil? ) then
                SE.puts "#{SE.lineno}: Unable to find uid '#{date_clump_uid}' from 'output_data_uid_H' in 'after_change_string'"
                SE.q {[ 'before_change_string' ]}
                SE.q {[ 'after_change_string' ]}
                SE.q {[ 'argv' ]}
                SE.q {[ 'date_clump_S__A[ date_clump_uid_O.num_from_uid( date_clump_uid__from_argv ) - 1 ]' ]} if ( date_clump_uid__from_argv )
                SE.q {[ 'output_data_uid_H[ date_clump_uid ]' ]}
                raise
            end
            cnt += 1
        end
        if ( cnt != output_data_uid_H.keys.count ) then
            SE.puts "#{SE.lineno}: Bad key count."
            SE.q {[ 'before_change_string' ]}
            SE.q {[ 'after_change_string' ]}
            SE.q {[ 'argv' ]}
            SE.q {[ 'output_data_uid_H' ]}
            raise
        end
        
        if ( after_change_string.match( /(#{date_clump_uid_O.pattern_RES.rstrip}\s{0,1}#{date_clump_uid_O.pattern_RES.lstrip})/ ) ) then
            SE.puts "#{SE.lineno}: Found 2 date_clumps squeezed together."
            SE.q {[ '$&' ]}
            SE.q {[ 'before_change_string' ]}
            SE.q {[ 'after_change_string' ]}
            SE.q {[ 'argv' ]}
            SE.q {[ 'date_clump_S__A[ date_clump_uid_O.num_from_uid( date_clump_uid__from_argv ) - 1 ]' ]} if ( date_clump_uid__from_argv )
            raise
        end
    end
    
end
