=begin

    Does a single http call to the AS backend and returns the results.
    
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
    rep_num = cmdln_option[ 'repository-num' ]
end

if ( ARGV.length < 2 ) then
    SE.puts "I need two params: http method (eg 'get') and the uri"
    exit
end

aspace_O = ASpace.new
http_O = Http_Calls.new( aspace_O ) 
method = ARGV[ 0 ] + ""
if ( not http_O.respond_to?( method )) then
    SE.puts "#{SE.lineno}: unknown method: #{method}"        
    exit
end
stringer = ARGV[ 1 ] + ""
stringer.delete_prefix!( aspace_O.api_uri_base )
arr1 = stringer.split( '?' ).map( &:to_s ).map( &:strip )  
uri = arr1[ 0 ]
if ( arr1.maxindex < 1 ) then
    param_H = {}
else
    param_H = {}.compare_by_identity    
#   '{}.compare_by_identity' uses the object_id as the key instead of the actual value.  This 
#   is needed when there are duplicate parameter names being passed.  For example:
#       get '/repositories/2/find_by_id/archival_objects?resolve[]=archival_objects&ref_id[]=aspace_5fac98a4fbd20ccfc43b68a6b660d288&ref_id[]=aspace_e1dc17a72326fee0b8fb6fdaad7efa85'
#   There can be many 'ref_id[]=value' strings.            
       
    arr1[ 1 ].split( '&' ) do | e | 
        k, v = e.split( '=' ).map( &:to_s ).map( &:strip )
        if ( v.is_not_a?( String ) ) then
            SE.q { 'v' }
            raise "'v' is not a string"
        end
        param_H[ k ] = ( v.integer? ) ? v.to_i : v       
    end
end

uri.sub!( ':repo_id', rep_num.to_s )
puts "uri=#{uri}, param_H=#{param_H}"
stringer = http_O.method( method ).call( uri, param_H ) 
puts stringer.ai


