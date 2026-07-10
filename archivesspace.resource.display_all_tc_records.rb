=begin

    Display all the Top-Containers of a Resource, with a few different 
    print options.

=end

require 'json'
require 'optparse'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.TopContainer.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option_H = { :rep_num                     => 2  ,
                   :res_num                     => nil  ,
                   :print_ao_data_TF            => false ,
                   :filter                      => false ,
                   :additional_filter_items_A   => [] ,
                   :print_display_string_only   => false ,
                   :flattened                   => false,
                   :display                     => nil,
                  }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do |opt_arg|
        cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )." ) do |opt_arg|
        cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "--ao_data_too", "Print some AO data too." ) do |opt_arg|
        cmdln_option_H[ :print_ao_data_TF ]      = true
    end
    option.on( "--filter", "Apply filter." ) do |opt_arg|
        cmdln_option_H[ :filter ] = true
    end
    option.on( "--add_filter_items X", "Additional filter items in a comma delimited string" ) do |opt_arg|        
        cmdln_option_H[ :additional_filter_items_A ] = opt_arg.split( ',' ).map(&:strip)
        cmdln_option_H[ :filter ]                    = true
    end
    option.on( "--print-display_string-only", "Only print the display_string." ) do |opt_arg|
        cmdln_option_H[ :print_display_string_only ] = true
    end
    option.on( "--flattened", "--flatten", "Flatten the record and ap(awesome-print) it." ) do |opt_arg|
        cmdln_option_H[ :flattened ] = true
        cmdln_option_H[ :display ] = 'ap'
    end
    option.on( "--display X", "X = 'string|json|ap(awesome-print)]', output the AO's as 'X'" ) do |opt_arg|
        if ( opt_arg.not_in?( [ 'string', 'json', 'ap' ] ) )
            SE.puts "Was expecting [ 'string', 'json', 'ap' ] for the --display option value"
            raise
        end
        cmdln_option_H[ :display ] = opt_arg
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#SE.q { 'cmdln_option_H' }

if ( cmdln_option_H[ :rep_num ] )
    rep_num = cmdln_option_H[ :rep_num ]
else
    SE.puts "The --rep-num option is required."
    raise
end
if ( cmdln_option_H[ :res_num ] )
    res_num = cmdln_option_H[ :res_num ]
else
    SE.puts "The --res-num option is required."
    raise
end
SE.q {'cmdln_option_H'}

local_comparison_filter_A = cmdln_option_H[ :additional_filter_items_A ] | K.comparison_filter_A

print_LP = lambda{ | record_H, cnt | 
    case true
    when cmdln_option_H[ :print_display_string_only ] 
        puts "#{record_H[ K.display_string ]}"
    when cmdln_option_H[ :display ].not_nil?        
        record_H.deep_yield! do | y_O |
                y_O.gsub!( '&amp;', '&' ) if y_O.is_a?( String )
                next y_O if not ( cmdln_option_H[ :filter ] ) 
                next y_O if not y_O.is_a?( Hash )     ####  NOTICE >>> next y_O   
                y_O.each_key do | key |
                    y_O[ key ] = FILTERED if ( local_comparison_filter_A.include?( key ) ) 
                end
                next y_O
            end
        if ( cmdln_option_H[ :flattened ] )
            record_H = record_H.to_CKA_h
        end
        case cmdln_option_H[ :display ]
        when 'string'
            print  [ record_H ].join(" ").gsub( '&amp;', '&' )            
        when 'json'
            print record_H.to_json.gsub( '&amp;', '&' )
        when 'ap'
            header_trailer_string = "#{record_H[ K.type ]} #{record_H[ K.indicator ]} <<<<<<<<<<<<<<<<<<<<<<<<<<<<<"   
            puts header_trailer_string
            record_H.delete( K.type )
            record_H.delete( K.indicator )
            puts record_H.ai
            puts 'END:' + header_trailer_string
        else
            SE.puts "Programmer malfunction"
            raise
        end
        print "\n"
    else
        print "#{cnt} "
        print "#{record_H[ K.display_string ]} "
        print "\n"
    end
}

aspace_O = ASpace.new
rep_O = Repository.new( aspace_O, rep_num )
res_O = Resource.new( rep_O, res_num )
ao_QO = AO_Query__of_Resource.new( res_O: res_O, get_full_ao_record_TF: true )
tc_QO = TC_Query__of_Resource.new( ao_QO )

unsorted_tc_record_H_A = tc_QO.record_H_A
sorted_tc_record_H_A = unsorted_tc_record_H_A.each_with_index.sort do 
    | ( hash_a,                                                 index_a ),    ( hash_b,                                                 index_b ) |
    [   hash_a[ K.type ], hash_a[ K.indicator ].rjust(30, '0'), index_a ] <=> [ hash_b[ K.type ], hash_b[ K.indicator ].rjust(30, '0'), index_b ]
end.map( &:first )

ao_data_cnt = 0
sorted_tc_record_H_A.each_with_index do | tc_record_H, tc_record_H_A_idx |
    
    ao_data_H_A = tc_QO.ao_data_H_A__OF_tc_uri( tc_record_H[ K.uri ] )
    SE.raise if ( ao_data_H_A.nil? )
    ao_data_cnt += ao_data_H_A.length
    tc_record_H[ :AO_DATA_H_A ] = ao_data_H_A if ( cmdln_option_H[ :print_ao_data_TF ] )
            
    print_LP.call( tc_record_H, tc_record_H_A_idx + 1 )
end
SE.puts "#{tc_QO.record_H_A.length} TC records."
SE.puts "#{ao_QO.record_H_A.length} AO records."
SE.puts "#{ao_data_cnt} ao_data_H_A total."



