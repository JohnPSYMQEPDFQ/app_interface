
class Archival_Object
=begin
      Archival_Object just holds the AO-number and uri.   
      An object of this is needed to create a AO_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          ao_buffer_Obj = Archival_Object.new(resource_Obj, ao-num|uri).new_buffer[.read|create]
=end
    attr_reader :res_O, :uri_num, :uri_addr
    
    def initialize( p1_res_O, p2_AO_identifier = nil )
        case true
        when p1_res_O.is_a?( Resource_Record_Buf )
            @res_O = p1_res_O.res_O
        when p1_res_O.is_a?( Resource )
            @res_O = p1_res_O
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Resource or Resource_Record_Buf class object, it's: '#{p1_res_O.class}'"
            raise
        end    

        case true
        when p2_AO_identifier.nil?  
            @uri_num = nil
            @uri_addr = nil        
        when p2_AO_identifier.integer?  then
            @uri_num = p2_AO_identifier
            @uri_addr = "#{@res_O.rep_O.uri_addr}/#{ARCHIVAL_OBJECTS}/#{@uri_num}"
        when p2_AO_identifier.start_with?( "#{@res_O.rep_O.uri_addr}/#{ARCHIVAL_OBJECTS}" )
            @uri_addr = p2_AO_identifier
            @uri_num = p2_AO_identifier.trailing_digits
            if (! @uri_num.integer? ) then
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
    
    def new_buffer
        ao_buf_O = AO_Record_Buf.new( self )
        return ao_buf_O
    end
end

class AO_Record_Buf < Record_Buf       
=begin
      A "CRUD-like" class for the /ARCHIVAL_OBJECTS. 
      Note that: The 'create' just initializes the buffer, and the Update is called 'store' (so it's IRSD)
      There's also a 'load' method which allows external data to be loaded into the buffer.
=end
    attr_reader :ao_O, :uri_num, :uri_addr
    
    def initialize( p1_ao_O )
        if ( not p1_ao_O.is_a?( Archival_Object )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Archival_Class object, it's: '#{p1_ao_O.class}'"
            raise
        end    
        @rec_jsonmodel_type =  K.archival_object
        @ao_O = p1_ao_O
        @uri_addr = @ao_O.uri_addr
        @uri_num = @ao_O.uri_num
        super( @ao_O.res_O.rep_O.aspace_O )
    end
    
    def create( p1_level )
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )  
        @record_H[ K.level ] = p1_level
        @record_H[ K.resource ][ K.ref ] = @ao_O.res_O.uri_addr
        @cant_change_A << K.level 
        @cant_change_A << K.resource
        return self
    end

    def load( external_record_H, filter_record_B = true )
        @record_H = super
        if ( not (@record_H.has_key?( K.resource ) and @record_H[K.resource].has_key?( K.ref ) and 
                  @record_H[ K.resource ][ K.ref ] == @ao_O.res_O.uri_addr )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Archival_object doesn't belong to current Resource."
            SE.puts "@record_H[K.resource][K.ref] != @ao_O.res_O.uri_addr"
            SE.ap "@record_H:", @record_H
            raise
        end
        @cant_change_A << K.level 
        @cant_change_A << K.resource
        return self
    end
    
    def read( filter_record_B = true )
        stringer = "#{@ao_O.res_O.rep_O.uri_addr}/#{ARCHIVAL_OBJECTS}"
        if ( stringer != self.uri_addr[ 0 .. stringer.maxindex ]) then 
            SE.puts "#{SE.lineno}: =============================================="     
            SE.puts "uri isn't a archival_object! uri=#{@uri_addr}"
            raise
        end
        @record_H = super( filter_record_B )
#       SE.ap "#{SE.lineno}: @record_H:", @record_H
        if ( @record_H[K.resource][K.ref] != @ao_O.res_O.uri_addr ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Archival_object doesn't belong to current Resource."
            SE.puts "@record_H[K.resource][K.ref] != @ao_O.res_O.uri_addr"
            SE.puts "#{@record_H[K.resource][K.ref]} != #{@ao_O.res_O.uri_addr}"
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
                if ( ! (  @record_H[K.parent][K.ref].match?( %r"^#{@ao_O.res_O.rep_O.uri_addr}/(#{ARCHIVAL_OBJECTS}|#{RESOURCES})" ) or
                       (  @record_H[K.parent][K.ref] == "NO UPDATE MODE" and ! @ao_O.res_O.rep_O.aspace_O.allow_updates )))
                    SE.puts "#{SE.lineno}: =========================================="
                    SE.puts "@record_H[K.parent][K.ref]: '#{@ao_O.res_O.rep_O.uri_addr}/(#{ARCHIVAL_OBJECTS}|#{RESOURCES})'"
                    SE.puts "@record_H[K.parent][K.ref]: '#{@record_H[K.parent][K.ref]}'"
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
        if ( @record_H[K.resource][K.ref] != @ao_O.res_O.uri_addr ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Archival_object doesn't belong to current Resource."
            SE.puts "@record_H[K.resource][K.ref] != @ao_O.res_O.uri_addr"
            SE.puts "#{@record_H[K.resource][K.ref]} != #{@ao_O.res_O.uri_addr}"
            raise
        end

        if ( @uri_addr.nil? ) then
            @uri_addr = "#{@ao_O.res_O.rep_O.uri_addr}/#{ARCHIVAL_OBJECTS}"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created ArchivalObject, uri = #{http_response_body_H[ K.uri ]}";
        else
#           SE.puts "#{SE.lineno}: I shouldn't be updating an ArchivalObject"
#           raise
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated ArchivalObject, uri = #{http_response_body_H[ K.uri ]}";
        end
        @uri_addr = http_response_body_H[ K.uri ] 
        @uri_num = @uri_addr.trailing_digits
        return self
    end
end    


class AO_Query_of_Resource
    public  attr_reader :res_O, :uri_addr, :index_H_A, :ao_display_order_H                 
    private attr_writer :res_O, :uri_addr, :index_H_A, :ao_display_order_H, :record_H_A
    
    def initialize( resource_O:, 
                    get_full_ao_record_TF: false, 
                    starting_node_uri: '', 
                    recurse_index_children_TF: true 
                   )
        if ( resource_O.is_not_a?( Resource ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Resource class object, it's: '#{res_O.class}'"
            raise
        end    
        self.res_O              = resource_O
        self.uri_addr           = "#{self.res_O.rep_O.uri_addr}/#{ARCHIVAL_OBJECTS}"
        self.index_H_A          = nil
        self.ao_display_order_H = nil
        self.record_H_A         = nil
=begin    
        Param 'get_full_ao_record_TF', if true, causes the query to read each AO record.  
        This is about 10 times slowerthan using the data from the AO indexes, which is a subset of the AO.
=end
        if ( get_full_ao_record_TF.not_in?( true, false )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 2 should be true or false, not '#{get_full_ao_record_TF}'"
            raise
        end 
      # if ( get_full_ao_record_TF ) then
      #     SE.puts "'AO_Query_of_Resource' fetching full AO-Record data."
      # else
      #     SE.puts "'AO_Query_of_Resource' fetching index data ONLY!"
      # end

        if ( recurse_index_children_TF.not_in?( true, false )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 4 should be true or false, not '#{recurse_index_children_TF}'"
            raise
        end         

=begin
        Get all the AO's for the resource, building an array of index_H,
        loaded with the subset of AO data contained in the 'tree' records.
        The 'starting_node_uri' parameter allows one to start from anyplace on the resource's tree.
        For example, from a specific "Series" record, using the series' URL
        would return all the children of the series. A 'blank' mean all the 1st level records (the
        children of the Resource record).  The 'recurse_index_children_TF' boolean determines 
        whether the records with children will be recursed. Basically, if 'false' only the records
        of a particular level will be fetched.
=end
        self.index_H_A = []
        self.ao_display_order_H = {}     # Hash of ao_uri_num's with associated index_H_A index number
        process_each_node( starting_node_uri, recurse_index_children_TF )
        self.index_H_A.each_with_index do | index_H, ao_display_order |
            ao_uri_num = index_H[ K.uri ].delete_prefix( "#{self.uri_addr}/" ).to_i
            raise 'ao_uri_num == 0' if ( ao_uri_num == 0 )
            self.ao_display_order_H[ ao_uri_num ] = ao_display_order
        end

        if ( get_full_ao_record_TF ) then
            self.record_H_A = Array.new( self.ao_display_order_H.length )

            self.res_O.rep_O.query( ARCHIVAL_OBJECTS ).record_H_A__of_id_A( self.ao_display_order_H.keys.sort )
                                                      .result_A.each do | record_H |
                if ( record_H.has_no_key?( K.resource ) ) then
                     SE.puts "#{SE.lineno}: =============================================="
                     SE.puts "AO record missing '#{K.resource}' key"
                     SE.q {'record_H'}
                     raise
                end
                if ( record_H[ K.resource ].has_no_key?( K.ref ) ) then
                     SE.puts "#{SE.lineno}: =============================================="
                     SE.puts "AO record missing ['#{K.resource}'] => '#{K.ref}' key"
                     SE.q {'record_H'}
                     raise
                end
                if ( record_H[ K.resource ][ K.ref ] != self.res_O.uri_addr ) then
                     SE.puts "#{SE.lineno}: =============================================="
                     SE.puts "AO record[ '#{K.resource}' ][ '#{K.ref}' ] != self.res_O.uri_addr"   
                     SE.puts "AO record isn't part of resource #{self.res_O.uri_num}"
                     SE.q {'self.res_O.uri_addr'}
                     SE.q {'record_H[ K.resource ][ K.ref ]'}
                     SE.q {'record_H'}
                     raise
                end
#               'rep_O.query( ARCHIVAL_OBJECTS )' returns the records in URI order.  They've got to be in index order, which is
#               the order they are exported and displayed in.   The following code builds record_H_A in the same order
#               ao_display_order_H.keys.
                
                if ( record_H.has_no_key?( K.uri ) ) then
                     SE.puts "#{SE.lineno}: =============================================="
                     SE.puts "AO record missing '#{K.uri}' key"
                     SE.q {'record_H'}
                     raise
                end
                ao_uri_num = record_H[ K.uri ].delete_prefix( "#{self.uri_addr}/" ).to_i
                raise 'ao_uri_num == 0' if ( ao_uri_num == 0 )
                ao_display_order = self.ao_display_order_H[ ao_uri_num ]
                if ( ao_display_order.nil? ) then
                     SE.puts "#{SE.lineno}: =============================================="
                     SE.puts "self.ao_display_order_H[ ao_uri_num ] is nil?"
                     SE.q {'record_H[ K.uri ]'}
                     SE.q {'self.ao_display_order_H'}
                     raise
                end 
                if ( self.record_H_A[ ao_display_order ].not_nil? ) then
                     SE.puts "#{SE.lineno}: =============================================="
                     SE.puts "self.record_H_A[ ao_display_order ].not_nil?"
                     SE.q {'record_H'}
                     SE.q {'self.record_H_A[ ao_display_order ]'}
                     SE.q {'self.ao_display_order_H'}
                     raise
                end 
                self.record_H_A[ ao_display_order ] = record_H
            end     
            if ( self.record_H_A.length != self.ao_display_order_H.keys.length ) then
                 SE.puts "#{SE.lineno}: =============================================="
                 SE.puts "self.record_H_A.length != self.ao_display_order_H.keys.length"
                 SE.q {[ 'self.record_H_A.length', 'self.ao_display_order_H.keys.length' ]}
                 raise
            end 
            if ( self.record_H_A.include?( nil ) ) then
                 SE.puts "#{SE.lineno}: =============================================="
                 SE.puts "self.record_H_A.include?( nil )"
                 raise
            end                  
        end
        return self
    end   
    
    def record_H_A( index_ok_TF: false )
#            @record_H_A must be used in here because 'self.record_H_A' is this method.  
        if ( index_ok_TF.not_in?( true, false ) ) then
            SE.puts "#{SE.lineno}: Was expecting param-1 'index_ok_TF:' to be T/F, not '#{index_ok_TF}'!"
            raise
        end
        if ( @record_H_A.nil? ) then 
            if ( index_ok_TF ) then
                return self.index_H_A
            else
                SE.puts "#{SE.lineno}: @record_H_A.nil? and 'index_ok_TF' == false"
                SE.puts "Either set 'get_full_ao_record_TF' of the query to 'true',"
                SE.puts "or specify 'record_H_A( index_ok_TF: true )'"
                raise
            end
        end
        return @record_H_A
    end
    
    def record_H__of_uri( p1_ao_uri_addr_OR_id_num )
        return self.record_H_A[ ao_display_order( p1_ao_uri_addr_OR_id_num ) ]
    end   

    def index_H__of_uri( p1_ao_uri_addr_OR_id_num )
        return self.index_H_A[ ao_display_order( p1_ao_uri_addr_OR_id_num ) ]
    end   
    
    def ao_display_order( p1_ao_uri_addr_OR_id_num )
        case true
        when p1_ao_uri_addr_OR_id_num.is_a?( String ) 
            stringer = p1_ao_uri_addr_OR_id_num.delete_prefix( "#{self.uri_addr}/" )
            if ( stringer.not_integer? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Param 'p1_ao_uri_addr_OR_id_num' won't convert to an integer."
                if ( p1_ao_uri_addr_OR_id_num[ 0 ] == '/' ) then
                    SE.puts "It's probably because the URI doesn't start with '#{self.uri_addr}'"
                end
                SE.q {['p1_ao_uri_addr_OR_id_num','stringer','self.uri_addr']}
                raise
            end
            ao_uri_num = stringer.to_i
        when p1_ao_uri_addr_OR_id_num.integer?
            ao_uri_num = p1_ao_uri_addr_OR_id_num.to_i
        else
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Was expecting param 'p1_ao_uri_addr_OR_id_num' to be a URI String or integer"
            SE.q {'p1_ao_uri_addr_OR_id_num'}
            raise
        end
        raise 'ao_uri_num == 0' if ( ao_uri_num == 0 )
        if ( self.ao_display_order_H.has_no_key?( ao_uri_num ) ) then
            SE.puts "#{SE.lineno}: No ao_uri_num '#{ao_uri_num}' in resource"
            raise
        end
        return self.ao_display_order_H[ ao_uri_num ] 
    end
  
    def process_each_node( node_uri, recurse_index_children = true )
        if ( node_uri == '' ) then
            waypoint_node_H = self.res_O.rep_O.aspace_O.http_calls_O.get( "#{self.res_O.uri_addr}/tree/root", { } ) 
            if (  waypoint_node_H.has_key?( K.precomputed_waypoints ) and
                  waypoint_node_H[ K.precomputed_waypoints ] == {} ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "#{SE.lineno}: No AO records found"
                SE.puts "#{SE.lineno}: =============================================="
                return
            end
        else
            waypoint_node_H = self.res_O.rep_O.aspace_O.http_calls_O.get( "#{self.res_O.uri_addr}/tree/node", { K.node_uri => node_uri } ) 
        end
#       SE.q { [ 'waypoint_node_H' ] }
        if ( not ( waypoint_node_H.has_key?( K.precomputed_waypoints ) and
                   waypoint_node_H[ K.precomputed_waypoints ].has_key?( node_uri ) and
                   waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].has_key?( '0' ) and
                   waypoint_node_H.has_key?( K.child_count ) and
                   waypoint_node_H.has_key?( K.waypoints ) and
                   waypoint_node_H.has_key?( K.waypoint_size ) and
                   waypoint_node_H.has_key?( K.uri ) ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Missing expected key"
            SE.q { [ 'waypoint_node_H' ] }
            raise
        end
        if ( waypoint_node_H[ K.precomputed_waypoints ].keys.length != 1 ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "ERROR: waypoint_node_H[ K.precomputed_waypoints ].keys.length != 1, equals: " +
                    "#{waypoint_node_H[ K.precomputed_waypoints ].keys.length}"
            SE.puts "waypoint_node_H[ K.precomputed_waypoints ].keys:" + waypoint_node_H[ K.precomputed_waypoints ].keys
            raise
        end
        if ( waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].keys.length != 1 ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "ERROR: waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].keys.length != 1, equals: " +
                    "#{waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].keys.length}"
            SE.puts "waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].keys:" + waypoint_node_H[ K.precomputed_waypoints ][ '0' ].keys
            raise
        end
#       SE.puts "node_uri = #{node_uri}, waypoint_node_H[ K.waypoints ] = #{waypoint_node_H[ K.waypoints ]}"
        waypoint_A = waypoint_node_H[ K.precomputed_waypoints ][ node_uri ] [ '0' ]
        waypoint_num = 0; loop do
#           SE.q { [ 'waypoint_A' ] }
            waypoint_A.each do | child_H |
                if ( not ( child_H.has_key?( K.child_count ) and
                           child_H.has_key?( K.waypoints ) and
                           child_H.has_key?( K.waypoint_size ) and
                           child_H.has_key?( K.uri ) ) ) then
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Missing expected key: K.uri"
                    SE.q { [ 'child_H' ] } 
                    raise
                end
                child_H[ K.resource ] = { K.ref => self.res_O.uri_addr }
                self.index_H_A << child_H
                if ( child_H[ K.child_count ] > 0 and recurse_index_children ) then
                    process_each_node( child_H[ K.uri ], recurse_index_children )
                end
            end 
            waypoint_num += 1
            break if ( waypoint_num >= waypoint_node_H[ K.waypoints ] )
            uri = "#{self.res_O.uri_addr}/tree/waypoint"
            if ( node_uri == '' ) then
                waypoint_A = self.res_O.rep_O.aspace_O.http_calls_O.get( uri, { K.offset => waypoint_num } )
            else
                waypoint_A = self.res_O.rep_O.aspace_O.http_calls_O.get( uri, { K.offset => waypoint_num , K.parent_node => node_uri } )
            end
        end
    end
    private :process_each_node

end
