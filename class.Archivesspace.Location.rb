=begin

Abbreviations,  AO = archival object(Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                AS = ArchivesSpace
                location = top container
                SC = Sub-container
                _H = Hash
                _A = Array
                _I = Index(of Array)
                _O = Object
               _0R = Zero Relative

=end

class Location 
=begin
      Location just holds the location-number and uri.   
      An object of this is needed to create a Location_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          location_buffer_O = location.new(aspace_O, location-num|uri).new_buffer[.read|create]
=end
    def initialize( p1_aspace_O, p2_location_identifier = nil )
        if ( p1_aspace_O.class != ASpace ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Param 1 is not a Resource or Resource_Record_Buf class object, it's: '#{p1_aspace_O.class}'"
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
                Se.puts "#{Se.lineno}: =============================================="
                Se.puts "Invalid param2: #{p2_location_identifier}, was expecting a location number."
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
        if ( location_O.class.name.downcase != K.location ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Param 1 is not an location object, it's: '#{location_O.class}'"
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
        stringer = "/locations"
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            Se.puts "#{Se.lineno}: =============================================="     
            Se.puts "uri isn't a location! uri=#{@uri}"
            raise
        end
        @record_H = super( filter_record_B ) 
#       Se.pp "#{Se.lineno}: @record_H:", @record_H
        return self
    end

    def store( )
    #   Se.pp "@record_H:", @record_H 
        if (!(  @record_H[K.building] and @record_H[K.building] != '')) then 
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "#{Se.lineno}: I was expecting a @record_H[K.building] value";
            Se.puts "@uri = #{@uri}"
            Se.pp "@record_H:", @record_H
            raise
        end
        if (!(  @record_H[K.classification] and @record_H[K.classification] != K.undefined )) then 
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "#{Se.lineno}: I was expecting a @record_H[K.classification] value";
            Se.puts "@uri = #{@uri}"
            Se.pp "@record_H:", @record_H
            raise
        end
        if ( @uri == nil ) then
            @uri = "/locations"
            http_response_body_H = super
            Se.puts "#{Se.lineno}: Created TopContainer, uri = #{http_response_body_H[ K.uri ]}"
        else
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "#{Se.lineno}: I shouldn't be updating a TopContainer"
            raise
            http_response_body_H = super
            Se.puts "#{Se.lineno}: Updated location, uri = #{http_response_body_H[ K.uri ]}"
        end
        @uri = http_response_body_H[ K.uri ] 
        @num = @uri.sub( /^.*\//, '' )
        return self
    end
        
    def delete( )
        stringer = "/locations"
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            Se.puts "#{Se.lineno}: =============================================="     
            Se.puts "uri isn't a location! uri=#{@uri}"
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
        @uri = "/locations"    
        @result = nil
    end
    attr_reader :aspace_O, :result, :uri

    def get_A_of_location_nums( p1_params )
        http_response_body = @aspace_O.http_calls_O.get( @uri, p1_params )
        @result = http_response_body
        return self
    end
end


