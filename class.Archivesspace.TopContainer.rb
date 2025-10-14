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


class TC_Query_of_Repository
    attr_accessor :rep_O,  :uri,  :page_cnt,  :record_H_A                          
    private       :rep_O=, :uri=, :page_cnt=, :record_H_A=
    
    def initialize( p1_rep_O )
        self.rep_O = p1_rep_O
        self.uri = "#{p1_rep_O.uri}/top_containers"    
        self.page_cnt = 0
        self.record_H_A = nil
    end

    def get_num_A
        http_response_body = self.rep_O.aspace_O.http_calls_O.get( self.uri, { 'all_ids' => 'true' } )
        return http_response_body
    end
    
    def get_page_H( page, page_size )
        http_response_body = self.rep_O.aspace_O.http_calls_O.get( self.uri, { 'page' => page, 'page_size' => page_size } )
        self.page_cnt += 1
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
        all_TC_S = all_TC_C.new( record_H_A, self.page_cnt )
#       SE.pom( all_TC_S )
        return all_TC_S
    end

    def for_num_A( tc_uri_num_A )
        if ( tc_uri_num_A.is_not_a?( Array ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Array, it's: '#{tc_uri_num_A.class}'"
            raise
        end   
        if ( not tc_uri_num_A.all? { | element | element.integer? } ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "The param 1 array isn't all integers."
            SE.puts "URL's won't work."
            raise
        end
        record_H_A = []
        tc_uri_num_A.each_slice( 250 ) do | sliced_A |        
            http_response_body = rep_O.aspace_O.http_calls_O.get( self.uri, { 'id_set' => sliced_A.join( ',' ) } )
            if ( http_response_body.is_not_a?( Array ) ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Unexpected response from #{self.uri}"
                SE.q {'http_response_body'}
                raise
            end
            if ( http_response_body.length < 1 ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Unable to find Archival_Object with 'id_set'='#{tc_uri_num_A}'"
                raise
            end  
            if ( http_response_body.length != sliced_A.length ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "http_response_body.length != sliced_A.length"
                SE.q {[ 'http_response_body.length', 'sliced_A.length' ]}
                SE.q {[ 'http_response_body' ]}
                SE.q {[ 'sliced_A' ]}            
                raise
            end  
            record_H_A.concat( http_response_body )
        end
        if ( record_H_A.length != tc_uri_num_A.length ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "record_H_A.length != tc_uri_num_A.length"
            SE.q {[ 'record_H_A.length', 'tc_uri_num_A.length' ]}
#           SE.q {[ 'record_H_A' ]}
            SE.q {[ 'tc_uri_num_A' ]}            
            raise
        end          
        return record_H_A
    end    
end

class TC_Query_of_Resource
    attr_accessor :res_query_O,  :uri,  :tc_display_order_H,  :record_H_A
    private       :res_query_O=, :uri=, :tc_display_order_H=, :record_H_A=
    
    def initialize( p1_res_query_O )
        if ( p1_res_query_O.is_not_a?( AO_Query_of_Resource ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a 'AO_Query_of_Resource' class object, it's: '#{p1_res_query_O.class}'"
            raise
        end    
        self.res_query_O = p1_res_query_O
        self.uri = "#{p1_res_query_O.res_O.rep_O.uri}/top_containers"    
        if ( p1_res_query_O.record_H_A.nil? ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "p1_res_query_O.record_H_A is nil, was the get_full_ao_buf boolean set?"
            raise
        end
        tc_ao_instance_xref_H_A_H = {}
        p1_res_query_O.record_H_A.each_with_index do | record_H, ao_display_order |
            if ( record_H.has_no_key?( K.instances ) ) then
                next
            end
            record_H[ K.instances ].each do | instance |
                if ( instance.has_no_key?( K.sub_container ) ) then
                    next
                end
                if ( instance[ K.sub_container ].has_no_key?( K.top_container ) ) then
                    next
                end
                if ( instance[ K.sub_container ][ K.top_container ].has_no_key?( K.ref ) ) then
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "instance with top_container but no K.ref key!"
                    SE.q { 'instance' }
                    SE.q { 'record_H' }
                    raise
                end
                tc_uri_num = instance[ K.sub_container ][ K.top_container ][ K.ref ].delete_prefix( "#{self.uri}/" ).to_i
                
                if ( tc_ao_instance_xref_H_A_H.has_no_key?( tc_uri_num ) ) then
                    tc_ao_instance_xref_H_A_H[ tc_uri_num ] = []
                end       
                tc_ao_instance_xref_H_A_H[ tc_uri_num ].push( { K.title           => record_H[ K.title ],
                                                                :ao_display_order => ao_display_order,
                                                                K.instance        => instance[ K.sub_container ] } )
                
            end
        end
        
        #   Make a hash by tc_uri_num with the lowest (minimum) :ao_display_order value...
        tmp_H = {}
        tc_ao_instance_xref_H_A_H.each_pair do | tc_uri_num, ao_instance_xref_H_A |
             tmp_H[ tc_uri_num ] = ao_instance_xref_H_A.map { | h | h[ :ao_display_order ] }.min
        end
        #   Then sort the tmp_H by that lowest value, but sequence the hash 1..N for the actual order.
        self.tc_display_order_H = tmp_H.sort_by { |_, v| v }.each_with_index.to_h { |(k, _), i| [k, i] }
        if ( self.tc_display_order_H.length != tc_ao_instance_xref_H_A_H.length ) then
             SE.puts "#{SE.lineno}: =============================================="
             SE.puts "self.tc_display_order_H.length != tc_ao_instance_xref_H_A_H.length"
             SE.q {[ 'self.tc_display_order_H.length', 'tc_ao_instance_xref_H_A_H.length' ]}
             raise
        end
        
        self.record_H_A = Array.new( self.tc_display_order_H.length )
        TC_Query_of_Repository.new( p1_res_query_O.res_O.rep_O ).for_num_A( self.tc_display_order_H.keys.sort ).each do | record_H |
            tc_uri_num = record_H[ K.uri ].delete_prefix( "#{self.uri}/" ).to_i
            tc_display_order = self.tc_display_order_H[ tc_uri_num ]
            if ( tc_display_order.nil? ) then
                 SE.puts "#{SE.lineno}: =============================================="
                 SE.puts "self.tc_display_order_H[ tc_uri_num ] is nil?"
                 SE.q {'record_H[ K.uri ]'}
                 SE.q {'self.tc_display_order_H'}
                 raise
            end 
            if ( self.record_H_A[ tc_display_order ].not_nil? ) then
                 SE.puts "#{SE.lineno}: =============================================="
                 SE.puts "self.record_H_A[ tc_display_order ].not_nil?"
                 SE.q {'record_H'}
                 SE.q {'self.record_H_A[ tc_display_order ]'}
                 SE.q {'self.tc_display_order_H'}
                 raise
            end 
            record_H[ "~__RELATED_AO's__~" ] = tc_ao_instance_xref_H_A_H[ tc_uri_num ]
            self.record_H_A[ tc_display_order ] = record_H
        end
        if ( self.record_H_A.length != self.tc_display_order_H.keys.length ) then
             SE.puts "#{SE.lineno}: =============================================="
             SE.puts "self.record_H_A.length != self.tc_display_order_H.keys.length"
             SE.q {[ 'self.record_H_A.length', 'self.tc_display_order_H.keys.length' ]}
             raise
        end 
        if ( self.record_H_A.include?( nil ) ) then
             SE.puts "#{SE.lineno}: =============================================="
             SE.puts "self.record_H_A.include?( nil )"
             raise
        end                
        return self
    end
    
    def record_H( p1_tc_uri_num )
        case true
        when p1_tc_uri_num.is_a?( String ) 
            tc_uri_num = p1_tc_uri_num.delete_prefix( "#{self.uri}/" ).to_i
        when p1_tc_uri_num.integer?
            tc_uri_num = p1_tc_uri_num.to_i
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Was expecting param 'p1_tc_uri_num' to be a String or integer"
            SE.q {'p1_tc_uri_num'}
            raise
        end
        tc_display_order = self.tc_display_order_H[ tc_uri_num ]
        if ( tc_display_order.nil? ) then
            return nil
        end
        if ( self.record_H_A[ tc_display_order ].nil? ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "self.record_H_A[ tc_display_order ].nil?"
            SE.q {'tc_display_order'}
            SE.q {'self.record_H_A'}
            raise
        end
        return self.record_H_A[ tc_display_order ]
    end

end



