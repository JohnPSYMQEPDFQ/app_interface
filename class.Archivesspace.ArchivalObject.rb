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

class Archival_Object
=begin
      Archival_Object just holds the AO-number and uri.   
      An object of this is needed to create a AO_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          ao_buffer_Obj = Archival_Object.new(resource_Obj, ao-num|uri).new_buffer[.read|create]
=end
    def initialize( p1_O, p2_AO_identifier = nil )
        if ( p1_O.is_a?( Resource_Record_Buf ) ) then
            @res_O = p1_O.res_O
        else
            if ( not p1_O.is_a?( Resource ) ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Param 1 is not a Resource or Resource_Record_Buf class object, it's: '#{p1_O.class}'"
                raise
            end    
            @res_O = p1_O
        end
        if ( p2_AO_identifier == nil ) then
            @num = nil
            @uri = nil
        else
            if ( p2_AO_identifier.integer? ) then
                @num = p2_AO_identifier
                @uri = "#{@res_O.rep_O.uri}/archival_objects/#{@num}"
            else
                stringer = "#{@res_O.rep_O.uri}/archival_objects"
                if ( stringer == p2_AO_identifier[ 0 .. stringer.maxindex ]) then
                    @uri = p2_AO_identifier
                    @num = p2_AO_identifier.sub( /^.*\//, '' )
                    if (! @num.integer? ) then
                        SE.puts "#{SE.lineno}: =============================================="
                        SE.puts "Invalid param2: #{p2_AO_identifier}"
                        raise
                    end
                else
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Invalid param2: #{p2_AO_identifier}"
                    raise
                end
            end
        end
    end
    attr_reader :res_O, :num, :uri
    
    def new_buffer
        ao_buf_O = AO_Record_Buf.new( self )
        return ao_buf_O
    end
end

class AO_Record_Buf < Record_Buf       
=begin
      A "CRUD-like" class for the /archival_objects. 
      Note that: The 'create' just initializes the buffer, and the Update is called 'store' (so it's IRSD)
      There's also a 'load' method which allows external data to be loaded into the buffer.
=end
    def initialize( ao_O )
        if ( not ao_O.is_a?( Archival_Object )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Archival_Class object, it's: '#{ao_O.class}'"
            raise
        end    
        @rec_jsonmodel_type =  K.archival_object
        @ao_O = ao_O
        @uri = @ao_O.uri
        @num = @ao_O.num
        super( @ao_O.res_O.rep_O.aspace_O )
    end
    attr_reader :ao_O, :num, :uri
    
    def create( p1_level )
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )  
        @record_H[ K.level ] = p1_level
        @record_H[ K.resource ][ K.ref ] = @ao_O.res_O.uri
        @cant_change_A << K.level 
        @cant_change_A << K.resource
        return self
    end

    def load( external_record_H, filter_record_B = true )
        @record_H = super
        if ( not (@record_H.has_key?( K.resource ) and @record_H[K.resource].has_key?( K.ref ) and 
                  @record_H[ K.resource ][ K.ref ] == @ao_O.res_O.uri )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Archival_object doesn't belong to current Resource."
            SE.puts "@record_H[K.resource][K.ref] != @ao_O.res_O.uri"
            SE.ap "@record_H:", @record_H
            raise
        end
        @cant_change_A << K.level 
        @cant_change_A << K.resource
        return self
    end
    
    def read( filter_record_B = true )
        stringer = "#{@ao_O.res_O.rep_O.uri}/archival_objects"
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a archival_object! uri=#{@uri}"
            raise
        end
        @record_H = super( filter_record_B )
#       SE.ap "#{SE.lineno}: @record_H:", @record_H
        if ( @record_H[K.resource][K.ref] != @ao_O.res_O.uri ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Archival_object doesn't belong to current Resource."
            SE.puts "@record_H[K.resource][K.ref] != @ao_O.res_O.uri"
            SE.puts "#{@record_H[K.resource][K.ref]} != #{@ao_O.res_O.uri}"
            raise
        end
        return self
    end
     
    def store( )
#       SE.ap "@record_H:", @record_H            
        if (!(   @record_H[K.resource][K.ref] and @record_H[K.resource][K.ref] != '')) then 
            SE.puts "#{SE.lineno}: =========================================="
            SE.puts "I was expecting an @record_H[K.resource][K.ref] value";
            SE.ap "@record_H:", @record_H
            raise
        end
        if ( @record_H.has_key?(K.parent)) then
            if ( @record_H[K.parent].respond_to?(:to_H) and @record_H[K.parent].has_key?(K.ref)) then
                if ( !(  @record_H[K.parent][K.ref] =~ %r"^#{@ao_O.res_O.rep_O.uri}/(archival_objects|resources)" \
                      or (  @record_H[K.parent][K.ref] == "NO UPDATE MODE" and ! @ao_O.res_O.rep_O.aspace_O.allow_updates )))
                    SE.puts "#{SE.lineno}: =========================================="
                    SE.puts "@record_H[K.parent][K.ref] =~ |#{@ao_O.res_O.rep_O.uri}/(archival_objects|resources)|"
                    SE.puts "@record_H[K.parent][K.ref] = #{@record_H[K.parent][K.ref]}"
                    SE.ap "@record_H:", @record_H
                    raise
                end
            end
        end
        if (!(  @record_H[K.title] and @record_H[K.title] != K.undefined )) then 
            SE.puts "#{SE.lineno}: =========================================="
            SE.puts "I was expecting a @record_H[K.title] value";
            SE.ap "@record_H:", @record_H
            raise
        end
        if ( @record_H[K.resource][K.ref] != @ao_O.res_O.uri ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Archival_object doesn't belong to current Resource."
            SE.puts "@record_H[K.resource][K.ref] != @ao_O.res_O.uri"
            SE.puts "#{@record_H[K.resource][K.ref]} != #{@ao_O.res_O.uri}"
            raise
        end

        if ( @uri == nil ) then
            @uri = "#{@ao_O.res_O.rep_O.uri}/archival_objects"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created ArchivalObject, uri = #{http_response_body_H[ K.uri ]}";
        else
#           SE.puts "#{SE.lineno}: I shouldn't be updating an ArchivalObject"
#           raise
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated ArchivalObject, uri = #{http_response_body_H[ K.uri ]}";
        end
        @uri = http_response_body_H[ K.uri ] 
        @num = @uri.sub( /^.*\//, '' )
        return self
    end
end    


class AO_Query    
    def initialize( p1_rep_O )
        @rep_O = p1_rep_O
        @uri = "#{p1_rep_O.uri}/find_by_id/archival_objects"
        @result = nil
    end
    attr_reader :result, :uri

    def get_H_of_A_of_AO_ref__find_by_ref( p1_AO_ref_A )
        http_response_body = @rep_O.aspace_O.http_calls_O.get( @uri, { 'ref_id[]' => p1_AO_ref_A } )
        if ( http_response_body[K.archival_objects].length < 1 ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Unable to find Archival_Object with ref='#{p1_AO_ref_A}'"
            SE.ap "http_response_body", http_response_body
    #       Note:  The ref's are the strings that look like this:  75f47d3454c79e8d2f9a180ae35779a6
    #              It's NOT the AO number.
            raise
        end        
        @result = http_response_body
        return self
    end
end

