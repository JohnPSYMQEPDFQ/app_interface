#   Part of class.Find_Dates_in_String.rb

module Output_Date_Text_Validation

    public  attr_reader :output_data_uid_H_H    
    private attr_writer :output_data_uid_H_H
               
    #   NOTE:   "def self.initialize" will initialize module variables, NOT the instance variables of the class
    #           the module is included in !!!!!!  See the comment in 'Find_Dates_in_String::initialize' for how
    #           to call a module's "def initialize".  BUT, the "def initialize" is called ONLY at
    #           instance initialize!!!  If the module is supposed to initialize some variables FOR the module
    #           each time a method is called in the class, I decided to name a module method the same name
    #           as the instance method and call it like is being done for "def initialize".
    #           See the :do_find method in "class.Find_Dates_in_String.rb".               
    def do_find
        self.output_data_uid_H_H = {}  
    end
       
    def print_before_change_params( my_creator, before_change_string, argv )
        SE.q {[ 'my_creator.__id__' ]}
        SE.q {[ 'before_change_string' ]}
        SE.q {[ 'argv' ]}
    end
    def before_change_validate( my_creator, before_change_string, argv )
        if ( option_H[ :debug_options ].include?( :print_before )) then
            SE.puts "==========================================================="    
            SE.q {[ 'SE.stack( SE.my_source_code_path )' ]}    
            SE.q {[ 'before_change_string' ]}
            SE.q {[ 'argv' ]}
        end   
        output_data_uid_H_H[ my_creator.__id__ ].tap do | output_data_uid_H |            
            if ( output_data_uid_H.nil? ) then
                SE.puts "#{SE.lineno}: Unable to find my_creator.__id__ '#{my_creator.__id__}' in 'output_data_uid_H_H'"
                print_before_change_params( my_creator, before_change_string, argv )
                SE.q {[ 'output_data_uid_H' ]}
                raise
            end
            date_clump_uid__from_argv = nil
            if ( argv.first.is_a?( String ) and argv.first.match( date_clump_uid_O.pattern_RE ) ) then
                date_clump_uid__from_argv = $&
                if  ( output_data_uid_H.has_no_key?( date_clump_uid__from_argv ) ) then
                    SE.puts "#{SE.lineno}: output_data_uid_H_H['#{my_creator.__id__}']['#{date_clump_uid__from_argv}'] is missing."
                    print_before_change_params( my_creator, before_change_string, argv )
                    SE.q {[ 'output_data_uid_H' ]}
                    raise
                end            
                if ( before_change_string.index( date_clump_uid__from_argv ).nil? ) then
                    SE.puts "#{SE.lineno}: Unable to find uid '#{date_clump_uid__from_argv}' in 'before_change_string'"
                    print_before_change_params( my_creator, before_change_string, argv ) 
                    SE.q {[ 'output_data_uid_H' ]}
                    raise
                end
            end
            if ( argv.last.is_a?( String) and argv.last.match( date_clump_uid_O.pattern_RE ) ) then
                date_clump_uid__from_argv = $&
                if  ( output_data_uid_H.has_key?( date_clump_uid__from_argv ) ) then
                    SE.puts "#{SE.lineno}: Found an already existing uid '#{date_clump_uid__from_argv}' in 'output_data_uid_H_H'"
                    print_before_change_params( my_creator, before_change_string, argv ) 
                    SE.q {[ 'output_data_uid_H' ]}
                    raise
                end
            end
            output_data_uid_H.keys.each do | date_clump_uid | 
                if ( before_change_string.index( date_clump_uid ).nil? ) then
                    SE.puts "#{SE.lineno}: Unable to find uid '#{date_clump_uid}' from 'output_data_uid_H_H' in 'before_change_string'"
                    print_before_change_params( my_creator, before_change_string, argv ) 
                    SE.q {[ 'output_data_uid_H' ]}
                    raise
                end
            end
        end
    end    

    def print_after_change_params( my_creator, before_change_string, after_change_string, argv )
        SE.q {[ 'my_creator.__id__' ]}
        SE.q {[ 'before_change_string' ]}
        SE.q {[ 'after_change_string' ]}
        SE.q {[ 'argv' ]}
    end
    def after_change_validate( my_creator, before_change_string, after_change_string, argv )  
        if ( option_H[ :debug_options ].include?( :print_after )) then
            SE.puts "==========================================================="
            SE.q {[ 'SE.stack( SE.my_source_code_path )' ]}
            SE.q {[ 'before_change_string']}
            SE.q {[ 'after_change_string' ]}
            SE.q {[ 'argv' ]}
        end
        if ( argv.is_a?( String ) )   #  This is the initial assign, eg. obj.string = 'xyz'.
            output_data_uid_H_H.delete( my_creator.__id__ ) if ( output_data_uid_H_H.has_key?( my_creator.__id__ ) ) 
            output_data_uid_H_H[ my_creator.__id__ ] = { }
            argv.scan( date_clump_uid_O.pattern_RE ).each do | date_clump_uid |
                date_clump_S = date_clump_S__A[ date_clump_uid_O.num_from_uid( date_clump_uid ) - 1 ]  # The number is 1 relative
                if ( not ( date_clump_S.not_nil? and date_clump_S.uid == date_clump_uid ) ) then
                    SE.puts "#{SE.lineno}: Couldn't find the uid '#{date_clump_uid}' in 'date_clump_S__A'"
                    print_after_change_params( my_creator, before_change_string, after_change_string, argv )
                    SE.q {[ 'output_data_uid_H' ]}
                    SE.q {[ 'date_clump_S' ]}
                    SE.q {[ 'date_clump_S__A' ]}
                    raise                
                end
                output_data_uid_H_H[ my_creator.__id__ ][ date_clump_uid ] = date_clump_S
            end
            return
        end
        output_data_uid_H_H[ my_creator.__id__ ] = {} if ( output_data_uid_H_H.has_no_key?( my_creator.__id__ ) ) 
        output_data_uid_H_H[ my_creator.__id__ ].tap do | output_data_uid_H |       
            date_clump_uid__from_argv = nil
            if ( argv.first.is_a?( String) and argv.first.match( date_clump_uid_O.pattern_RE ) ) then
                date_clump_uid__from_argv = $&
                if  ( output_data_uid_H.key?( date_clump_uid__from_argv ) ) then
                    output_data_uid_H.delete( date_clump_uid__from_argv )
                else
                    SE.puts "#{SE.lineno}: Couldn't find the uid '#{date_clump_uid}' in 'output_data_uid_H'"
                    print_after_change_params( my_creator, before_change_string, after_change_string, argv )
                    SE.q {[ 'output_data_uid_H' ]}
                    raise
                end      
            end
            if ( argv.last.is_a?( String ) and argv.last.match( date_clump_uid_O.pattern_RE ) ) then
                date_clump_uid__from_argv = $&
                if ( after_change_string.index( date_clump_uid__from_argv ).nil? ) then
                    SE.puts "#{SE.lineno}: Couldn't find the just added uid '#{date_clump_uid__from_argv}' in 'after_change_string'"
                    print_after_change_params( my_creator, before_change_string, after_change_string, argv )
                    SE.q {[ 'output_data_uid_H' ]}
                    raise
                end
                date_clump_S = date_clump_S__A[ date_clump_uid_O.num_from_uid( date_clump_uid__from_argv ) - 1 ]  # The number is 1 relative
                if ( not ( date_clump_S.not_nil? and date_clump_S.uid == date_clump_uid__from_argv ) ) then
                    SE.puts "#{SE.lineno}: Couldn't find the just added uid '#{date_clump_uid__from_argv}' in 'date_clump_S__A'"
                    print_after_change_params( my_creator, before_change_string, after_change_string, argv )
                    SE.q {[ 'output_data_uid_H' ]}
                    SE.q {[ 'date_clump_S' ]}         
                    SE.q {[ 'date_clump_S__A' ]}
                    raise                
                end
                output_data_uid_H[ date_clump_uid__from_argv ] = date_clump_S       
            end
            
            cnt = 0
            output_data_uid_H.keys.each do | date_clump_uid | 
                if ( after_change_string.index( date_clump_uid ).nil? ) then
                    SE.puts "#{SE.lineno}: Unable to find uid '#{date_clump_uid}' from 'output_data_uid_H_H' in 'after_change_string'"
                    print_after_change_params( my_creator, before_change_string, after_change_string, argv )
                    SE.q {[ 'output_data_uid_H' ]}
                    SE.q {[ 'date_clump_S__A[ date_clump_uid_O.num_from_uid( date_clump_uid__from_argv ) - 1 ]' ]} if ( date_clump_uid__from_argv )
                    raise
                end
                cnt += 1
            end
            if ( cnt != output_data_uid_H.keys.count ) then
                SE.puts "#{SE.lineno}: Bad key count."
                print_after_change_params( my_creator, before_change_string, after_change_string, argv )
                SE.q {[ 'output_data_uid_H' ]}
                SE.q {[ 'cnt', 'output_data_uid_H.keys.count' ]}
                raise
            end
        end
        if ( after_change_string.match( /(#{date_clump_uid_O.pattern_RES.rstrip}\s{0,1}#{date_clump_uid_O.pattern_RES.lstrip})/ ) ) then
            SE.puts "#{SE.lineno}: Found 2 date_clumps squeezed together."
            SE.q {[ '$&' ]}
            print_after_change_params( my_creator, before_change_string, after_change_string, argv )
            SE.q {[ 'output_data_uid_H' ]}
            SE.q {[ 'date_clump_S__A[ date_clump_uid_O.num_from_uid( date_clump_uid__from_argv ) - 1 ]' ]} if ( date_clump_uid__from_argv )
            raise
        end
    end
    
end
