=begin

Abbreviations,  AO = archival object(Everything's an AO, but there's also uri "archive_objects". It's confusing...)
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


require 'net/http'
require 'uri'
require 'json'

class Http_Calls

    def initialize( p1_aspace_O )
        if ( p1_aspace_O.is_not_a?( ASpace ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a ASpace class object, it's a '${p1_aspace_O.class}'"
            raise
        end    
        @aspace_O = p1_aspace_O
    end
    attr_reader :aspace_O
    
    def get( p1_uri, p2_params = { } )
    #   SE.pov( uri ) 
            
        uri = URI.parse( "#{@aspace_O.api_uri_base}#{p1_uri}" )
        uri.query = URI.encode_www_form( p2_params )
        http = Net::HTTP.new(uri.host, uri.port)
    #   http.set_debug_output( $Stderr )
    #   SE.pov( http )
            
        headers = { "Content-type" => "application/json", "X-ArchivesSpace-Session" => @aspace_O.session }
        response_O = http.request( Net::HTTP::Get.new( uri.request_uri, headers ))
    #   SE.pov( response )
    #   SE.pom( response )
    #   SE.pp response.to_H   # This defaults to printing the headers
    #   response.each_header do |key, value|
    #       SE.puts "#{key} => #{value}"
    #   end
        if ( response_O.code != "200" ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.q { [ 'p1_uri', 'p2_params' ] }
            SE.q { [ 'response_O.code' ] }
            SE.q { [ 'response_O.body' ] }
            raise
        end
        response_body = JSON.parse( response_O.body )
        return response_body
    end           
    
    def post_with_params( p1_uri, p2_params = { } )  
        uri = URI.parse("#{@aspace_O.api_uri_base}/#{p1_uri}")
        uri.query = URI.encode_www_form( p2_params )  # Params are after the ? in the URL
        http = Net::HTTP.new( uri.host, uri.port )
    #   http.set_debug_output( $Stderr )    
        if ( @aspace_O.session == nil ) then
            headers = { "Content-type" => "application/json" }
        else
            headers = { "Content-type" => "application/json" , 'X-ArchivesSpace-Session' => @aspace_O.session}
        end
        response_O = http.request( Net::HTTP::Post.new( uri.request_uri, headers ))    
        if ( response_O.code != "200" ) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.q { [ 'p1_uri', 'p2_params' ] }
            SE.q { [ 'response_O.code' ] }
            SE.q { [ 'response_O.body' ] }
            raise
        end
        response_body = JSON.parse( response_O.body )
        return response_body
    end

    def post_with_body( p1_uri, p2_input_H )     
        uri = URI.parse("#{@aspace_O.api_uri_base}#{p1_uri}")       
        http = Net::HTTP.new( uri.host, uri.port )
    #   http.set_debug_output( $Stderr )      
        headers = { "Content-type" => "application/json" , 'X-ArchivesSpace-Session' => @aspace_O.session}
        input_O = Net::HTTP::Post.new( uri.request_uri, headers )
        input_O.body = p2_input_H.to_json
        response_O = http.request( input_O )
        if ( response_O.code != "200" ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.q { [ 'p1_uri' ] }
            SE.q { [ 'p2_input_H' ] }
            SE.q { [ 'response_O.code' ] }
            SE.q { [ 'response_O.body' ] }
            raise
        end
        response_body = JSON.parse( response_O.body )
    #   SE.pp "response_body", response_body
        return response_body;
    end 
    
    def delete( p1_uri, p2_params = { } )  
        uri = URI.parse("#{@aspace_O.api_uri_base}/#{p1_uri}")
        uri.query = URI.encode_www_form( p2_params )  # Params are after the ? in the URL
        http = Net::HTTP.new( uri.host, uri.port )
    #   http.set_debug_output( $Stderr )    
        headers = { "Content-type" => "application/json" , 'X-ArchivesSpace-Session' => @aspace_O.session}  
        response_O = http.request( Net::HTTP::Delete.new( uri.request_uri, headers ))
        if ( response_O.code != "200" ) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.q { [ 'p1_uri', 'p2_params' ] }
            SE.q { [ 'response_O.code' ] }
            SE.q { [ 'response_O.body' ] }
            raise
        end
        response_body = JSON.parse( response_O.body )
        return response_body
    end
end




