
class Location 
=begin
      Location just holds the location-number and uri.   
      An object of this is needed to create a Location_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          location_buffer_O = location.new(aspace_O, location-num|uri).new_buffer[.read|create]
=end
    attr_reader :aspace_O, :owner_repo, :uri_num,  :uri_addr
    
    def initialize( p1_O, p2_location_identifier = nil )
    
        case true        
        when p1_O.is_a?( ASpace )
            @aspace_O = p1_O
            @owner_repo = nil
        when p1_O.is_a?( Repository ) 
            @aspace_O = p1_O.aspace_O
            @owner_repo = p1_O.uri_addr
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a ASpace or Repository, it's: '#{p1_O.class}'"
            raise
        end    

        case true
        when p2_location_identifier.nil?
            @uri_num = nil
            @uri_addr = nil
        when p2_location_identifier.integer? 
            @uri_num = p2_location_identifier
            @uri_addr = "/#{LOCATIONS}/#{@uri_num}"
        when p2_location_identifier.start_with?( "/#{LOCATIONS}" ) 
            @uri_addr = p2_location_identifier
            @uri_num = p2_location_identifier.trailing_digits
            if (! @uri_num.integer? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Invalid param2: #{p2_location_identifier}"
                raise
            end
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Invalid param2: #{p2_location_identifier}, was expecting a location number."
            raise
        end
    end
    
    def new_buffer
        location_buf_O = Location_Record_Buf.new( self )
        return location_buf_O
    end
end

class Location_Record_Buf < Record_Buf
=begin
      A "CRUD-like" class for the /locations. 
      Note that: The 'create' just initializes the buffer, and the Update is called 'store' (so it's IRSD)
=end
    def initialize( location_O )
        if ( not location_O.is_a?( Location )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Location object, it's a '#{location_O.class}'"
            raise
        end    
        @rec_jsonmodel_type = K.location
        @uri_addr = location_O.uri_addr
        @uri_num = location_O.uri_num
        super( location_O.aspace_O )
    end
    attr_reader :location_O, :uri_num, :uri_addr
    
    def owner_repo_validate
        return if ( @owner_repo.nil? )
        return if ( @record_H.has_key?( K.owner_repo ) && @record_H[ K.owner_repo ] == @owner_repo )
        SE.puts "#{SE.lineno}: =============================================="
        SE.puts "Invalid 'owner_repo'"
        SE.q {'@owner_repo'}
        SE.q {'@record_H'}
        raise
    end
    
    def create  
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )
        if ( @owner_repo ) then
            @record_H[ K.owner_repo ] = { K.ref => @owner_repo }
        end
        owner_repo_validate
        @cant_change_A << K.owner_repo 
        return self
    end
    
    def load( external_record_H, filter_record_B = true )
        @record_H = super
        owner_repo_validate
        @cant_change_A << K.owner_repo 
        return self
    end
    
    def read( filter_record_B = true )
        stringer = "/#{LOCATIONS}"
        if ( stringer != @uri_addr[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a location! uri=#{@uri_addr}"
            raise
        end
        @record_H = super( filter_record_B ) 
#       SE.q {[ '@record_H' ]}
        owner_repo_validate
        return self
    end

    def store( )
    #   SE.q {[ '@record_H' ]}
        owner_repo_validate
        
        if ( ! (  @record_H[ K.building ] and @record_H[ K.building ] != '' ) ) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.building] value";
            SE.puts "@uri_addr = #{@uri_addr}"
            SE.q {[ '@record_H' ]}
            raise
        end
        # if (!(  @record_H[ K.title ] and @record_H[ K.title ] != K.undefined )) then 
            # SE.puts "#{SE.lineno}: =============================================="
            # SE.puts "#{SE.lineno}: I was expecting a @record_H[K.title] value";
            # SE.puts "@uri_addr = #{@uri_addr}"
            # SE.q {[ '@record_H' ]}
            # raise
        # end
        if ( @uri_addr.nil? ) then
            @uri_addr = "/#{LOCATIONS}"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created Location, uri = #{http_response_body_H[ K.uri ]}"
        else
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated location, uri = #{http_response_body_H[ K.uri ]}"
        end
        @uri_addr = http_response_body_H[ K.uri ] 
        @uri_num = @uri_addr.trailing_digits
        return self
    end
        
    def delete()
        stringer = "/#{LOCATIONS}"
        if ( stringer != @uri_addr[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a locations uri=#{@uri_addr}"
            raise
        end
        read()
        owner_repo_validate     
        http_response_body_H = super
        return http_response_body_H
    end    
end



