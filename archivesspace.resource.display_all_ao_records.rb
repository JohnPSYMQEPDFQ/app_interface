=begin

    Display all the Archival-Objects of a Resource, with a few different 
    print options.

=end

require 'json'
require 'optparse'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.TopContainer.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option_H = { :rep_num => 2  ,
                   :res_num => nil  ,
                   :get_full_ao_record_TF => true ,
                   :additional_filter_items_A => [] ,
                   :print_tc_data_TF => false,
                   :filter => false ,
                   :print_uri => true ,              
                   :print_title_only => false ,
                   :print_res_rec => false,
                   :flattened => false,
                   :display => nil,
                  }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do |opt_arg|
        cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )." ) do |opt_arg|
        cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "--ao-index-only", "Get the AO index buffer only." ) do |opt_arg|
        cmdln_option_H[ :get_full_ao_record_TF ] = false
    end
    option.on( "--tc_data_too", "Print some TC data too." ) do |opt_arg|
        cmdln_option_H[ :print_tc_data_TF ]      = true
        cmdln_option_H[ :get_full_ao_record_TF ] = true
    end
    option.on( "--filter", "Apply filter." ) do |opt_arg|            # For comparing resources
        cmdln_option_H[ :filter ] = true
    end
    option.on( "--add_filter_items X", "Additional filter items in a comma delimited string" ) do |opt_arg|        
        cmdln_option_H[ :additional_filter_items_A ] = opt_arg.split( ',' ).map(&:strip)
        cmdln_option_H[ :filter ]                    = true
    end
    option.on( "--no-uri", "Don't print the URI value." ) do |opt_arg|
        cmdln_option_H[ :print_uri ] = false
    end
    option.on( "--pto", "--print-title-only", "Only print the title." ) do |opt_arg|
        cmdln_option_H[ :print_title_only ] = true
    end
    option.on( "--prr", "--print-res-rec", "Print the resource record too." ) do |opt_arg|
        cmdln_option_H[ :print_res_rec ] = true
    end
    option.on( "--flattened", "Flatten the record and ap(awesome-print) it." ) do |opt_arg|
        cmdln_option_H[ :flattened ] = true
        cmdln_option_H[ :display ] = 'ap'
    end
    option.on( "--display X", "X = 'string|json|ap(awesome-print)]', output the AO's as 'X'" ) do |opt_arg|
        if ( opt_arg.not_in?( [ 'string', 'json', 'ap' ] ) ) 
            SE.puts "Was expecting [ 'string', 'json', 'ap' ] for the --display option value, not '#{opt_arg}'."
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

print_LP = lambda{ | record_H, ao_cnt | 
    case true
    when cmdln_option_H[ :print_title_only ] 
        puts "#{record_H[ K.title ]}"
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
            header_trailer_string = "#{record_H[ K.title ].gsub( '&amp;', '&' )} <<<<<<<<<<<<<<<<<<<<"   # This 'print' is to get the title printed first.
            puts header_trailer_string
            record_H.delete( K.title )
            puts record_H.ai.gsub( '&amp;', '&' )
            puts 'END:' + header_trailer_string
        else
            SE.puts "Programmer malfunction"
            raise
        end
        print "\n"
    else
        print "#{ao_cnt} "
        print "#{record_H[ K.uri ]} " if ( cmdln_option_H[ :print_uri ] )
        print "#{record_H[ K.ancestors ].length} " if ( record_H[ K.ancestors ] )
        print "#{record_H[ K.position ]} "
        print "#{record_H[ K.level ]} "
        print "#{record_H[ K.publish ]} " if ( cmdln_option_H[ :get_full_ao_record_TF ] )
        print "#{record_H[ K.title ]} "
        print "\n"
    end
}

aspace_O = ASpace.new
rep_O = Repository.new( aspace_O, rep_num )
res_O = Resource.new( rep_O, res_num )
if ( cmdln_option_H[ :print_res_rec ] )
    print_LP.call( res_O.new_buffer.read( filter_record_TF: cmdln_option_H[ :filter ] ).record_H, 0 )
end
ao_cnt = 0
ao_QO = AO_Query__of_Resource.new( res_O: res_O, get_full_ao_record_TF: cmdln_option_H[ :get_full_ao_record_TF ] )
tc_QO = ( cmdln_option_H[ :print_tc_data_TF ] ) ? TC_Query__of_Resource.new( ao_QO ) : nil
ao_QO.record_H_A( index_ok_TF: true ).each do | ao_record_H |
    ao_cnt += 1
    if tc_QO
        ao_record_H.to_CKA_h.each_pair do | key_CKA, value |
            next if ( value.is_not_a?( String ) )
            next if ( key_CKA.length < 2 )
            next if ( key_CKA.last( 2 ) != [ K.top_container, K.ref ] )
            tc_record_H = tc_QO.record_H__OF_uri( value )
            SE.raise if ( tc_record_H.nil? )
            ao_record_H.value__using_CKA!( key_CKA[0 ... -1] ) do | y_O | 
                the_of_n_A = tc_QO.uri_addr_A__OF_type_indicator( type:      tc_record_H[ K.type ], 
                                                                  indicator: tc_record_H[ K.indicator ] 
                                                                  )
                one_of_n = the_of_n_A.find_index( tc_record_H[ K.uri ] ) + 1
                SE.raise if ( one_of_n.nil? )
                y_O[ :BOX_INFO_H ] = { K.type      => tc_record_H[ K.type ], 
                                       K.indicator => tc_record_H[ K.indicator ],
                                       :ONE_OF_N   => "#{one_of_n} of #{the_of_n_A.length}"
                                      }
                next y_O
            end
        end
    end
    print_LP.call( ao_record_H, ao_cnt )
end
SE.puts "#{ao_cnt} records."




