
class Resource
=begin
      Resource just holds the resource-number and uri.   
      An object of this is needed to create a Resource_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          resource_buffer_Obj = Resource.new(repository_Obj, resource-num|uri).new_buffer[.read|create]
=end
public  attr_reader :rep_O, :rec_id, :uri_addr
private attr_writer :rep_O, :rec_id, :uri_addr

    def initialize( p1_rep_O, p2_res_identifier = nil )
        if ( p1_rep_O.nil? || p1_rep_O.is_not_a?( Repository ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Repository class object, it's a '#{p1_rep_O.class}'"
            raise
        end    
        self.rep_O = p1_rep_O
        case true
        when p2_res_identifier.nil? 
            self.rec_id = nil
            self.uri_addr = nil
        when p2_res_identifier.integer? 
            self.rec_id = p2_res_identifier
            self.uri_addr = "#{self.rep_O.uri_addr}/#{RESOURCES}/#{self.rec_id}"
        when p2_res_identifier.start_with?( "#{self.rep_O.uri_addr}/#{ARCHIVAL_OBJECTS}" ) 
            self.uri_addr = p2_res_identifier
            self.rec_id = p2_res_identifier.trailing_digits
            if ( ! self.rec_id.integer? ) then
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
    
    def new_buffer
        res_buf_O = Resource_Record_Buf.new( self )
        return res_buf_O
    end
#
#   NOTE!  'what_to_query' is the SUB-object NOT this object.
#          e.g.: Repository -> Resource -> ( Top_Container -or- Archival_Object )
    def query( what_to_query )
        return Repository_Query__for_Resource.new( self.rep_O.aspace_O, 
                                                   self.rep_O, 
                                                   self, 
                                                   what_to_query 
                                                   )
    end
    
    def search( record_type_A: [], search_text:, search_uri: '/search', result_field_A: [] )
        return Repostory_Search__for_Resource.new( self.rep_O.aspace_O,
                                                   self.rep_O, 
                                                   self, 
                                                   record_type_A, 
                                                   search_uri, 
                                                   search_text, 
                                                   result_field_A )
    end
    
    def batch_delete( delete_uri_A )
        return Repository_Batch_delete__for_Resource.new( self.rep_O.aspace_O, 
                                          self.rep_O, 
                                          self, 
                                          delete_uri_A )
    end
    
    def query_search_filter( record_H_A, query_search_uri )
       #SE.q {[ 'self.class', 'record_H_A.class' ]}
        if ( record_H_A.length == 0 ) then
            return record_H_A
        end
        case true
        when self.uri_addr.nil? 
            SE.puts "#{SE.lineno}: ======================================"
            SE.puts "I shouldn't be here, self.uri_addr is nil!"
            raise
        when query_search_uri.start_with?( self.uri_addr )
            SE.puts "#{SE.lineno}: ======================================"
            SE.puts "All of the CHILD records are mine, based on query uri '#{query_search_uri}' starting with '#{self.uri_addr}'"
            return record_H_A
        end
        not_mine_A = []
        mine_A = []
        record_H_A.each do | record_H |
            not_mine = false
#               
            ref = record_H.dig( K.resource, K.ref )            # Archival-Objects
            if ( ref && ref != self.uri_addr ) then
                not_mine = true
            end
            if ( record_H.has_key?( K.collection ) ) then      # Top-Containers
                not_mine = record_H[ K.collection ].none? { | e | e[ K.ref ] == self.uri_addr } 
            end
            if not_mine 
                not_mine_A << record_H
            else
                mine_A << record_H
            end
        end
        SE.puts "#{SE.lineno}: ======================================"
        case true
        when mine_A.length == 0
            SE.puts "None of the #{record_H_A.length} CHILD records are mine, based on PARENT uri '#{self.uri_addr}'."
        when mine_A.length < record_H_A.length
            SE.puts "#{mine_A.length} of #{record_H_A.length} CHILD records are mine, based on PARENT uri '#{self.uri_addr}'."
        else
            SE.puts "All of the CHILD records are mine, based on PARENT uri '#{self.uri_addr}'."
        end
        not_mine_A = nil
        return mine_A
    end 
end

class Resource_Record_Buf < Record_Buf
=begin
      A "CRUD-like" class for the /resources, but (as of 4/19/2020) I don't want anything accidently
      updating a Resource, so the U.D. part are missing.   
      Note that: The 'create' just initializes the buffer, and the Update is called 'store' (so it's IRSD)
=end

public  attr_reader :res_O, :uri_addr, :rec_id, :rec_jsonmodel_type
private attr_writer :res_O, :uri_addr, :rec_id, :rec_jsonmodel_type

    def initialize( p1_res_O )
        if ( not p1_res_O.is_a?( Resource )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Resource class object, it's a '#{p1_res_O.class}'"
            raise
        end 
        self.rec_jsonmodel_type =  K.resource
        self.res_O              = p1_res_O
        self.uri_addr           = p1_res_O.uri_addr
        self.rec_id             = p1_res_O.rec_id
        super( self.res_O.rep_O.aspace_O )
    end
    
    def create
        @record_H.merge!( Record_Format.new( self.rec_jsonmodel_type ).record_H )
        self.cant_change_A << K.level 
        self.cant_change_A << K.resource
        return self
    end

    def load( external_record_H, filter_record_B = true )
        @record_H = super
        # if ( not (@record_H.has_key?( K.resource ) && @record_H[K.resource].has_key?( K.ref ) && 
                  # @record_H[ K.resource ][ K.ref ] == self.ao_O.p1_res_O.uri_addr )) then
            # SE.puts "#{SE.lineno}: =============================================="
            # SE.puts "Archival_object doesn't belong to current Resource."
            # SE.puts "@record_H[K.resource][K.ref] != self.ao_O.p1_res_O.uri_addr"
            # SE.ap "@record_H:", @record_H
            # raise
        # end
        self.cant_change_A << K.level 
        self.cant_change_A << K.resource
        return self
    end
    
    def read( filter_record_B = true )
        @record_H = super( filter_record_B )
#       SE.q { [ '@record_H' ] }
        if ( @record_H.key?( self.rec_jsonmodel_type ) &&  @record_H[ self.rec_jsonmodel_type ].key?( K.ref )) then
            if ( ! ( @record_H[ self.rec_jsonmodel_type ][ K.ref ] == "#{self.uri_addr}" ) ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "uri is not part of resource '#{self.rec_id}'"
                SE.puts "resource => uri = '#{self.uri_addr}'"
                SE.q { [ '@record_H' ] }
                raise
            end
        end
        return self
    end
    
    def store( )
        if ( not (  @record_H[K.title] && @record_H[K.title] != K.undefined )) then 
            SE.puts "#{SE.lineno}: =========================================="
            SE.puts "I was expecting a @record_H[K.title] value";
            SE.ap "@record_H:", @record_H
            raise
        end

        if ( self.uri_addr.nil? ) then
            self.uri_addr = "#{self.res_O.rep_O.uri_addr}/#{RESOURCES}"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created Resource, uri = #{http_response_body_H[ K.uri ]}";
            self.uri_addr = http_response_body_H[ K.uri ] 
            self.rec_id = self.uri_addr.trailing_digits
        else
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated Resource, uri = #{http_response_body_H[ K.uri ]}";
        end
    end
end   

class Repository_Query__for_Resource < ASpace_Query__for_Repository 
    def initialize( aspace_O, rep_O, my_creator_O, what_to_query )
        if ( rep_O.is_not_a?( Repository ) )
            SE.puts "#{SE.lineno}: Was expecting param 'rep_O' to be a Repository not a '#{rep_O.class}'"
            SE.q {[ 'rep_O', 'my_creator_O' ]}
            raise
        end       
        if ( self.uri_addr.nil? ) then
            if ( my_creator_O.is_not_a?( Resource ) )
                SE.puts "#{SE.lineno}: Was expecting param 'my_creator_O' to be a Resource not a '#{my_creator_O.class}'"
                SE.q {[ 'rep_O', 'my_creator_O' ]}
                raise
            end
            self.uri_addr = "#{rep_O.uri_addr}/#{what_to_query}"    # NOTE!!  It should NOT be 'my_creator_O.uri_addr'
                                                                    # because the queries are ONLY 
                                                                    # /what_to_query (for global searches) and
                                                                    # /repository/:repo_id/record_type (for repository searches)
        end
        aspace_O.http_calls_O.get( my_creator_O.uri_addr )
        super       
    end
    def rec_id_A
        return super
    end
    def record_H_A
       #SE.q {['self.aspace_O.class', 'self.my_creator_O.class', 'self.uri_addr']}
        return my_creator_O.query_search_filter( super, self.uri_addr )
    end
    def record_H_A__OF_rec_id_A( rec_id_A )
        return my_creator_O.query_search_filter( super, self.uri_addr )
    end
end

class Repository_Search__for_Resource < ASpace_Search__for_Repository   
    def initialize( aspace_O, rep_O, my_creator_O, record_type_A, search_uri, search_text, result_field_A )
        if ( rep_O.is_not_a?( Repository ) )
            SE.puts "#{SE.lineno}: Was expecting param 'rep_O' to be a Repository not a '#{rep_O.class}'"
            SE.q {[ 'rep_O', 'my_creator_O' ]}
            raise
        end       
        if ( self.uri_addr.nil? ) then
            if ( my_creator_O.is_not_a?( Resource ) )
                SE.puts "#{SE.lineno}: Was expecting param 'my_creator_O' to be a Resource not a '#{my_creator_O.class}'"
                SE.q {[ 'rep_O', 'my_creator_O' ]}
                raise
            end
            self.uri_addr = "#{rep_O.uri_addr}#{search_uri}"
        end
        super
        self.record_H_A = rep_O.query_search_filter( self.record_H_A, self.uri_addr )
        return self
    end
end

class Repository_Batch_delete__for_Resource < ASpace_Batch_delete__for_Repository
    def initialize( aspace_O, rep_O, my_creator_O, delete_uri_A )
        if ( rep_O.is_not_a?( Repository ) )
            SE.puts "#{SE.lineno}: Was expecting param 'rep_O' to be a Repository not a '#{rep_O.class}'"
            SE.q {[ 'rep_O', 'my_creator_O' ]}
            raise
        end

        if ( my_creator_O.is_not_a?( Resource ) )
            SE.puts "#{SE.lineno}: Was expecting param 'my_creator_O' to be a Resource not a '#{my_creator_O.class}'"
            SE.q {[ 'rep_O', 'my_creator_O' ]}
            raise
        end

        aspace_O.http_calls_O.get( res_O.uri_addr )
        delete_uri_A.each_with_idx do | delete_uri, idx |
            next if delete_uri.start_with?( "#{res_O.uri_addr}/" ) 
            SE.put "#{SE.lineno}: Found a delete_uri without a res:id prefix"
            SE.q {['delete_uri', 'idx', 'res_O.uri_addr']}
            raise
        end
        super       
    end
end


 
