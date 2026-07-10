
class Top_Container 
=begin
      Top_Container just holds the TC-number and uri.   
      An object of this is needed to create a TC_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          tc_buffer_Obj = Top_Container.new(repository_Obj, tc-num|uri).new_buffer[.read|create]
=end
public  attr_reader :res_O, :rep_O, :rec_id, :uri_addr
private attr_writer :res_O, :rep_O, :rec_id, :uri_addr

    def initialize( p1_O, p2_tc_uri_addr_OR_rec_id = nil )
        case true        
        when p1_O.is_a?( Resource )
            self.res_O = p1_O
            self.rep_O = p1_O.rep_O
        when p1_O.is_a?( Repository ) 
            self.res_O = nil
            self.rep_O = p1_O
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a 'Repository' or 'Resource' class object, it's: '#{p1_O.class}'"
            raise
        end    

        case true
        when p2_tc_uri_addr_OR_rec_id.nil? 
            self.rec_id   = nil
            self.uri_addr = nil
        when p2_tc_uri_addr_OR_rec_id.integer? 
            self.rec_id   = p2_tc_uri_addr_OR_rec_id
            self.uri_addr = "#{self.rep_O.uri_addr}/#{TOP_CONTAINERS}/#{self.rec_id}"
        when p2_tc_uri_addr_OR_rec_id.start_with?( "#{self.rep_O.uri_addr}/#{TOP_CONTAINERS}" ) 
            self.uri_addr = p2_tc_uri_addr_OR_rec_id
            self.rec_id   = p2_tc_uri_addr_OR_rec_id.trailing_digits
            if (! self.rec_id.integer? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Invalid param2: #{p2_tc_uri_addr_OR_rec_id}"
                raise
            end
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Invalid param2: #{p2_tc_uri_addr_OR_rec_id}"
            raise
        end
    end
    
    def new_buffer
        tc_BO = TC_Record_Buf.new( self )
        return tc_BO
    end
end

class TC_Record_Buf < Record_Buf
=begin
      A "CRUD-like" class for the /top_containers. 
      Note that: The 'create' just initializes the buffer, and the Update is called 'store' (so it's IRSD)
=end
public  attr_reader :tc_O, :rec_id, :uri_addr, :rec_jsonmodel_type
private attr_writer :tc_O, :rec_id, :uri_addr, :rec_jsonmodel_type

    def initialize( tc_O )
        if ( not tc_O.is_a?( Top_Container )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Top_Container object, it's a '#{tc_O.class}'"
            raise
        end    
        self.rec_jsonmodel_type = K.top_container
        self.tc_O               = tc_O
        self.uri_addr           = self.tc_O.uri_addr
        self.rec_id             = self.tc_O.rec_id
        super( self.tc_O.rep_O.aspace_O )
    end
    
    def create
        if ( self.tc_O.res_O.nil? ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "self.tc_O.res_O == nil"
            SE.puts "This object was probably created with a 'Repository' Object"
            raise
        end
        super
#       self.record_H.merge!( Record_Format.new( self.rec_jsonmodel_type ).record_H )
        self.record_H[ K.resource ][ K.ref ] = self.tc_O.res_O.uri_addr
        self.record_H[ K.created_for_collection ] = self.tc_O.res_O.uri_addr
        self.cant_change_A << K.resource
        self.cant_change_A << K.created_for_collection
        return self
    end
    
    def load( external_record_H, filter_record_TF: true )
        self.record_H = super
        self.cant_change_A << K.resource
        self.cant_change_A << K.created_for_collection
        return self
    end
    
    def read( filter_record_TF: true )
        stringer = "#{self.tc_O.rep_O.uri_addr}/#{TOP_CONTAINERS}"
        if ( stringer != self.uri_addr[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a top_container! uri=#{self.uri_addr}"
            raise
        end
        self.record_H = super 
#       SE.q {[ 'self.record_H' ]}
        return self
    end

    def store( )
    #   SE.q {[ 'self.record_H' ]}
        if ( self.tc_O.res_O.nil? ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "self.tc_O.res_O == nil"
            SE.puts "This object was probably created with a 'Repository' Object"
            raise
        end
        if ( ! (  self.record_H[K.type] && self.record_H[K.type] != '' ) ) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a self.record_H[K.type] value";
            SE.puts "self.uri_addr = #{self.uri_addr}"
            SE.q {[ 'self.record_H' ]}
            raise
        end
        if ( ! (  self.record_H[K.indicator] && self.record_H[K.indicator] != UNDEFINED ) ) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "#{SE.lineno}: I was expecting a self.record_H[K.indicator] value";
            SE.puts "self.uri_addr = #{self.uri_addr}"
            SE.q {[ 'self.record_H' ]}
            raise
        end
        if not (    ( self.record_H[ K.collection ].any?{ | collection | collection[ K.ref ] == self.tc_O.res_O.uri_addr  } ) ||
                    ( self.record_H.fetch( K.resource, {} ).fetch( K.ref, '' ) == self.tc_O.res_O.uri_addr )
               ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Top_Container doesn't belong to current Collection."
            SE.puts 'self.record_H[ K.collection ].any?{ | collection | collection[ K.ref ] == self.tc_O.res_O.uri_addr  }'
            SE.puts 'self.record_H.fetch( K.resource, {} ).fetch( K.ref, '' ) == self.tc_O.res_O.uri_addr'
            SE.q {'self.tc_O.res_O.uri_addr'}
            SE.q {'self.record_H[ K.collection ]'}
            SE.q {'self.record_H'}
            raise
        end
        if ( self.uri_addr.nil? ) then
            self.uri_addr = "#{self.tc_O.rep_O.uri_addr}/#{TOP_CONTAINERS}"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created TopContainer, uri = #{http_response_body_H[ K.uri ]}"
            self.uri_addr = http_response_body_H[ K.uri ] 
            self.rec_id = self.uri_addr.trailing_digits
        else
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated top_container, uri = #{http_response_body_H[ K.uri ]}"
        end
        return self
    end
        
    def delete( )
        stringer = "#{self.tc_O.rep_O.uri_addr}/#{TOP_CONTAINERS}"
        if ( stringer != self.uri_addr[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a top_container! uri=#{self.uri_addr}"
            raise
        end
        read()
        
        if ( self.record_H.has_key?( K.resource ) && self.record_H[ K.resource ].has_key?( K.ref )) then
            if ( self.tc_O.res_O.nil? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "self.tc_O.res_O == nil"
                SE.puts "This object was probably created with a 'Repository' Object"
                raise
            end
            if ( self.record_H[ K.resource ][ K.ref ] != self.tc_O.res_O.uri_addr ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Top_Container doesn't belong to current Resource."
                SE.puts "self.record_H[K.resource][K.ref] != self.tc_O.res_O.uri_addr"
                SE.puts "#{self.record_H[K.resource][K.ref]} != #{self.tc_O.res_O.uri_addr}"
                raise
            end
        end
        http_response_body_H = super
        SE.puts "#{SE.lineno}: Deleted top_container, uri = #{http_response_body_H[ K.uri ]}"
        return http_response_body_H
    end    
end

class TC_Query__of_Resource
    attr_accessor :uri_addr,  :tc_display_order_H,  :record_H_A,  :uri_addr_S__BY_type_indicator_CKA,  :ao_data_H_A__BY_tc_rec_id
    private       :uri_addr=, :tc_display_order_H=, :record_H_A=, :uri_addr_S__BY_type_indicator_CKA=, :ao_data_H_A__BY_tc_rec_id=
        
    def initialize( p1_ao_QO )
        if ( p1_ao_QO.is_not_a?( AO_Query__of_Resource ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a 'AO_Query__of_Resource' class object, it's: '#{p1_ao_QO.class}'"
            raise
        end    
        self.uri_addr = "#{p1_ao_QO.res_O.rep_O.uri_addr}/#{TOP_CONTAINERS}"    
        if ( p1_ao_QO.record_H_A.nil? ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "p1_ao_QO.record_H_A is nil, was the get_full_ao_buf boolean set?"
            raise
        end
        self.ao_data_H_A__BY_tc_rec_id = {}
        p1_ao_QO.record_H_A.each_with_index do | ao_record_H, ao_display_order |
            if ( ao_record_H.has_no_key?( K.instances ) ) then
                next
            end
            ao_record_H[ K.instances ].each do | instance |
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
                    SE.q { 'ao_record_H' }
                    raise
                end
                tc_rec_id_I = instance[ K.sub_container ][ K.top_container ][ K.ref ].delete_prefix( "#{self.uri_addr}/" ).to_i
                SE.raise if ( tc_rec_id_I == 0 )
                
                self.ao_data_H_A__BY_tc_rec_id[ tc_rec_id_I ] ||= []
                self.ao_data_H_A__BY_tc_rec_id[ tc_rec_id_I ].push( { K.title           => ao_record_H[ K.title ],
                                                                      :AO_DISPLAY_ORDER => ao_display_order,
                                                                      K.uri             => ao_record_H[ K.uri ],
                                                                      K.ancestors       => ao_record_H[ K.ancestors ],
                                                                      K.level           => ao_record_H[ K.level ],
                                                                      } )
                
            end
        end
        
        #   Make a hash by tc_rec_id_I with the lowest (minimum) :AO_DISPLAY_ORDER value...
        tmp_H = {}
        self.ao_data_H_A__BY_tc_rec_id.each_pair do | tc_rec_id_I, related_ao_H_A |
             tmp_H[ tc_rec_id_I ] = related_ao_H_A.map { | h | h[ :AO_DISPLAY_ORDER ] }.min
        end
        #   Then sort the tmp_H by that lowest value, but sequence the hash 1..N for the actual order.
        self.tc_display_order_H = tmp_H.sort_by { |_, v| v }.each_with_index.to_h { |(k, _), i| [k, i] }
        if ( self.tc_display_order_H.length != self.ao_data_H_A__BY_tc_rec_id.length ) then
             SE.puts "#{SE.lineno}: =============================================="
             SE.puts "self.tc_display_order_H.length != self.ao_data_H_A__BY_tc_rec_id.length"
             SE.q {[ 'self.tc_display_order_H.length', 'self.ao_data_H_A__BY_tc_rec_id.length' ]}
             raise
        end
   
        self.uri_addr_S__BY_type_indicator_CKA = { }
        self.record_H_A = Array.new( self.tc_display_order_H.length )
        p1_ao_QO.res_O.query( TOP_CONTAINERS )
                      .record_H_A__OF_rec_id_A( self.tc_display_order_H.keys.sort )
                      .each do | tc_record_H |
            tc_rec_id_I = tc_record_H[ K.uri ].delete_prefix( "#{self.uri_addr}/" ).to_i
            SE.raise if ( tc_rec_id_I == 0 )
            tc_display_order = self.tc_display_order_H[ tc_rec_id_I ]
            if ( tc_display_order.nil? ) then
                 SE.puts "#{SE.lineno}: =============================================="
                 SE.puts "self.tc_display_order_H[ tc_rec_id_I ] is nil?"
                 SE.q {'tc_record_H[ K.uri ]'}
                 SE.q {'self.tc_display_order_H'}
                 raise
            end 
            if ( self.record_H_A[ tc_display_order ].not_nil? ) then
                 SE.puts "#{SE.lineno}: =============================================="
                 SE.puts "self.record_H_A[ tc_display_order ].not_nil?"
                 SE.q {'tc_record_H'}
                 SE.q {'self.record_H_A[ tc_display_order ]'}
                 SE.q {'self.tc_display_order_H'}
                 raise
            end
            
            type      = tc_record_H.fetch( K.type ).strip.downcase
            indicator = tc_record_H.fetch( K.indicator ).strip.downcase
            type_indicator_A = [ type.freeze, indicator.freeze ].freeze
            self.uri_addr_S__BY_type_indicator_CKA[ type_indicator_A ] ||= Set.new
            self.uri_addr_S__BY_type_indicator_CKA[ type_indicator_A ] << tc_record_H[ K.uri ]                        
            self.record_H_A[ tc_display_order ] = tc_record_H
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
    
    def record_H__OF_uri( p1_tc_uri_addr_OR_rec_id )
        case true
        when p1_tc_uri_addr_OR_rec_id.is_a?( String ) 
            stringer = p1_tc_uri_addr_OR_rec_id.delete_prefix( "#{self.uri_addr}/" )
            if ( stringer.not_integer? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Param 'p1_tc_uri_addr_OR_rec_id' won't convert to an integer."
                if ( p1_tc_uri_addr_OR_rec_id[ 0 ] == '/' ) then
                    SE.puts "It's probably because the URI doesn't start with '#{self.uri_addr}'"
                end
                SE.q {['p1_tc_uri_addr_OR_rec_id','stringer','self.uri_addr']}
                raise
            end
            tc_rec_id_I = stringer.to_i
        when p1_tc_uri_addr_OR_rec_id.integer?
            tc_rec_id_I = p1_tc_uri_addr_OR_rec_id.to_i
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Was expecting param 'p1_tc_uri_addr_OR_rec_id' to be a URI String or integer"
            SE.q {'p1_tc_uri_addr_OR_rec_id'}
            raise
        end
        SE.raise if ( tc_rec_id_I == 0 )
        tc_display_order = self.tc_display_order_H[ tc_rec_id_I ]
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
    
    def ao_data_H_A__OF_tc_uri( p1_tc_uri_addr_OR_rec_id )
    #   NOTE! This is NOT the ao_record_H.   See ao_data_H_A above for the fields.
        case true
        when p1_tc_uri_addr_OR_rec_id.is_a?( String ) 
            stringer = p1_tc_uri_addr_OR_rec_id.delete_prefix( "#{self.uri_addr}/" )
            if ( stringer.not_integer? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Param 'p1_tc_uri_addr_OR_rec_id' won't convert to an integer."
                if ( p1_tc_uri_addr_OR_rec_id[ 0 ] == '/' ) then
                    SE.puts "It's probably because the URI doesn't start with '#{self.uri_addr}'"
                end
                SE.q {['p1_tc_uri_addr_OR_rec_id','stringer','self.uri_addr']}
                raise
            end
            tc_rec_id_I = stringer.to_i
        when p1_tc_uri_addr_OR_rec_id.integer?
            tc_rec_id_I = p1_tc_uri_addr_OR_rec_id.to_i
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Was expecting param 'p1_tc_uri_addr_OR_rec_id' to be a URI String or integer"
            SE.q {'p1_tc_uri_addr_OR_rec_id'}
            raise
        end
        SE.raise if ( tc_rec_id_I == 0 )
        return self.ao_data_H_A__BY_tc_rec_id[ tc_rec_id_I ]
    end 
    
    def uri_addr_A__OF_type_indicator( type:, indicator: )
        return self.uri_addr_S__BY_type_indicator_CKA[ [ type.strip.downcase, indicator.strip.downcase ] ].to_a
    end

end



