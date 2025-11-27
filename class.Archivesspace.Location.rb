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

class Location 
=begin
      Location just holds the location-number and uri.   
      An object of this is needed to create a Location_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          location_buffer_O = location.new(aspace_O, location-num|uri).new_buffer[.read|create]
=end
    def initialize( p1_aspace_O, p2_location_identifier = nil )
        if ( not p1_aspace_O.is_a?( ASpace ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a ASpace class object, it's a '#{p1_aspace_O.class}'"
            raise
        end    
        @aspace_O = p1_aspace_O
        if ( p2_location_identifier == nil ) then
            @num = nil
            @uri = nil
        else
            if ( p2_location_identifier.integer? ) then
                @num = p2_location_identifier
                @uri = "/locations/#{@num}"
            else
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Invalid param2: #{p2_location_identifier}, was expecting a location number."
                raise
            end
        end
    end
    attr_reader :aspace_O, :num, :uri
    
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
        @location_O = location_O
        @uri = @location_O.uri
        @num = @location_O.num
        super( @location_O.aspace_O )
    end
    attr_reader :location_O, :num, :uri
    
    def create  
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )
        return self
    end
    
    def read( filter_record_B = true )
        stringer = '/locations'
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a location! uri=#{@uri}"
            raise
        end
        @record_H = super( filter_record_B ) 
#       SE.q {[ '@record_H' ]}
        return self
    end

    def store( )
    #   SE.q {[ '@record_H' ]}
        if (!(  @record_H[K.building] and @record_H[K.building] != '')) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.building] value";
            SE.puts "@uri = #{@uri}"
            SE.q {[ '@record_H' ]}
            raise
        end
        if (!(  @record_H[K.classification] and @record_H[K.classification] != K.undefined )) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.classification] value";
            SE.puts "@uri = #{@uri}"
            SE.q {[ '@record_H' ]}
            raise
        end
        if ( @uri == nil ) then
            @uri = '/locations'
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created TopContainer, uri = #{http_response_body_H[ K.uri ]}"
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I shouldn't be updating a TopContainer"
            raise
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated location, uri = #{http_response_body_H[ K.uri ]}"
        end
        @uri = http_response_body_H[ K.uri ] 
        @num = @uri.trailing_digits
        return self
    end
        
    def delete( )
        stringer = '/locations'
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a locations uri=#{@uri}"
            raise
        end
        read()
        
        http_response_body_H = super
        return http_response_body_H
    end    
end


class Location_Query
    def initialize( p1_aspace_O )
        @aspace_O = p1_aspace_O
        @uri = '/locations'    
        @result = nil
    end
    attr_reader :aspace_O, :result, :uri

    def get_A_of_location_nums( p1_params )
        http_response_body = @aspace_O.http_calls_O.get( @uri, p1_params )
        @result = http_response_body
        return self
    end
end


