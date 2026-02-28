
class Top_Container 
=begin
      Top_Container just holds the TC-number and uri.   
      An object of this is needed to create a TC_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          tc_buffer_Obj = Top_Container.new(resource_Obj, tc-num|uri).new_buffer[.read|create]
=end
    attr_reader :res_O, :rep_O, :uri_num, :uri_addr
    def initialize( p1_O, p2_TC_identifier = nil )
        case true        
        when p1_O.is_a?( Resource_Record_Buf ) 
            @res_O = p1_O.res_O
            @rep_O = p1_O.res_O.rep_O
        when p1_O.is_a?( Resource )
            @res_O = p1_O
            @rep_O = p1_O.rep_O
        when p1_O.is_a?( Repository ) 
            @res_O = nil
            @rep_O = p1_O
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Resource, Resource_Record_Buf, or Repository class object, it's: '#{p1_O.class}'"
            raise
        end    

        case true
        when p2_TC_identifier.nil? 
            @uri_num = nil
            @uri_addr = nil
        when p2_TC_identifier.integer? 
            @uri_num = p2_TC_identifier
            @uri_addr = "#{@rep_O.uri_addr}/#{TOP_CONTAINERS}/#{@uri_num}"
        when p2_TC_identifier.start_with?( "#{@rep_O.uri_addr}/#{TOP_CONTAINERS}" ) 
            @uri_addr = p2_TC_identifier
            @uri_num = p2_TC_identifier.trailing_digits
            if (! @uri_num.integer? ) then
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
        @uri_addr = @tc_O.uri_addr
        @uri_num = @tc_O.uri_num
        super( @tc_O.rep_O.aspace_O )
    end
    attr_reader :tc_O, :uri_num, :uri_addr
    
    def create  
        if ( @tc_O.res_O.nil? ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "@tc_O.res_O == nil"
            SE.puts "This object was probably created with a 'Repository' Object"
            raise
        end
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )
        @record_H[ K.resource ][ K.ref ] = @tc_O.res_O.uri_addr
        @record_H[ K.created_for_collection ] = @tc_O.res_O.uri_addr
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
        stringer = "#{@tc_O.rep_O.uri_addr}/#{TOP_CONTAINERS}"
        if ( stringer != @uri_addr[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a top_container! uri=#{@uri_addr}"
            raise
        end
        @record_H = super( filter_record_B ) 
#       SE.q {[ '@record_H' ]}
        return self
    end

    def store( )
    #   SE.q {[ '@record_H' ]}
        if ( @tc_O.res_O.nil? ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "@tc_O.res_O == nil"
            SE.puts "This object was probably created with a 'Repository' Object"
            raise
        end
        if (!(  @record_H[K.type] and @record_H[K.type] != '')) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.type] value";
            SE.puts "@uri_addr = #{@uri_addr}"
            SE.q {[ '@record_H' ]}
            raise
        end
        if (!(  @record_H[K.indicator] and @record_H[K.indicator] != K.undefined )) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a @record_H[K.indicator] value";
            SE.puts "@uri_addr = #{@uri_addr}"
            SE.q {[ '@record_H' ]}
            raise
        end
        if not (    ( @record_H[ K.collection ].any?{ | collection | collection[ K.ref ] == @tc_O.res_O.uri_addr  } ) or
                    ( @record_H.fetch( K.resource, {} ).fetch( K.ref, '' ) == @tc_O.res_O.uri_addr )
               ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Top_Container doesn't belong to current Collection."
            SE.puts '@record_H[ K.collection ].any?{ | collection | collection[ K.ref ] == @tc_O.res_O.uri_addr  }'
            SE.puts '@record_H.fetch( K.resource, {} ).fetch( K.ref, '' ) == @tc_O.res_O.uri_addr'
            SE.q {'@tc_O.res_O.uri_addr'}
            SE.q {'@record_H[ K.collection ]'}
            SE.q {'@record_H'}
            raise
        end
        if ( @uri_addr.nil? ) then
            @uri_addr = "#{@tc_O.rep_O.uri_addr}/#{TOP_CONTAINERS}"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created TopContainer, uri = #{http_response_body_H[ K.uri ]}"
        else
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated top_container, uri = #{http_response_body_H[ K.uri ]}"
        end
        @uri_addr = http_response_body_H[ K.uri ] 
        @uri_num = @uri_addr.trailing_digits
        return self
    end
        
    def delete( )
        stringer = "#{@tc_O.rep_O.uri_addr}/#{TOP_CONTAINERS}"
        if ( stringer != @uri_addr[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a top_container! uri=#{@uri_addr}"
            raise
        end
        read()
        
        if ( @record_H.has_key?( K.resource ) and @record_H[ K.resource ].has_key?( K.ref )) then
            if ( @tc_O.res_O.nil? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "@tc_O.res_O == nil"
                SE.puts "This object was probably created with a 'Repository' Object"
                raise
            end
            if ( @record_H[ K.resource ][ K.ref ] != @tc_O.res_O.uri_addr ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Top_Container doesn't belong to current Resource."
                SE.puts "@record_H[K.resource][K.ref] != @tc_O.res_O.uri_addr"
                SE.puts "#{@record_H[K.resource][K.ref]} != #{@tc_O.res_O.uri_addr}"
                raise
            end
        end
        http_response_body_H = super
        return http_response_body_H
    end    
end

class TC_Query_of_Resource
    attr_accessor :ao_query_O,  :uri_addr,  :tc_display_order_H,  :record_H_A
    private       :ao_query_O=, :uri_addr=, :tc_display_order_H=, :record_H_A=
    
    def initialize( p1_ao_query_O )
        if ( p1_ao_query_O.is_not_a?( AO_Query_of_Resource ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a 'AO_Query_of_Resource' class object, it's: '#{p1_ao_query_O.class}'"
            raise
        end    
        self.ao_query_O = p1_ao_query_O
        self.uri_addr = "#{p1_ao_query_O.res_O.rep_O.uri_addr}/#{TOP_CONTAINERS}"    
        if ( p1_ao_query_O.record_H_A.nil? ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "p1_ao_query_O.record_H_A is nil, was the get_full_ao_buf boolean set?"
            raise
        end
        tc_ao_instance_xref_H_A_H = {}
        p1_ao_query_O.record_H_A.each_with_index do | record_H, ao_display_order |
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
                tc_uri_num = instance[ K.sub_container ][ K.top_container ][ K.ref ].delete_prefix( "#{self.uri_addr}/" ).to_i
                raise 'tc_uri_num == 0' if ( tc_uri_num == 0 )
                
                if ( tc_ao_instance_xref_H_A_H.has_no_key?( tc_uri_num ) ) then
                    tc_ao_instance_xref_H_A_H[ tc_uri_num ] = []
                end       
                tc_ao_instance_xref_H_A_H[ tc_uri_num ].push( { K.title           => record_H[ K.title ],
                                                                :ao_display_order => ao_display_order,
                                                                K.uri             => record_H[ K.uri ],
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
        p1_ao_query_O.res_O.rep_O.query( TOP_CONTAINERS )
                           .record_H_A__of_id_A( self.tc_display_order_H.keys.sort )
                           .result_A.each do | record_H |
            tc_uri_num = record_H[ K.uri ].delete_prefix( "#{self.uri_addr}/" ).to_i
            raise 'tc_uri_num == 0' if ( tc_uri_num == 0 )
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
             SE.q {'self.record_H_A'}
             raise
        end                
        return self
    end
    
    def record_H__of_uri( p1_tc_uri_addr_OR_id_num )
        case true
        when p1_tc_uri_addr_OR_id_num.is_a?( String ) 
            stringer = p1_tc_uri_addr_OR_id_num.delete_prefix( "#{self.uri_addr}/" )
            if ( stringer.not_integer? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Param 'p1_tc_uri_addr_OR_id_num' won't convert to an integer."
                if ( p1_tc_uri_addr_OR_id_num[ 0 ] == '/' ) then
                    SE.puts "It's probably because the URI doesn't start with '#{self.uri_addr}'"
                end
                SE.q {['p1_tc_uri_addr_OR_id_num','stringer','self.uri_addr']}
                raise
            end
            tc_uri_num = stringer.to_i
        when p1_tc_uri_addr_OR_id_num.integer?
            tc_uri_num = p1_tc_uri_addr_OR_id_num.to_i
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Was expecting param 'p1_tc_uri_addr_OR_id_num' to be a URI String or integer"
            SE.q {'p1_tc_uri_addr_OR_id_num'}
            raise
        end
        raise 'tc_uri_num == 0' if ( tc_uri_num == 0 )
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



