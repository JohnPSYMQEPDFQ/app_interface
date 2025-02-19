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
        case true        
        when p1_O.is_a?( Resource_Record_Buf ) then
            @res_O = p1_O.res_O
            @rep_O = p1_O.res_O.rep_O
        when p1_O.is_a?( Resource ) then
            @res_O = p1_O
            @rep_O = p1_O.rep_O
        when p1_O.is_a?( Repository ) then
            @res_O = nil
            @rep_O = p1_O
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Resource, Resource_Record_Buf, or Repository class object, it's: '#{p1_O.class}'"
            raise
        end    

        if ( p2_TC_identifier == nil ) then
            @num = nil
            @uri = nil
        else
            if ( p2_TC_identifier.integer? ) then
                @num = p2_TC_identifier
                @uri = "#{@rep_O.uri}/top_containers/#{@num}"
            else
                stringer = "#{@rep_O.uri}/top_containers"
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
    attr_reader :res_O, :rep_O, :num, :uri
    
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
        if ( not tc_O.is_a?( Top_Container )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Top_Container object, it's a '#{tc_O.class}'"
            raise
        end    
        @rec_jsonmodel_type =  K.top_container
        @tc_O = tc_O
        @uri = @tc_O.uri
        @num = @tc_O.num
        super( @tc_O.rep_O.aspace_O )
    end
    attr_reader :tc_O, :num, :uri
    
    def create  
        if ( @tc_O.res_O == nil ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "@tc_O.res_O == nil"
            SE.puts "This object was probably created with a 'Repository' Object"
            raise
        end
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )
        @record_H[ K.resource ][ K.ref ] = @tc_O.res_O.uri
        @record_H[ K.created_for_collection ] = @tc_O.res_O.uri
        @cant_change_A << K.resource
        @cant_change_A << K.created_for_collection
        return self
    end
    
    def load( external_record_H, filter_record_B = true )
        @record_H = super
        @cant_change_A << K.resource
        @cant_change_A << K.created_for_collection
        return self
    end
    
    def read( filter_record_B = true )
        stringer = "#{@tc_O.rep_O.uri}/top_containers"
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a top_container! uri=#{@uri}"
            raise
        end
        @record_H = super( filter_record_B ) 
#       SE.q {[ '@record_H' ]}
        return self
    end

    def store( )
    #   SE.q {[ '@record_H' ]}
        if ( @tc_O.res_O == nil ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "@tc_O.res_O == nil"
            SE.puts "This object was probably created with a 'Repository' Object"
            raise
        end
        if (!(  @record_H[K.type] and @record_H[K.type] != '')) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.type] value";
            SE.puts "@uri = #{@uri}"
            SE.q {[ '@record_H' ]}
            raise
        end
        if (!(  @record_H[K.indicator] and @record_H[K.indicator] != K.undefined )) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.indicator] value";
            SE.puts "@uri = #{@uri}"
            SE.q {[ '@record_H' ]}
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
            @uri = "#{@tc_O.rep_O.uri}/top_containers"
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
        stringer = "#{@tc_O.rep_O.uri}/top_containers"
        if ( stringer != @uri[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a top_container! uri=#{@uri}"
            raise
        end
        read()
        
        if ( @record_H.has_key?( K.resource ) and @record_H[ K.resource ].has_key?( K.ref )) then
            if ( @tc_O.res_O == nil ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "@tc_O.res_O == nil"
                SE.puts "This object was probably created with a 'Repository' Object"
                raise
            end
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
        @page_cnt = 0
    end
    attr_reader :rep_O, :uri

    def get_num_A
        http_response_body = @rep_O.aspace_O.http_calls_O.get( @uri, { 'all_ids' => 'true' } )
        return http_response_body
    end
    
    def get_page_H( page, page_size )
        http_response_body = @rep_O.aspace_O.http_calls_O.get( @uri, { 'page' => page, 'page_size' => page_size } )
        @page_cnt += 1
        return http_response_body
    end
   
    def get_record_H_A
        record_H_A = [ ]
        page_total = nil
        page_size = 250
        page = 1; loop do
            page_H = self.get_page_H( page, page_size )
            if ( not ( [ 'first_page', 'last_page', 'results', 'this_page', 'total' ] - page_H.keys ).empty? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Missing key in 'page_H'"
                SE.ai page_H
                raise
            end        
            record_H_A.concat( page_H[ 'results' ] )
            page_total = page_H[ 'total' ]
            page += 1
            break if ( page > page_H[ 'last_page' ])
        end
        if ( record_H_A.length != page_total ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Length of 'record_H_A' != to page_H[ 'total' ]"
            SE.puts "'#{record_H_A.length}' != '#{page_total}'"
            SE.ai page_H
            raise
        end
        return record_H_A         
    end
    
    def get_all_TC_S
        all_TC_C = Struct.new( :record_H_A, :page_cnt, 
        )   do
                def for_res__record_H_A( p1_O )
                    case true        
                    when p1_O.is_a?( Resource_Record_Buf ) then
                        res_O = p1_O.res_O
                    when p1_O.is_a?( Resource ) then
                        res_O = p1_O
                    else
                        SE.puts "#{SE.lineno}: =============================================="
                        SE.puts "Param 1 is not a Resource or Resource_Record_Buf class object, it's a '#{p1_O.class}'"
                        raise                    
                    end
                    if ( res_O.uri == nil ) then
                        SE.puts "#{SE.lineno}: =============================================="
                        SE.puts "Param 1 res_O.uri is nil"
                        raise     
                    end
                    res_tc_record_H_A = [ ]
                    record_H_A.each do | record_H |
                        if ( record_H.key?( K.collection ) && record_H[ K.collection ].count > 0 ) then     
                            record_H[ K.collection ].each do | collection |
                                if ( collection.key?( K.ref ) && collection[ K.ref ] == res_O.uri ) then
                                    res_tc_record_H_A << record_H
                                end
                            end
                        end
                    end
                    return res_tc_record_H_A
                end
                
                def for_unused__record_H_A
                    unused_tc_record_H_A = [ ]
                    record_H_A.each do | record_H |
                        if ( not ( record_H.key?( K.collection ) && record_H[ K.collection ].count > 0 )) then     
                            unused_tc_record_H_A << record_H
                        end 
                    end
                    return unused_tc_record_H_A
                end
            end
        record_H_A = self.get_record_H_A   
        all_TC_S = all_TC_C.new( record_H_A, @page_cnt )
#       SE.pom( all_TC_S )
        return all_TC_S
    end
    #attr_reader :record_H_A   # Don't know why, but a reader and writer is included for 'record_H_A' 
                               # See 'SE.pom( all_TC_S )' output.  It's something to do with the Structure.

    
end




