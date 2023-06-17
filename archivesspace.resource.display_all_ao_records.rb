=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                AS = ArchivesSpace
                IT = instance type
                TC = top container
                SC = Sub-container
                _H = Hash
                _A = Array
                _I = Index(of Array)
                _O = Object
               _0R = Zero Relative


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
    option.on( "--print-title-only", "Don't print the URI value." ) do |opt_arg|
        cmdln_option[ :print_title_only ] = true
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

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )
#SE.pom(aspace_O)
#SE.pov(aspace_O)
rep_O = Repository.new( aspace_O, rep_num )
#SE.pom(rep_O)
#SE.pov(rep_O)

res_O = Resource.new( rep_O, res_num )
cnt = 0; Resource_Query.new( res_O, cmdln_option[ :get_full_buffer ] ).get_all_AO.buf_A.each do | ao_buf_O |
    cnt += 1
    if ( cmdln_option[ :print_title_only ] ) then
        puts "#{ao_buf_O.record_H[ K.title ]}"
    else
        print "#{cnt} "
        print "#{ao_buf_O.record_H[ K.uri ]} " if ( cmdln_option[ :print_uri ] )
        print "#{ao_buf_O.record_H[ K.position ]} "
        print "#{ao_buf_O.record_H[ K.level ]} "
        print "#{ao_buf_O.record_H[ K.publish ]} " if ( cmdln_option[ :get_full_buffer ] )
        print "#{ao_buf_O.record_H[ K.title ]} "
        print "\n"
    end
end
SE.puts "#{cnt} records."




