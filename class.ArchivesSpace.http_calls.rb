
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
        uri = URI.parse( "#{self.aspace_O.api_uri_base}#{p1_uri}" )
        uri.query = URI.encode_www_form( p2_params )
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = ( self.aspace_O.api_uri_base[ 0, 6 ] == 'https:' ) 
    #   http.set_debug_output( $stderr )         
        headers = { "Content-type" => "application/json", "X-ArchivesSpace-Session" => self.aspace_O.session }
        response_O = http.request( Net::HTTP::Get.new( uri.request_uri, headers ))
        response_body = JSON.parse( response_O.body )
        if ( response_O.code != "200" ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.q { [ 'p1_uri', 'p2_params' ] }
            SE.q { [ 'response_O.code' ] }
            SE.q { [ 'response_body' ] }
            raise
        end
        return response_body
    end           
    
    def post_with_params( p1_uri, p2_params = { } )  
        uri = URI.parse( "#{self.aspace_O.api_uri_base}#{p1_uri}" )
        uri.query = URI.encode_www_form( p2_params )  # Params are after the ? in the URL
        http = Net::HTTP.new( uri.host, uri.port )
        http.use_ssl = ( self.aspace_O.api_uri_base[ 0, 6 ] == 'https:' ) 
    #   http.set_debug_output( $stderr )    
        if ( self.aspace_O.session == nil ) then
            headers = { "Content-type" => "application/json" }
        else
            headers = { "Content-type" => "application/json" , 'X-ArchivesSpace-Session' => self.aspace_O.session}
        end
        if ( @aspace_O.allow_updates || p1_uri.end_with?( '/login' ) ) then   # the login uses this method.
            response_O = http.request( Net::HTTP::Post.new( uri.request_uri, headers ))  
            response_body = JSON.parse( response_O.body )            
            if ( response_O.code != "200" ) then 
                SE.puts "#{SE.lineno}: =============================================="
                SE.q { [ 'p1_uri', 'p2_params' ] }
                SE.q { [ 'http' ] }
                SE.q { [ 'response_O.code' ] }
                SE.q { [ 'response_body' ] }
                raise
            end
        else
            response_body = {K.uri => "NO UPDATE MODE"}
        end
        return response_body
    end

    def post_with_body( p1_uri, p2_input_H )     
        uri = URI.parse( "#{self.aspace_O.api_uri_base}#{p1_uri}" )       
        http = Net::HTTP.new( uri.host, uri.port )
        http.use_ssl = ( self.aspace_O.api_uri_base[ 0, 6 ] == 'https:' ) 
    #   http.set_debug_output( $stderr )      
        headers = { "Content-type" => "application/json" , 'X-ArchivesSpace-Session' => self.aspace_O.session}
        input_O = Net::HTTP::Post.new( uri.request_uri, headers )
        input_O.body = p2_input_H.to_json
        if ( @aspace_O.allow_updates ) then
            response_O = http.request( input_O )  
            response_body = JSON.parse( response_O.body ) 
            if ( response_O.code != "200" ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.q { [ 'p1_uri' ] }
                SE.q { [ 'p2_input_H' ] }
                SE.q { [ 'response_O.code' ] }
                SE.q { [ 'response_body' ] }
                raise
            end       
        else
            response_body = {K.uri => "NO UPDATE MODE"}
        end
    #   SE.q {'response_body'}
        return response_body;
    end 
    
    def delete( p1_uri, p2_params = { } )  
        uri = URI.parse( "#{self.aspace_O.api_uri_base}#{p1_uri}" )
        uri.query = URI.encode_www_form( p2_params )  # Params are after the ? in the URL
        http = Net::HTTP.new( uri.host, uri.port )
        http.use_ssl = ( self.aspace_O.api_uri_base[ 0, 6 ] == 'https:' ) 
    #   http.set_debug_output( $stderr )   
        if ( @aspace_O.allow_updates ) then    
            headers = { "Content-type" => "application/json" , 'X-ArchivesSpace-Session' => self.aspace_O.session}  
            response_O = http.request( Net::HTTP::Delete.new( uri.request_uri, headers ))
            response_body = JSON.parse( response_O.body )
            if ( response_O.code != "200" ) then 
                SE.puts "#{SE.lineno}: =============================================="
                SE.q { [ 'p1_uri', 'p2_params' ] }
                SE.q { [ 'response_O.code' ] }
                SE.q { [ 'response_body' ] }
                raise
            end            
        else
            response_body = {K.uri => "NO UPDATE MODE"}
        end
        return response_body
    end
end




