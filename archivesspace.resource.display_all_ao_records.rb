=begin

Display all the Archival-Objects of a Resource, with a few different 
print options.

=end

require 'json'
# require 'pp'
require 'optparse'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )
api_uri_base = "http://localhost:8089"

cmdln_option = { :rep_num => 2  ,
                 :res_num => nil  ,
                 :get_full_buffer => false ,
                 :print_uri => true ,
                 :print_title_only => false ,
                 :print_res_rec => false,
                 :flatten => false,
                }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do |opt_arg|
        cmdln_option[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )." ) do |opt_arg|
        cmdln_option[ :res_num ] = opt_arg
    end
    option.on( "--get-full-buffer", "Get the full AO buffer (SLOW!)." ) do |opt_arg|
        cmdln_option[ :get_full_buffer ] = true
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
    option.on( "--flatten", "'join' the entire record_H into one long string" ) do |opt_arg|
        cmdln_option[ :flatten ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV
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

print__record_H = lambda{ | record_H | 
    case true
    when cmdln_option[ :print_title_only ] 
        puts "#{record_H[ K.title ]}"
    when cmdln_option[ :flatten ] 
        print "#{record_H[ K.title ]} "
        
#           Flatten is useful for comparison of two resources, so remove anything that might
#           legitimately be different.

        record_H.delete( K.title )          # removed because it's printed above
        record_H.delete( K.ancestors )
        record_H.delete( K.ead_id )
        record_H.delete( K.id_0 )
        record_H.delete( K.lock_version )
        record_H.delete( K.parent )         # ao_record
        record_H.delete( K.parent_id )      # index_record  
        record_H.delete( K.persistent_id )
        record_H.delete( K.slugged_url )
        record_H.delete( K.ref_id )
        record_H.delete( K.repository )
        record_H.delete( K.resource )
        record_H.delete( K.tree )
        record_H.delete( K.uri )
        record_H.delete( K.waypoints )
        record_H.delete( K.waypoint_size )
        
        print  [ record_H ].join(" ")        
        print "\n"        
    else
        print "#{cnt} "
        print "#{record_H[ K.uri ]} " if ( cmdln_option[ :print_uri ] )
        print "#{record_H[ K.position ]} "
        print "#{record_H[ K.level ]} "
        print "#{record_H[ K.publish ]} " if ( cmdln_option[ :get_full_buffer ] )
        print "#{record_H[ K.title ]} "
        print "\n"
    end
}

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )
#SE.pom(aspace_O)
#SE.pov(aspace_O)
rep_O = Repository.new( aspace_O, rep_num )
#SE.pom(rep_O)
#SE.pov(rep_O)

cnt = 0
res_O = Resource.new( rep_O, res_num )
if ( cmdln_option[ :print_res_rec ] ) then
    print__record_H.call( res_O.new_buffer.read.record_H )
end
Resource_Query.new( res_O, cmdln_option[ :get_full_buffer ] ).record_H_A.each do | record_H |
    cnt += 1
    print__record_H.call( record_H )
end
SE.puts "#{cnt} records."




