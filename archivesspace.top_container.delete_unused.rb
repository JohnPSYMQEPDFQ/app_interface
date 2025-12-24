=begin

=begin

Variable Abbreviations:
        AO = Archival Object ( Resources are an AO too, but they have their own structure. )
        AS = ArchivesSpace
        IT = Instance Type
        TC = Top Container
        SC = Sub-Container
        _H = Hash
        _J = Json string
        _RES = Regular Expression String, e.g: find_bozo_RES = '\s+bozo\s+'
        _RE  = Regular Expression, e.g.: find_bozo_RE = /#{find_bozo_RES}/
        _A = Array
        _O = Object
        _Q = Query
        _C = Class of Struct
        _S = Structure of _C 
        __ = reads as: 'in a(n)', e.g.: record_H__A = 'record' Hash "in an" Array.

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
record_H_A = rep_O.query( TOP_CONTAINERS ).record_H_A__all.result_A
elapsed_seconds = Time.now - time_begin
SE.puts "Elapsed seconds = #{elapsed_seconds}"

SE.puts "Total TC's = #{record_H_A.length}"

record_H_A.each do | record_H |
    if ( not ( record_H.key?( K.collection ) && record_H[ K.collection ].count > 0 )) then
        print "Delete top_container: #{record_H[ K.uri ]}, "
        puts Top_Container.new( rep_O, record_H[ K.uri ] ).new_buffer.delete 
    end
end

