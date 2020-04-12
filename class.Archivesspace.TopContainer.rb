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

class Top_Container 
    def initialize( p1_O, p2_TC_identifier = nil )
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
        if ( p2_TC_identifier == nil ) then
            @num = nil
            @uri = nil
        else
            if ( p2_TC_identifier.integer? ) then
                @num = p2_TC_identifier
                @uri = "#{@res_O.rep_O.uri}/top_containers/#{@num}"
            else
                stringer = "#{@res_O.rep_O.uri}/top_containers"
                if ( stringer == p2_TC_identifier[ 0 .. stringer.maxindex ]) then
                    @uri = p2_TC_identifier
                    @num = p2_TC_identifier.sub( /^.*\//, '' )
                    if (! @num.integer? ) then
                        Se.puts "#{Se.lineno}: =============================================="
                        Se.puts "Invalid param2: #{p2_TC_identifier}"
                        raise
                    end
                end
            end
        end
    end
    attr_reader :res_O, :num, :uri
    
    def make_buffer
        tc_buf_O = TC_Record_Buf.new( self )
        return tc_buf_O
    end
end

class TC_Record_Buf < Record_Buf

    def initialize( rec_type_O )
        if ( rec_type_O.class == 'Top_Container' ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Param 1 is not an Top_Container object, it's: '#{rec_type_O.class}'"
            raise
        end    
        @rec_type_O = rec_type_O
        @uri = @rec_type_O.uri
        @num = @rec_type_O.num
        super( @rec_type_O.res_O.rep_O.aspace_O )
    end
    attr_reader :rec_type_O, :num, :uri, :record_H
    
    
    def create  
        @record_H.merge!( Record_Format.new( K.top_container ).record_H )
        @record_H[ K.resource ][ K.ref ] = @rec_type_O.res_O.uri
        @record_H[ K.created_for_collection ] = @rec_type_O.res_O.uri
        return self
    end
    
    def read( filter_record_B = true )
        @record_H = super( filter_record_B ) 
#       Se.pp "#{Se.lineno}: @record_H:", @record_H
        if ( ! ( @record_H.has_key?( K.jsonmodel_type ) and @record_H[ K.jsonmodel_type ] == K.top_container ) )
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Was expecting a top_container jsonmodel_type"
            Se.puts "@uri = #{@uri}"
            Se.pp "@record_H:", @record_H
            raise
        end  
        return self
    end

    def store( )
    #   Se.pp "@record_H:", @record_H
    
        if (!(  @record_H[K.jsonmodel_type] and @record_H[K.jsonmodel_type] == K.top_container)) then 
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Was expecting a top_container jsonmodel_type"
            Se.puts "@uri = #{@uri}"
            Se.pp "@record_H:", @record_H
            raise
        end 
        if (!(  @record_H[K.type] and @record_H[K.type] != '')) then 
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "#{Se.lineno}: I was expecting an @record_H[K.type] value";
            Se.puts "@uri = #{@uri}"
            Se.pp "@record_H:", @record_H
            raise
        end
        if (!(  @record_H[K.indicator] and @record_H[K.indicator] != K.undefined )) then 
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "#{Se.lineno}: I was expecting an @record_H[K.indicator] value";
            Se.puts "@uri = #{@uri}"
            Se.pp "@record_H:", @record_H
            raise
        end
        if ( @record_H[K.resource][K.ref] != @rec_type_O.res_O.uri ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Top_Container doesn't belong to current Resource."
            Se.puts "@record_H[K.resource][K.ref] != @rec_type_O.res_O.uri"
            Se.puts "#{@record_H[K.resource][K.ref]} != #{@rec_type_O.res_O.uri}"
            raise
        end
        if ( @uri == nil ) then
            @uri = "#{@rec_type_O.res_O.rep_O.uri}/top_containers"
            http_response_body_H = super
            Se.puts "#{Se.lineno}: Created TopContainer, uri = #{http_response_body_H[ K.uri ]}"
        else
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "#{Se.lineno}: I shouldn't be updating a TopContainer"
            raise
            http_response_body_H = super
            Se.puts "#{Se.lineno}: Updated top_container, uri = #{http_response_body_H[ K.uri ]}"
        end
        @uri = http_response_body_H[ K.uri ] 
        return self
    end
        
    def delete( )
        stringer = "#{@rec_type_O.res_O.rep_O.uri}/top_containers"
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            Se.puts "#{Se.lineno}: =============================================="     
            Se.puts "uri isn't a top_container! uri=#{@uri}"
            raise
        end
        read()
        
        if ( @record_H.has_key?( K.resource ) and @record_H[ K.resource ].has_key?( K.ref )) then
            if ( @record_H[ K.resource ][ K.ref ] != @rec_type_O.res_O.uri ) then
                Se.puts "#{Se.lineno}: =============================================="
                Se.puts "Top_Container doesn't belong to current Resource."
                Se.puts "@record_H[K.resource][K.ref] != @rec_type_O.res_O.uri"
                Se.puts "#{@record_H[K.resource][K.ref]} != #{@rec_type_O.res_O.uri}"
                raise
            end
        end
        http_response_body_H = super
        return http_response_body_H
    end	
end


class TC_Query
    def initialize( p1_rep_O )
        @rep_O = p1_rep_O
        @uri = "#{p1_rep_O.uri}/top_containers"    
        @result = nil
    end
    attr_reader :result, :rep_O, :uri

    def get_A_of_TC_nums( p1_params )
        http_response_body = @rep_O.aspace_O.http_calls_O.http_get( @uri, p1_params )
        @result = http_response_body
        return self
    end
end


