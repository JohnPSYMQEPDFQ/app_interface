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
rep_O = Repository.new( aspace_O, rep_num )

#   id_0 is called the unitid in the XML EAD file.
puts "res_num, title, id_0/unitid, ead_id"
rep_O.query( RESOURCES ).get_all__record_H_A.result_A.each do | record_H |
    puts "#{record_H[ K.uri ].trailing_digits}: #{record_H[ K.title ]} '#{record_H[ K.id_0 ]}' '#{record_H[ K.ead_id ]}'"
end



