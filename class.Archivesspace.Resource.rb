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

class Resource
=begin
      Resource just holds the resource-number and uri.   
      An object of this is needed to create a Resource_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          resource_buffer_Obj = Resource.new(repository_Obj, resource-num|uri).new_buffer[.read|create]
=end
    def initialize( p1_rep_O, p2_res_identifier )
        if ( p1_rep_O.class != Repository ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Repository class object, it's #{p1_rep_O.class}"
            raise
        end    
        @rep_O = p1_rep_O
        if ( p2_res_identifier == nil ) then
            @num = nil
            @uri = nil
        else
            if ( p2_res_identifier.integer? ) then
                @num = p2_res_identifier
                @uri = "#{@rep_O.uri}/resources/#{@num}"
            else
                stringer = "#{@rep_O.uri}/archival_objects"
                if ( stringer == p2_res_identifier[ 0 .. stringer.maxindex ]) then
                    @uri = p2_res_identifier
                    @num = p2_res_identifier.sub( /^.*\//, '' )
                    if (not @num.integer? ) then
                        SE.puts "#{SE.lineno}: =============================================="
                        SE.puts "Invalid param2: #{p2_res_identifier}"
                        raise
                    end
                else
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Invalid param2: #{p2_res_identifier}"
                    raise
                end
            end
        end 
    end
    attr_reader :rep_O, :num, :uri
    
    def new_buffer
        res_buf_O = Resource_Record_Buf.new( self )
        return res_buf_O
    end
 
end

class Resource_Record_Buf < Record_Buf
=begin
      A "CRUD-like" class for the /resources, but (as of 4/19/2020) I don't want anything accidently
      updating a Resource, so the U.D. part are missing.   
      Note that: The 'create' just initializes the buffer, and the Update is called 'store' (so it's IRSD)
=end
    def initialize( res_O )
        if ( res_O.class.name.downcase != K.resource ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Resource class object, it's a #{res_O.class}"
            raise
        end 
        @rec_jsonmodel_type =  K.resource
        @res_O = res_O
        @uri = @res_O.uri
        @num = @res_O.num
        super( @res_O.rep_O.aspace_O )
    end
    attr_reader :num, :uri, :res_O
    
    def create
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )
        return self
    end
    
    def read( filter_record_B = true )
        @record_H = super( filter_record_B )
#       SE.pp "@record_H", @record_H
        if ( @record_H.key?( @rec_jsonmodel_type ) and  @record_H[ @rec_jsonmodel_type ].key?( K.ref )) then
            if ( ! ( @record_H[ @rec_jsonmodel_type ][ K.ref ] == "#{@uri}" ) ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "uri is not part of resource '#{@num}'"
                SE.puts "resource => uri = '#{@uri}'"
                SE.pp "@record_H:", @record_H
                raise
            end
        end
        return self
    end
    
    def store( )
        SE.puts "#{SE.lineno}: =============================================="
        SE.puts "Method not coded"
        raise
    end
end   

class Resource_Query   

    def initialize( res_O, param_get_full_ao_buf = false )
=begin    
        Param2, if true, causes the query to read each AO record.  This is about 30 times slower
        than using the data from the AO indexes, which is a subset of the AO.
=end
        if ( res_O.class.name.downcase != K.resource ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Resource class object, it's a '#{res_O.class}'"
            raise
        end 
        if ( not (param_get_full_ao_buf == true or param_get_full_ao_buf == false )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 2 should be true or false, not '#{param_get_full_ao_buf}'"
            raise
        end 
        @res_O = res_O
        @buf_A = nil
        @get_full_ao_buf = param_get_full_ao_buf    
    end
    attr_reader :buf_A, :res_O

    def get_all_AO( starting_uri = '' )
=begin
        Get all the AO's for the resource building an array of AO_Record_Buf's
        loaded with the subset of AO data contained in the 'tree' records.
        The parameter allows one to start from anyplace on the resource's tree.
=end
        @buf_A = []
        process_each_node( starting_uri )
        return self
    end

    def process_each_node( node_uri )
        if ( node_uri == '' ) then
            waypoint_node_H = @res_O.rep_O.aspace_O.http_calls_O.get( "#{@res_O.uri}/tree/root", { } ) 
        else
            waypoint_node_H = @res_O.rep_O.aspace_O.http_calls_O.get( "#{@res_O.uri}/tree/node", { K.node_uri => node_uri } ) 
        end
#       SE.pp waypoint_node_H
        if ( not ( waypoint_node_H.has_key?( K.precomputed_waypoints ) and
                   waypoint_node_H[ K.precomputed_waypoints ].has_key?( node_uri ) and
                   waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].has_key?( '0' ) and
                   waypoint_node_H.has_key?( K.child_count ) and
                   waypoint_node_H.has_key?( K.waypoints ) and
                   waypoint_node_H.has_key?( K.waypoint_size ) and
                   waypoint_node_H.has_key?( K.uri ) ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Missing expected key"
            SE.pp waypoint_node_H
            raise
        end
        if ( waypoint_node_H[ K.precomputed_waypoints ].keys.length != 1 ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "WARNING: waypoint_node_H[ K.precomputed_waypoints ].keys.length != 1, equals: " +
                    "#{waypoint_node_H[ K.precomputed_waypoints ].keys.length}"
            SE.puts "waypoint_node_H[ K.precomputed_waypoints ].keys:" + waypoint_node_H[ K.precomputed_waypoints ].keys
        end
        if ( waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].keys.length != 1 ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "WARNING: waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].keys.length != 1, equals: " +
                    "#{waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].keys.length}"
            SE.puts "waypoint_node_H[ K.precomputed_waypoints ][ node_uri ].keys:" + waypoint_node_H[ K.precomputed_waypoints ][ '0' ].keys
        end
#       SE.puts "node_uri = #{node_uri}, waypoint_node_H[ K.waypoints ] = #{waypoint_node_H[ K.waypoints ]}"
        waypoint_A = waypoint_node_H[ K.precomputed_waypoints ][ node_uri ] [ '0' ]
        waypoint_num = 0; loop do
#           SE.pp waypoint_A
            waypoint_A.each do | child_H |
                if ( not ( child_H.has_key?( K.child_count ) and
                           child_H.has_key?( K.waypoints ) and
                           child_H.has_key?( K.waypoint_size ) and
                           child_H.has_key?( K.uri ) ) ) then
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Missing expected key: K.uri"
                    SE.pp child_H
                    raise
                end
                child_H[ K.resource ] = { K.ref => @res_O.uri }
                if ( @get_full_ao_buf ) then
                    @buf_A << Archival_Object.new( @res_O, child_H[ K.uri ] ).new_buffer.read
                else
                    @buf_A << Archival_Object.new( @res_O, child_H[ K.uri ] ).new_buffer.load( child_H )
                end
                if ( child_H[ K.child_count ] > 0 ) then
                    process_each_node( child_H[ K.uri ] )
                end
            end 
            waypoint_num += 1
            break if ( waypoint_num >= waypoint_node_H[ K.waypoints ] )
            uri = "#{@res_O.uri}/tree/waypoint"
            if ( node_uri == '' ) then
                waypoint_A = @res_O.rep_O.aspace_O.http_calls_O.get( uri, { K.offset => waypoint_num } )
            else
                waypoint_A = @res_O.rep_O.aspace_O.http_calls_O.get( uri, { K.offset => waypoint_num , K.parent_node => node_uri } )
            end
        end
    end
    private :process_each_node

    def get_all_AO__DEPRECATED
=begin
        Get all the AO's for the resource
        returning an array of AO_Record_Buf's
        Run: rr archivesspace.do_http_call.rb get /repositories/:repo_id/resources/:res_id/tree
            for the format
=end
        uri = "#{@res_O.uri}/tree"
        http_response_body = @res_O.rep_O.aspace_O.http_calls_O.get( uri, { } )
        if ( not ( http_response_body.has_key?( K.id ) and http_response_body[ K.id ] == @res_O.num )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Unable to find Resource Tree for res_num = #{@res_O.num}"
            SE.puts "uri = #{uri}"
            SE.pp "http_response_body", http_response_body
            raise
        end        
#       SE.pp http_response_body
        @buf_A = load_children( http_response_body[ K.children], [] )
    end
    
    def load_children( child_A, result )
        if ( not (child_A.is_a?( Array ))) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Was expecting an Array here..."
            raise
        end
        child_A.each do | e |
            if ( e.is_a?( Hash )) then
                if ( not (e.has_key?( K.node_type ) and e[ K.node_type ] == K.archival_object )) then
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Was expecting an archival_object here, not k = #{k} and v = #{v}"
                    raise
                end
                result << Archival_Object.new( @res_O, e[ K.record_uri ]).new_buffer.read
                if ( e.has_key?( K.children ) and e[ K.children] != [] ) then
                    load_children( e[ K.children ], result )
                end
            else
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Was expecting a Hash here..."
                raise
            end
        end
        return result
    end
    private :load_children
end
 
