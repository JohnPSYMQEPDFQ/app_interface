

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
    option.banner = "Usage: #{myself_name} [options]"
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
record_H_A = rep_O.query( TOP_CONTAINERS ).record_H_A__all.result_A
elapsed_seconds = Time.now - time_begin
SE.puts "Elapsed seconds = #{elapsed_seconds}"

SE.puts "#{record_H_A.length} Top Containers."

tc_to_delete__uri_A = []
tc_with_locations_but_no_collection__uri_A = []
record_H_A.each do | record_H |
    if ( record_H.key?( K.collection ) && record_H[ K.collection ].count > 0 ) then
        next
    end
    if ( record_H.key?( K.container_locations ) && record_H[ K.container_locations ].count > 0 ) then
        tc_with_locations_but_no_collection__uri_A.push( record_H[ K.uri ] )
        next
    end
    tc_to_delete__uri_A.push( record_H[ K.uri ] )        
end
SE.puts "#{tc_to_delete__uri_A.length} to be deleted."
delete_cnt = rep_O.batch_delete( tc_to_delete__uri_A ).deleted_cnt
if ( delete_cnt != tc_to_delete__uri_A.length ) then
    SE.puts "#{SE.lineno}: Expected number of TC's not deleted!"
    SE.puts "delete_cnt != tc_to_delete__uri_A.length"
    SE.q {[ 'delete_cnt', 'tc_to_delete__uri_A.length']}
    raise
end
SE.puts "#{delete_cnt} deleted."
#SE.q {'tc_with_locations_but_no_collection__uri_A'}




