
class Location 
=begin
      Location just holds the location-number and uri.   
      An object of this is needed to create a Location_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          location_buffer_O = location.new(aspace_O, location-num|uri).new_buffer[.read|create]
=end
public  attr_reader :aspace_O, :owner_repo, :rec_id, :uri_addr
private attr_writer :aspace_O, :owner_repo, :rec_id, :uri_addr
    
    def initialize( p1_O, p2_location_identifier = nil )
    
        case true        
        when p1_O.is_a?( ASpace )
            self.aspace_O   = p1_O
            self.owner_repo = nil
        when p1_O.is_a?( Repository ) 
            self.aspace_O   = p1_O.aspace_O
            self.owner_repo = nil         #    p1_O.uri_addr      <<  Not sure when owner_repo is set?
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a ASpace or Repository, it's: '#{p1_O.class}'"
            raise
        end    

        case true
        when p2_location_identifier.nil?
            self.rec_id   = nil
            self.uri_addr = nil
        when p2_location_identifier.integer? 
            self.rec_id   = p2_location_identifier
            self.uri_addr = "/#{LOCATIONS}/#{self.rec_id}"
        when p2_location_identifier.start_with?( "/#{LOCATIONS}" ) 
            self.uri_addr = p2_location_identifier
            self.rec_id   = p2_location_identifier.trailing_digits
            if (! self.rec_id.integer? ) then
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

public  attr_reader :loc_O, :rec_id, :uri_addr, :rec_jsonmodel_type
private attr_writer :loc_O, :rec_id, :uri_addr, :rec_jsonmodel_type
    
    def initialize( loc_O )
        if ( not loc_O.is_a?( Location )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Location object, it's a '#{loc_O.class}'"
            raise
        end    
        self.rec_jsonmodel_type = K.location
        self.loc_O              = loc_O
        self.uri_addr           = loc_O.uri_addr
        self.rec_id             = loc_O.rec_id
        super( self.loc_O.aspace_O )
    end
    
    def owner_repo_validate
        return if ( loc_O.owner_repo.nil? )
        return if ( @record_H.has_key?( K.owner_repo ) && @record_H[ K.owner_repo ].fetch( K.ref ) == loc_O.owner_repo )
        SE.puts "#{SE.lineno}: =============================================="
        SE.puts "Invalid 'owner_repo'"
        SE.q {'loc_O.owner_repo'}
        SE.q {'@record_H'}
        raise
    end
    
    def create  
        @record_H.merge!( Record_Format.new( self.rec_jsonmodel_type ).record_H )
        if ( loc_O.owner_repo ) then
            @record_H[ K.owner_repo ] = { K.ref => loc_O.owner_repo }
        end
        owner_repo_validate
        self.cant_change_A << K.owner_repo 
        return self
    end
    
    def load( external_record_H, filter_record_B = true )
        @record_H = super
        owner_repo_validate
        self.cant_change_A << K.owner_repo 
        return self
    end
    
    def read( filter_record_B = true )
        stringer = "/#{LOCATIONS}"
        if ( stringer != self.uri_addr[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a location! uri=#{self.uri_addr}"
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
        
        if ( ! (  @record_H[ K.building ] && @record_H[ K.building ] != '' ) ) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.building] value";
            SE.puts "self.uri_addr = #{self.uri_addr}"
            SE.q {[ '@record_H' ]}
            raise
        end
        # if (!(  @record_H[ K.title ] && @record_H[ K.title ] != K.undefined )) then 
            # SE.puts "#{SE.lineno}: =============================================="
            # SE.puts "#{SE.lineno}: I was expecting a @record_H[K.title] value";
            # SE.puts "self.uri_addr = #{self.uri_addr}"
            # SE.q {[ '@record_H' ]}
            # raise
        # end
        if ( self.uri_addr.nil? ) then
            self.uri_addr = "/#{LOCATIONS}"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created Location, uri = #{http_response_body_H[ K.uri ]}"
            self.uri_addr = http_response_body_H[ K.uri ] 
            self.rec_id = self.uri_addr.trailing_digits
        else
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated location, uri = #{http_response_body_H[ K.uri ]}"
        end
        return self
    end
        
    def delete()
        stringer = "/#{LOCATIONS}"
        if ( stringer != self.uri_addr[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a locations uri=#{self.uri_addr}"
            raise
        end
        read()
        owner_repo_validate     
        http_response_body_H = super
        SE.puts "#{SE.lineno}: Deleted location, uri = #{http_response_body_H[ K.uri ]}"
        return http_response_body_H
    end    
end



