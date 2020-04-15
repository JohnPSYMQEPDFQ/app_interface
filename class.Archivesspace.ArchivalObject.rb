=begin

Abbreviations,  AO/ao = archival object(Everything's an AO, but there's also uri "archive_objects". It's confusing...)
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

class Archival_Object
    def initialize( p1_O, p2_AO_identifier = nil )
        if ( p1_O.class == Resource_Record_Buf ) then
            @res_O = p1_O.rec_type_O
        else
            if ( p1_O.class != Resource ) then
                Se.puts "#{Se.lineno}: =============================================="
                Se.puts "Param 1 is not a Resource or Resource_Record_Buf class object, it's: '#{p1_O.class}'"
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
                        Se.puts "#{Se.lineno}: =============================================="
                        Se.puts "Invalid param2: #{p2_AO_identifier}"
                        raise
                    end
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
    def initialize( rec_type_O )
        if ( rec_type_O.class.name.downcase != K.archival_object ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Param 1 is not an Archival_Class object, it's: '#{rec_type_O.class.name.downcase}'"
            raise
        end    
        @rec_jsonmodel_type =  K.archival_object
        @rec_type_O = rec_type_O
        @uri = @rec_type_O.uri
        @num = @rec_type_O.num
        super( @rec_type_O.res_O.rep_O.aspace_O )
    end
    attr_reader :rec_type_O, :num, :uri
    
    def create( p1_level )
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )  
        @record_H[ K.level ] = p1_level
        @record_H[ K.resource ][ K.ref ] = @rec_type_O.res_O.uri
        @cant_change_A << K.level 
        @cant_change_A << K.resource
        return self
    end

    def load( external_record_H, filter_record_B = true )
        @record_H = super
        if ( @record_H[K.resource][K.ref] != @rec_type_O.res_O.uri ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Archival_object doesn't belong to current Resource."
            Se.puts "@record_H[K.resource][K.ref] != @rec_type_O.res_O.uri"
            Se.puts "#{@record_H[K.resource][K.ref]} != #{@rec_type_O.res_O.uri}"
            raise
        end
        return self
    end
    
    def read( filter_record_B = true )
        stringer = "#{@rec_type_O.res_O.rep_O.uri}/archival_objects"
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            Se.puts "#{Se.lineno}: =============================================="     
            Se.puts "uri isn't a archival_object! uri=#{@uri}"
            raise
        end
        @record_H = super( filter_record_B )
#       Se.pp "#{Se.lineno}: @record_H:", @record_H
        if ( @record_H[K.resource][K.ref] != @rec_type_O.res_O.uri ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Archival_object doesn't belong to current Resource."
            Se.puts "@record_H[K.resource][K.ref] != @rec_type_O.res_O.uri"
            Se.puts "#{@record_H[K.resource][K.ref]} != #{@rec_type_O.res_O.uri}"
            raise
        end
        return self
    end
     
    def store( )
#       Se.pp "@record_H:", @record_H            
        if (!(   @record_H[K.resource][K.ref] and @record_H[K.resource][K.ref] != '')) then 
            Se.puts "#{Se.lineno}: =========================================="
            Se.puts "I was expecting an @record_H[K.resource][K.ref] value";
            Se.pp "@record_H:", @record_H
            raise
        end
        if ( @record_H.has_key?(K.parent)) then
            if ( @record_H[K.parent].respond_to?(:to_H) and @record_H[K.parent].has_key?(K.ref)) then
                if ( !(  @record_H[K.parent][K.ref] =~ %r"^#{@rec_type_O.res_O.rep_O.uri}/(archival_objects|resources)" \
                       or(  @record_H[K.parent][K.ref] == "NO UPDATE MODE" and ! $global_update)))
                    Se.puts "#{Se.lineno}: =========================================="
                    Se.puts "@record_H[K.parent][K.ref] =~ |#{@rec_type_O.res_O.rep_O.uri}/(archival_objects|resources)|"
                    Se.puts "@record_H[K.parent][K.ref] = #{@record_H[K.parent][K.ref]}"
                    Se.pp "@record_H:", @record_H
                    raise
                end
            end
        end
        if (!(  @record_H[K.title] and @record_H[K.title] != K.undefined )) then 
            Se.puts "#{Se.lineno}: =========================================="
            Se.puts "I was expecting a @record_H[K.title] value";
            Se.pp "@record_H:", @record_H
            raise
        end
        if ( @record_H[K.resource][K.ref] != @rec_type_O.res_O.uri ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Archival_object doesn't belong to current Resource."
            Se.puts "@record_H[K.resource][K.ref] != @rec_type_O.res_O.uri"
            Se.puts "#{@record_H[K.resource][K.ref]} != #{@rec_type_O.res_O.uri}"
            raise
        end

        if ( @uri == nil ) then
            @uri = "#{@rec_type_O.res_O.rep_O.uri}/archival_objects"
            http_response_body_H = super
            Se.puts "#{Se.lineno}: Created ArchivalObject, uri = #{http_response_body_H[ K.uri ]}";
        else
            Se.puts "#{Se.lineno}: I shouldn't be updating an ArchivalObject"
            raise
            http_response_body_H = super
            Se.puts "#{Se.lineno}: Updated ArchivalObject, uri = #{http_response_body_H[ K.uri ]}";
        end
        @uri = http_response_body_H[ K.uri ] 
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
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Unable to find Archival_Object with ref='#{p1_AO_ref_A}'"
            Se.pp "http_response_body", http_response_body
    #       Note:  The ref's are the strings that look like this:  75f47d3454c79e8d2f9a180ae35779a6
    #              It's NOT the AO number.
            raise
        end		
        @result = http_response_body
        return self
    end
end

