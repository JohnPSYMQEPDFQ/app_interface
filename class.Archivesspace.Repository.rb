
class Repository
    attr_reader         :aspace_O, :uri_id_num, :uri_addr
    private attr_writer :aspace_O, :uri_id_num, :uri_addr
    
    def initialize( p1_aspace_O, p2_rep_num )
        if ( not p1_aspace_O.is_a?( ASpace ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a ASpace class object, it's a '#{p1_aspace_O.class}'"
            raise
        end    
        if ( ! p1_aspace_O.session or p1_aspace_O.session == K.undefined ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "aspace_O.session undefined."
            SE.q {[ 'p1_aspace_O' ]}
            raise
        end
        @aspace_O = p1_aspace_O
        @uri_id_num      = p2_rep_num
        @uri_addr      = "/#{REPOSITORIES}/#{@uri_id_num}"
#       SE.puts "#{SE.lineno}: ================ In Repository:initialize,@uri_id_num=#{@uri_id_num}"
    end
#
#   NOTE!  'what_to_query' is the SUB-object NOT this object.
#          e.g.: Repository -> Resource -> ( Top_Container -or- Archival_Object )    
    def query( what_to_query )
        return Repository_Query.new( self.aspace_O, self, self, what_to_query )
    end
    
    def search( record_type:, search_text:, search_uri: '/search' )
        return Repository_Search.new( self.aspace_O, self, self, record_type, search_uri )
                                .record_H_A__having_the_text( search_text )
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
            SE.puts "#{SE.lineno}: It's all mine (query uri '#{query_O.uri_addr}' starts with '#{@uri_addr}')"
        else
            not_mine_A = []
            mine_A = []
            query_O.result_A.each do | record_H |
                not_mine = false
                ref = record_H.dig( K.repository, K.ref )
                if ( ref && ref != @uri_addr ) then
                    not_mine = true
                end
                ref = record_H.dig( K.owner_repo, K.ref )
                if ( ref && ref != @uri_addr ) then
                    not_mine = true
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


class Repository_Query < ASpace_Query 
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
            The Locations are stored a the root level, so have to be queried as '/locations',
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
    def id_A__all
        super
        return self
    end
    def record_H_A__all
        query_O = super
        rep_O.query_search_filter( query_O )
        return self
    end
    def record_H_A__of_id_A( id_A )
        query_O = super
        rep_O.query_search_filter( query_O )
        return self
    end
        
end

class Repository_Search < ASpace_Search   
    def initialize( aspace_O, rep_O, my_creator_O, record_type, search_uri = '/search' )
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
            self.uri_addr = "#{rep_O.uri_addr}#{search_uri}"
        end
        super
    end
    def record_H_A__having_the_text( search_text )
        search_O = super
        rep_O.query_search_filter( search_O )
        return self
    end
end


