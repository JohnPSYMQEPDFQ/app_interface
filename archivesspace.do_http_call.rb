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
require 'module.SE.rb'
require 'class.Archivesspace.rb'
require 'class.ArchivesSpace.http_calls.rb'


BEGIN {}
END {}

binding.pry if ( respond_to? :pry )
myself_name = File.basename( $0 )
api_uri_base = "http://localhost:8089"

cmdln_option = { "repository-num" => 2  ,
               }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ] Http_Calls.method (e.g get) uri[?params]"
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
if ( cmdln_option[ 'repository-num' ] ) then
    repository_num = cmdln_option[ 'repository-num' ]
end

if ( ARGV.length < 2 ) then
    SE.puts "I need two params: http method (eg 'get') and the uri"
    exit
end

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )

http_O = Http_Calls.new( aspace_O ) 
method = ARGV[ 0 ] + ""
if ( not http_O.respond_to?( method )) then
    SE.puts "#{SE.lineno}: unknown method: #{method}"        
    exit
end
stringer = ARGV[ 1 ] + ""
stringer.delete_prefix!( api_uri_base )
a1 = stringer.split( '?' ).map( &:to_s ).map( &:strip )  
uri = a1[ 0 ]
if ( a1.maxindex < 1 ) then
    params = {}
else
    params = a1[ 1 ].split( '&' ).map { | e | e.split( '=' ).map( &:to_s ).map( &:strip ) }.to_h
    params.each_pair { | k, v | params[k] = v.to_i if (v.integer?) }
end

uri.sub!( ':repo_id', repository_num.to_s )
#p a1
puts "uri=#{uri}, params=#{params}"
stringer = http_O.method( method ).call( uri, params ) 
puts stringer.ai


