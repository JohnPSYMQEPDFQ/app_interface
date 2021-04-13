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
=begin
      Top_Container just holds the TC-number and uri.   
      An object of this is needed to create a TC_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          tc_buffer_Obj = Top_Container.new(resource_Obj, tc-num|uri).new_buffer[.read|create]
=end
    def initialize( p1_O, p2_TC_identifier = nil )
        if ( p1_O.class == Resource_Record_Buf ) then
            @res_O = p1_O.res_O
        else
            if ( p1_O.class != Resource ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Param 1 is not a Resource or Resource_Record_Buf class object, it's: '#{p1_O.class}'"
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
                        SE.puts "#{SE.lineno}: =============================================="
                        SE.puts "Invalid param2: #{p2_TC_identifier}"
                        raise
                    end
                else
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Invalid param2: #{p2_TC_identifier}"
                    raise
                end
            end
        end
    end
    attr_reader :res_O, :num, :uri
    
    def new_buffer
        tc_buf_O = TC_Record_Buf.new( self )
        return tc_buf_O
    end
end

class TC_Record_Buf < Record_Buf
=begin
      A "CRUD-like" class for the /top_containers. 
      Note that: The 'create' just initializes the buffer, and the Update is called 'store' (so it's IRSD)
=end
    def initialize( tc_O )
        if ( tc_O.class.name.downcase != K.top_container ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Top_Container object, it's: '#{tc_O.class}'"
            raise
        end    
        @rec_jsonmodel_type =  K.top_container
        @tc_O = tc_O
        @uri = @tc_O.uri
        @num = @tc_O.num
        super( @tc_O.res_O.rep_O.aspace_O )
    end
    attr_reader :tc_O, :num, :uri
    
    def create  
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )
        @record_H[ K.resource ][ K.ref ] = @tc_O.res_O.uri
        @record_H[ K.created_for_collection ] = @tc_O.res_O.uri
        @cant_change_A << K.resource
        @cant_change_A << K.created_for_collection
        return self
    end
    
    def read( filter_record_B = true )
        stringer = "#{@tc_O.res_O.rep_O.uri}/top_containers"
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a top_container! uri=#{@uri}"
            raise
        end
        @record_H = super( filter_record_B ) 
#       SE.pp "#{SE.lineno}: @record_H:", @record_H
        return self
    end

    def store( )
    #   SE.pp "@record_H:", @record_H 
        if (!(  @record_H[K.type] and @record_H[K.type] != '')) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.type] value";
            SE.puts "@uri = #{@uri}"
            SE.pp "@record_H:", @record_H
            raise
        end
        if (!(  @record_H[K.indicator] and @record_H[K.indicator] != K.undefined )) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.indicator] value";
            SE.puts "@uri = #{@uri}"
            SE.pp "@record_H:", @record_H
            raise
        end
        if ( @record_H[K.resource][K.ref] != @tc_O.res_O.uri ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Top_Container doesn't belong to current Resource."
            SE.puts "@record_H[K.resource][K.ref] != @tc_O.res_O.uri"
            SE.puts "#{@record_H[K.resource][K.ref]} != #{@tc_O.res_O.uri}"
            raise
        end
        if ( @uri == nil ) then
            @uri = "#{@tc_O.res_O.rep_O.uri}/top_containers"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created TopContainer, uri = #{http_response_body_H[ K.uri ]}"
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I shouldn't be updating a TopContainer"
            raise
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated top_container, uri = #{http_response_body_H[ K.uri ]}"
        end
        @uri = http_response_body_H[ K.uri ] 
        @num = @uri.sub( /^.*\//, '' )
        return self
    end
        
    def delete( )
        stringer = "#{@tc_O.res_O.rep_O.uri}/top_containers"
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a top_container! uri=#{@uri}"
            raise
        end
        read()
        
        if ( @record_H.has_key?( K.resource ) and @record_H[ K.resource ].has_key?( K.ref )) then
            if ( @record_H[ K.resource ][ K.ref ] != @tc_O.res_O.uri ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Top_Container doesn't belong to current Resource."
                SE.puts "@record_H[K.resource][K.ref] != @tc_O.res_O.uri"
                SE.puts "#{@record_H[K.resource][K.ref]} != #{@tc_O.res_O.uri}"
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
        http_response_body = @rep_O.aspace_O.http_calls_O.get( @uri, p1_params )
        @result = http_response_body
        return self
    end
end


