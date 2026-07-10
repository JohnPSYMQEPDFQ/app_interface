
class Repository
public  attr_reader :aspace_O, :rec_id, :uri_addr
private attr_writer :aspace_O, :rec_id, :uri_addr
    
    def initialize( p1_aspace_O, p2_rep_rec_id )
        if ( not p1_aspace_O.is_a?( ASpace ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a ASpace class object, it's a '#{p1_aspace_O.class}'"
            raise
        end    
        if ( ! p1_aspace_O.session || p1_aspace_O.session == UNDEFINED ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "aspace_O.session undefined."
            SE.q {[ 'p1_aspace_O' ]}
            raise
        end
        self.aspace_O = p1_aspace_O
        self.rec_id   = p2_rep_rec_id
        self.uri_addr = "/#{REPOSITORIES}/#{self.rec_id}"
#       SE.puts "#{SE.lineno}: ================ In Repository:initialize,self.rec_id=#{self.rec_id}"
    end
#
#   NOTE!  'what_to_query' is the SUB-object NOT this object.
#          e.g.: Repository -> Resource -> ( Top_Container -or- Archival_Object )    
    def query( what_to_query )
        return ASpace_Query__for_Repository.new( self.aspace_O, 
                                                 self, 
                                                 self, 
                                                 what_to_query )
    end
    
    def search( record_type_A: [], search_text:, search_uri: '/search', result_field_A: [] )
        return ASpace_Search__for_Repository.new( self.aspace_O, 
                                                  self, 
                                                  self, 
                                                  record_type_A, 
                                                  search_uri, 
                                                  search_text, 
                                                  result_field_A )
    end
    
    def batch_delete( delete_uri_A )
        return ASpace_Batch_delete__for_Repository.new( self.aspace_O, 
                                                        self, 
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
            ref = record_H.dig( K.repository, K.ref )     # Repository
            if ( ref && ref != self.uri_addr ) then
                not_mine = true
            end
            ref = record_H.dig( K.owner_repo, K.ref )     # Top-Container
            if ( ref && ref != self.uri_addr ) then
                not_mine = true
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


class ASpace_Query__for_Repository < ASpace_Query 
    def initialize( aspace_O, rep_O, my_creator_O, what_to_query )
#           In this class rep_O and my_creator_O are the same, others they will be different
        if ( rep_O.is_not_a?( Repository ) )
            SE.puts "#{SE.lineno}: Was expecting param 'rep_O' to be a Repository not a '#{rep_O.class}'"
            SE.q {[ 'rep_O', 'my_creator_O' ]}
            raise
        end
        if ( self.uri_addr.nil? ) then
            if ( my_creator_O.is_not_a?( Repository ) )
                SE.puts "#{SE.lineno}: Was expecting param 'my_creator_O' to be a Repository not a '#{my_creator_O.class}'"
                SE.q {[ 'rep_O', 'my_creator_O' ]}
                raise
            end
=begin
            The Locations are stored at the root level, so have to be queried as '/locations',
            but there's a field called "owner_repo" which is the Repository that owns the 
            location.  Not sure why it's handled like this, instead of with the usual
            'repository' => 'ref' way, but in order to filter on "owner_repo" the following
            code simulates a '/repository/:repo_id/locations' query when it runs through the 
            'query_search_filter' method.  
=end
            if ( what_to_query.in?( [ LOCATIONS ] ) ) 
                self.uri_addr = "/#{what_to_query}"
            else
                self.uri_addr = "#{rep_O.uri_addr}/#{what_to_query}"
            end
        end
        aspace_O.http_calls_O.get( rep_O.uri_addr )
        super       
    end
    def rec_id_A
        return super
    end
    def record_H_A
       #SE.q {['self.aspace_O.class', 'self.my_creator_O.class', 'self.uri_addr']}
        return rep_O.query_search_filter( super, self.uri_addr )
    end
    def record_H_A__OF_rec_id_A( rec_id_A )
        return rep_O.query_search_filter( super, self.uri_addr )
    end
        
end

class ASpace_Search__for_Repository < ASpace_Search   
    def initialize( aspace_O, rep_O, my_creator_O, record_type_A, search_uri, search_text, result_field_A )
#           In this class rep_O and my_creator_O are the same, others they will be different
        if ( rep_O.is_not_a?( Repository ) )
            SE.puts "#{SE.lineno}: Was expecting param 'rep_O' to be a Repository not a '#{rep_O.class}'"
            SE.q {[ 'rep_O', 'my_creator_O' ]}
            raise
        end
        if ( self.uri_addr.nil? ) then
            if ( my_creator_O.is_not_a?( Repository ) )
                SE.puts "#{SE.lineno}: Was expecting param 'my_creator_O' to be a Repository not a '#{my_creator_O.class}'"
                SE.q {[ 'self.rep_O', 'my_creator_O' ]}
                raise
            end
            self.uri_addr = "#{rep_O.uri_addr}#{search_uri}"
        end
        super
        self.record_H_A = rep_O.query_search_filter( self.record_H_A, self.uri_addr ) 
        return self
    end
end

class ASpace_Batch_delete__for_Repository < ASpace_Batch_delete
    def initialize( aspace_O, rep_O, my_creator_O, delete_uri_A )
#           In this class rep_O and my_creator_O are the same, others they will be different
        if ( rep_O.is_not_a?( Repository ) )
            SE.puts "#{SE.lineno}: Was expecting param 'rep_O' to be a Repository not a '#{rep_O.class}'"
            SE.q {[ 'rep_O', 'my_creator_O' ]}
            raise
        end
        aspace_O.http_calls_O.get( rep_O.uri_addr )
        delete_uri_A.each_with_index do | delete_uri, idx |
            next if delete_uri.start_with?( "#{rep_O.uri_addr}/" ) 
            SE.put "#{SE.lineno}: Found a delete_uri without a repo:id prefix"
            SE.q {['delete_uri', 'idx', 'rep_O.uri_addr']}
            raise
        end
        super       
    end
end



