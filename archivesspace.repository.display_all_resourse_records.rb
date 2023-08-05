=begin

    Display all the resources of a repository.

=end

require 'json'
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'class.Hash.extend.rb'
require 'module.SE.rb'
require 'class.Archivesspace.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.Repository.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )
api_uri_base = "http://localhost:8089"

cmdln_option = { :rep_num => 2  ,
                }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ :rep_num ] = opt_arg
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

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )
#SE.pom(aspace_O)
#SE.pov(aspace_O)
rep_O = Repository.new( aspace_O, rep_num )
#SE.pom(rep_O)
#SE.pov(rep_O)

#   id_0 is called the unitid in the XML EAD file.
puts "res_num, title, id_0/unitid, ead_id"
Repository_Query.new( rep_O ).get_all_Resource.buf_A.each do | res_buf_O |
    puts "#{res_buf_O.res_O.num}: #{res_buf_O.record_H[ K.title ]} '#{res_buf_O.record_H[ K.id_0 ]}' '#{res_buf_O.record_H[ K.ead_id ]}'"
end



