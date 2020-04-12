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
                 "filter" => false }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ] --resource-num n [res] [(ao|tc) n,n,...]..."
    option.on( "--filter", "apply-read-filter" ) do |opt_arg|
        cmdln_option[ 'filter' ] = true
    end
    option.on( "-h","--help" ) do
        Se.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV
record_filter_B = cmdln_option[ 'filter' ] 

if ( ARGV.length < 2 ) then
    Se.puts "I need to params"
    exit
end

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )

http_O = Http_Calls.new( aspace_O ) 
method = "http_#{ARGV[ 0 ]}"
if ( not http_O.respond_to?( method )) then
    Se.puts "#{Se.lineno}: unknown method: #{method}"        
    exit
end
a1 = ARGV[ 1 ].split( '?' ).map( &:to_s ).map( &:strip )  
uri = a1[ 0 ]
if ( a1.maxindex < 1 ) then
    params = {}
else
    params = [ a1[ 1 ].split( '=' ).map( &:to_s ).map( &:strip ) ].to_h
    params.each_pair { | k, v | params[k] = v.to_i if (v.integer?) }
end
p a1
p uri
p params
pp http_O.method( method ).call( uri, params ) 


