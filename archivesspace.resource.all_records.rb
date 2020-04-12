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
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'class.Hash.extend.rb'
require 'module.Se.rb'
require 'class.Archivesspace.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )
api_uri_base = "http://localhost:8089"

cmdln_option = { "repository-num" => 2  ,
                 "resource-num" => nil  ,
                 "ao-ref" => nil  ,
                 "update" => false ,
                 'last_record_num' => nil}
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ] FILE"
    option.on( "--repository-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ 'repository-num' ] = opt_arg
    end
    option.on( "--resource-num n", OptionParser::DecimalInteger, "Resource number ( required )" ) do |opt_arg|
        cmdln_option[ 'resource-num' ] = opt_arg
    end
    option.on( "--ao-ref x", "Archival Object ReferenceID ( optional, but must be member of suppled Resource number )" ) do |opt_arg|
        cmdln_option[ 'ao-ref' ] = opt_arg
    end
    option.on( "--update", "Do updates" ) do |opt_arg|
        cmdln_option[ 'update' ] = true
    end
    option.on( "--last-record-num n", OptionParser::DecimalInteger, "Stop after record N" ) do |opt_arg|
        cmdln_option[ 'last-record-num' ] = opt_arg
    end
    option.on( "-h","--help" ) do
        Se.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV
if ( cmdln_option[ 'repository-num' ] ) then
    repository_num = cmdln_option[ 'repository-num' ]
else
    Se.puts "The --repository-num option is required."
    raise
end
if ( cmdln_option[ 'resource-num' ] ) then
    resource_num = cmdln_option[ 'resource-num' ]
else
    Se.puts "The --resource-num option is required."
    raise
end
if ( cmdln_option[ 'ao-ref' ] ) then
    cmdln_AO_ref = cmdln_option[ 'ao-ref' ]      
else
    cmdln_AO_ref = nil
end
if ( cmdln_option[ 'last-record-num' ] ) then
    last_record_num = cmdln_option[ 'last-record-num' ]      
else
    last_record_num = nil
end
$global_update=cmdln_option[ 'update' ] 

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )
#Se.pom(aspace_O)
#Se.pov(aspace_O)
rep_O = Repository.new( aspace_O, repository_num )
#Se.pom(rep_O)
#Se.pov(rep_O)

res_O = Resource.new( rep_O, resource_num )
res_tree_query_O = Resource_Tree_Query.new( res_O )
cnt = 0
res_tree_query_O.result.each do | element |
    cnt += 1
    ao_record_H = AO_Record_Buf.new( element ).read.record_H
    puts "#{cnt} #{ao_record_H[ K.uri ]} #{ao_record_H[ K.position ]} #{ao_record_H[ K.title ]}"
end



