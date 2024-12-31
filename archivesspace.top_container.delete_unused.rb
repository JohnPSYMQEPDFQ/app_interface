=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                AS = ArchivesSpace
                IT = instance type
                TC = top container
                SC = Sub-container
                _H = Hash
                _J = Json string
                _A = Array
                _O = Object
                _Q = Query
                _S = Structure
               _0R = Zero Relative


=end

require 'optparse'
require 'class.Archivesspace.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'

BEGIN {}
END {}

binding.pry if ( respond_to? :pry )
myself_name = File.basename( $0 )

cmdln_option = { :rep_num => 2  ,
                 :update => false ,
                 }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] FILE"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ :rep_num ] = opt_arg
    end
    option.on( "--update", "Do updates" ) do |opt_arg|
        cmdln_option[ :update ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV
if ( ! cmdln_option[ :rep_num ] ) then
    SE.puts "The --rep-num option is required."
    raise
end

aspace_O = ASpace.new
aspace_O.allow_updates=cmdln_option[ :update ] 

rep_O = Repository.new( aspace_O, cmdln_option[ :rep_num ] )

SE.puts "Finding Top_Containers (which takes some time) ..."
time_begin = Time.now
all_TC_S = TC_Query.new( rep_O ).get_all_TC_S
elapsed_seconds = Time.now - time_begin
SE.puts "Elapsed seconds = #{elapsed_seconds}"
# SE.q {[ 'all_TC_S.record_H_A' ]}
SE.puts "Total TC's = #{all_TC_S.record_H_A.length}, page_cnt = #{all_TC_S.page_cnt}"

all_TC_S.for_unused__record_H_A.each do | record_H |
    print "Delete top_container: #{record_H[ K.uri ]}, "
    puts Top_Container.new( rep_O, record_H[ K.uri ] ).new_buffer.delete 
end
