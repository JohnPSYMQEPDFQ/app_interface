
class Resource
=begin
      Resource just holds the resource-number and uri.   
      An object of this is needed to create a Resource_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          resource_buffer_Obj = Resource.new(repository_Obj, resource-num|uri).new_buffer[.read|create]
=end
    attr_reader :rep_O, :uri_num, :uri_addr
    def initialize( p1_rep_O, p2_res_identifier = nil )
        if ( p1_rep_O.nil? or p1_rep_O.is_not_a?( Repository ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Repository class object, it's a '#{p1_rep_O.class}'"
            raise
        end    
        @rep_O = p1_rep_O
        case true
        when p2_res_identifier.nil? 
            @uri_num = nil
            @uri_addr = nil
        when p2_res_identifier.integer? 
            @uri_num = p2_res_identifier
            @uri_addr = "#{@rep_O.uri_addr}/#{RESOURCES}/#{@uri_num}"
        when p2_res_identifier.start_with?( "#{@rep_O.uri_addr}/#{ARCHIVAL_OBJECTS}" ) 
            @uri_addr = p2_res_identifier
            @uri_num = p2_res_identifier.trailing_digits
            if ( ! @uri_num.integer? ) then
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
        return Repository_Query__for_Resource.new( self.rep_O.aspace_O, self.rep_O, self, 
                                                   what_to_query 
                                                   )
    end
    
    def search( record_type:, search_text:, search_uri: '/search', result_field_A: [] )
        return Resource_Search.new( self.rep_O.aspace_O, self.rep_O, self, record_type, search_uri, search_text, result_field_A )
    end
    
    def batch_delete( delete_uri_A )
        return Resource_Batch_Delete.new( self.rep_O.aspace_O, self.rep_O, self, delete_uri_A )
    end
    
    def query_search_filter( query_O )
       #SE.q {[ 'self.class']}
        if ( query_O.result_A.length == 0 ) then
            return
        end
        case true
        when @uri_addr.nil? 
            SE.puts "#{SE.lineno}: ======================================"
            SE.puts "I shouldn't be here, @uri_addr is nil!"
            raise
        when query_O.uri_addr.start_with?( @uri_addr )
            SE.puts "#{SE.lineno}: It's all mine (query uri '#{query.uri}' starts with '#{@uri_addr}')"
        else
            not_mine_A = []
            mine_A = []
            query_O.result_A.each do | record_H |
                not_mine = false
                ref = record_H.dig( K.resource, K.ref )
                if ( ref && ref != @uri_addr ) then
                    not_mine = true
                end
                if ( record_H.has_key?( K.collection ) ) then
                    not_mine = record_H[ K.collection ].none? { | e | e[ K.ref ] == @uri_addr } 
                end
                if not_mine 
                    not_mine_A << record_H
                else
                    mine_A << record_H
                end
            end            
            case true
            when mine_A.length == 0
                SE.puts "#{SE.lineno}: None of it's mine (validation uri '#{@uri_addr}')"
            when mine_A.length < query_O.result_A.length
                SE.puts "#{SE.lineno}: #{mine_A.length} of #{query_O.result_A.length} is mine (filtered using '#{@uri_addr}')"
            else
                SE.puts "#{SE.lineno}: All of it's mine (validation uri '#{@uri_addr}')"
            end
            query_O.result_A = mine_A
        end
    end
 
end

class Resource_Record_Buf < Record_Buf
=begin
      A "CRUD-like" class for the /resources, but (as of 4/19/2020) I don't want anything accidently
      updating a Resource, so the U.D. part are missing.   
      Note that: The 'create' just initializes the buffer, and the Update is called 'store' (so it's IRSD)
=end
    def initialize( p1_res_O )
        if ( not p1_res_O.is_a?( Resource )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Resource class object, it's a '#{p1_res_O.class}'"
            raise
        end 
        @rec_jsonmodel_type =  K.resource
        @res_O = p1_res_O
        @uri_addr = @res_O.uri_addr
        @uri_num = @res_O.uri_num
        super( @res_O.rep_O.aspace_O )
    end
    attr_reader :uri_num, :uri_addr, :res_O
    
    def create
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )
        @cant_change_A << K.level 
        @cant_change_A << K.resource
        return self
    end

    def load( external_record_H, filter_record_B = true )
        @record_H = super
        # if ( not (@record_H.has_key?( K.resource ) and @record_H[K.resource].has_key?( K.ref ) and 
                  # @record_H[ K.resource ][ K.ref ] == @ao_O.p1_res_O.uri_addr )) then
            # SE.puts "#{SE.lineno}: =============================================="
            # SE.puts "Archival_object doesn't belong to current Resource."
            # SE.puts "@record_H[K.resource][K.ref] != @ao_O.p1_res_O.uri_addr"
            # SE.ap "@record_H:", @record_H
            # raise
        # end
        @cant_change_A << K.level 
        @cant_change_A << K.resource
        return self
    end
    
    def read( filter_record_B = true )
        @record_H = super( filter_record_B )
#       SE.q { [ '@record_H' ] }
        if ( @record_H.key?( @rec_jsonmodel_type ) and  @record_H[ @rec_jsonmodel_type ].key?( K.ref )) then
            if ( ! ( @record_H[ @rec_jsonmodel_type ][ K.ref ] == "#{@uri_addr}" ) ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "uri is not part of resource '#{@uri_num}'"
                SE.puts "resource => uri = '#{@uri_addr}'"
                SE.q { [ '@record_H' ] }
                raise
            end
        end
        return self
    end
    
    def store( )
        if ( not (  @record_H[K.title] and @record_H[K.title] != K.undefined )) then 
            SE.puts "#{SE.lineno}: =========================================="
            SE.puts "I was expecting a @record_H[K.title] value";
            SE.ap "@record_H:", @record_H
            raise
        end

        if ( @uri_addr.nil? ) then
            @uri_addr = "#{@res_O.rep_O.uri_addr}/#{RESOURCES}"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created Resource, uri = #{http_response_body_H[ K.uri ]}";
        else
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated Resource, uri = #{http_response_body_H[ K.uri ]}";
        end
        @uri_addr = http_response_body_H[ K.uri ] 
        @uri_num = @uri_addr.trailing_digits
    end
end   

class Repository_Query__for_Resource < Repository_Query 
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
    def id_A__all
        super
        return self
    end
    def record_H_A__all
        query_O = super
        my_creator_O.query_search_filter( query_O )
        return self
    end
    def record_H_A__of_id_A( id_A )
        query_O = super
        my_creator_O.query_search_filter( query_O )
        return self
    end
end

class Repository_Search__for_Resource < Repository_Search   
    def initialize( aspace_O, rep_O, my_creator_O, record_type, search_uri, search_text, result_field_A )
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
        search_O = super
        rep_O.query_search_filter( search_O )
        return self
    end
end

class Resource_Batch_Delete < Repository_Batch_Delete
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


 
