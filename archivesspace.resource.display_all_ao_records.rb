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


BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option = { :rep_num => 2  ,
                 :res_num => nil  ,
                 :get_full_ao_record_TF => true ,
                 :filter => false ,
                 :print_uri => true ,              
                 :print_title_only => false ,
                 :print_res_rec => false,
                 :display => nil,
                }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do |opt_arg|
        cmdln_option[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )." ) do |opt_arg|
        cmdln_option[ :res_num ] = opt_arg
    end
    option.on( "--ao-index-only", "Get the AO index buffer only." ) do |opt_arg|
        cmdln_option[ :get_full_ao_record_TF ] = false
    end
    option.on( "--filter", "Apply filter." ) do |opt_arg|
        cmdln_option[ :filter ] = true
    end
    option.on( "--no-uri", "Don't print the URI value." ) do |opt_arg|
        cmdln_option[ :print_uri ] = false
    end
    option.on( "--print-title-only", "Only print the title." ) do |opt_arg|
        cmdln_option[ :print_title_only ] = true
    end
    option.on( "--print-res-rec", "Print the resource record too." ) do |opt_arg|
        cmdln_option[ :print_res_rec ] = true
    end
    option.on( "--display X", "X = 'string|json|ap(awesome-print)]', output the AO's as 'X'" ) do |opt_arg|
        if ( opt_arg.not_in?( [ 'string', 'json', 'ap' ] ) ) then
            SE.puts "Was expecting [ 'string', 'json', 'ap' ] for the --display option value"
            raise
        end
        cmdln_option[ :display ] = opt_arg
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#SE.q { 'cmdln_option' }

if ( cmdln_option[ :rep_num ] ) then
    rep_num = cmdln_option[ :rep_num ]
else
    SE.puts "The --rep-num option is required."
    raise
end
if ( cmdln_option[ :res_num ] ) then
    res_num = cmdln_option[ :res_num ]
else
    SE.puts "The --res-num option is required."
    raise
end

print__record_H = lambda{ | record_H, cnt | 
    case true
    when cmdln_option[ :print_title_only ] 
        puts "#{record_H[ K.title ]}"
    when cmdln_option[ :display ].not_nil?
        print "#{record_H[ K.title ].gsub( '&amp;', '&' )} "    # This 'print' is to get the title printed first.
        
        if ( cmdln_option[ :filter ] ) then
        
#           The --filter option is useful for comparison of two resources, so remove anything that might
#           legitimately be different.

            remove_A = [ K.created_by, K.last_modified_by, K.create_time, K.system_mtime, K.user_mtime,  # From read filter
                         K.ref, K.uri, K.lock_version, 
                         K.title,            # removed because it's printed first (above)
                         K.repository, K.resource,
                         K.ancestors, K.ead_id, K.id_0, K.parent, 
                         K.position, K.persistent_id, K.is_slug_auto, K.slugged_url, K.ref_id, 
                     # From the index_record:
                         K.parent_id, K.tree, K.waypoints, K.waypoint_size, 
                     # Maybe optional ones:
                         K.publish, K.has_unpublished_ancestor,
                       ]
            record_H.nested_except!( remove_A )
        end
        case cmdln_option[ :display ]
        when 'string'
            print  [ record_H ].join(" ").gsub( '&amp;', '&' )            
        when 'json'
            print record_H.to_json.gsub( '&amp;', '&' )
        when 'ap'
            print record_H.ai
        else
            SE.puts "Programmer malfuction"
            raise
        end
        print "\n"
    else
        print "#{cnt} "
        print "#{record_H[ K.uri ]} " if ( cmdln_option[ :print_uri ] )
        print "#{record_H[ K.position ]} "
        print "#{record_H[ K.level ]} "
        print "#{record_H[ K.publish ]} " if ( cmdln_option[ :get_full_ao_record_TF ] )
        print "#{record_H[ K.title ]} "
        print "\n"
    end
}

aspace_O = ASpace.new
rep_O = Repository.new( aspace_O, rep_num )
res_O = Resource.new( rep_O, res_num )
if ( cmdln_option[ :print_res_rec ] ) then
    print__record_H.call( res_O.new_buffer.read( cmdln_option[ :filter ] ).record_H, 0 )
end

cnt = 0
AO_Query_of_Resource.new( res_O, cmdln_option[ :get_full_ao_record_TF ] ).record_H_A.each do | record_H |
    cnt += 1
    print__record_H.call( record_H, cnt )
end
SE.puts "#{cnt} records."




