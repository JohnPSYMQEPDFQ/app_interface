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
        _TF = True/False (Boolean)
        _TF = True/False (Boolean)
        __ = reads as: 'of'

=end

require 'requires.common.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.Buffer_Base.rb'
require 'class.ArchivesSpace.Record_Buf.rb'
require 'class.Archivesspace.Record_Format.rb'


class ASpace
    public  attr_reader :allow_updates, :api_uri_base, :session, :http_calls_O, :date_expression_format, :date_expression_separator
    public  attr_writer :allow_updates
    private attr_writer                 :api_uri_base, :session, :http_calls_O 
    
    def initialize( )
        env_var_aspace_uri_base        = 'ASPACE_URI_BASE'
        env_var_aspace_user            = 'ASPACE_USER'
        self.allow_updates             = false
        self.session                   = 'NEVER_LOGGED_IN! SEE:class.Archivespace.rb'
        self.api_uri_base              = nil
        self.http_calls_O              = 'NEVER_LOGGED_IN! SEE:class.Archivespace.rb'
        self.date_expression_format    = 'aspace_default'      # The default is the yyyyDmmDdd format.   or :mmmddyyyy = MMM. nn, yyyy
        self.date_expression_separator = ' - '
        if ( ENV.has_key?( env_var_aspace_uri_base ) && ENV[ env_var_aspace_uri_base ].not_blank? ) then
            if ( ENV.has_key?( env_var_aspace_user ) && ENV[ env_var_aspace_user ].not_blank? ) then
                self.api_uri_base = ENV[ env_var_aspace_uri_base ]
                login_using_env_vars( ENV[ env_var_aspace_user ] )
            else
                SE.puts "#{SE.lineno}: ENV[ '#{env_var_aspace_uri_base}' ] is set, but ENV[ '#{env_var_aspace_user}' ] isn't."
                raise
            end
        else
            if ( ENV.has_key?( env_var_aspace_user ) && ENV[ env_var_aspace_user ].blank? ) then
                SE.puts "#{SE.lineno}: ENV[ '#{env_var_aspace_user}' ] is set, but ENV[ '#{env_var_aspace_uri_base}' ] isn't."
                raise
            else
#               SE.puts "#{SE.lineno}: No database login as ENV[ '#{env_var_aspace_user}' ] and ENV[ '#{env_var_aspace_uri_base}' ] aren't set."
            end
        end
#       SE.puts "================ In Aspace:initialize self.session=#{self.session}"
    end       
    
    def login_using_env_vars( p1_user )
        if ( self.api_uri_base == nil ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "self.api_uri_base isn't set."
            raise 
        end
      
        userid, password = p1_user.split(':')
        if ( password.nil? ) then
            SE.puts  "(After entering the password: if there's no LF immediately after hitting <enter>, try a new window...)"
            SE.print "Enter password:"
            password = STDIN.noecho(&:gets).chomp   # If the 'gets' stops working from the cygwin command line
#           password = STDIN.gets.chomp             # open a new window.  It does that sometimes.
            SE.puts ''                              # Maybe something is closing STDIN?  
            if ( password.blank? ) then
                SE.puts "#{SE.lineno}: No password entered."
                exit
            end
        end

        self.http_calls_O = Http_Calls.new( self )
        self.session = nil
        uri = "/users/#{userid}/login"
        http_response_body_H = self.http_calls_O.post_with_params( uri, { K.password => password } )
        self.session = http_response_body_H[ K.session ]
        if ( self.session.nil? ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Login failed, no session variable returned"
            SE.q {'http_response_body_H'}
            raise
        end        
    #   SE.puts "session = #{self.session}"
        return http_response_body_H
    end
    
    def date_expression_format=( date_format )
        if ( date_format.not_in?( [ 'aspace_default', 'mmmddyyyy' ] ) ) then
            SE.puts "#{SE.lineno}: Invalid date_format '#{date_format}', was expecting 'aspace_default' or 'mmmddyyyy'"
            SE.q {[ 'date_format' ]}
            raise
        end
        @date_expression_format = date_format   #  <<<  THIS NEEDS TO BE @
    end

    def date_expression_separator=( date_separator )
        if ( date_separator.not_in?( [ ' - ', '-' ] ) ) then
            SE.puts "#{SE.lineno}: Invalid date_separator '#{date_separator}', was expecting ' - ' or '-'"
            SE.q {[ 'date_separator' ]}
            raise
        end
        @date_expression_separator = date_separator    #  <<<  THIS NEEDS TO BE @
    end
    
    def format_date( yyyyDmmDdd ) 
        return yyyyDmmDdd.dup if ( self.date_expression_format == 'aspace_default' )
        short_month = [ 'Jan.', 'Feb.', 'Mar.', 'Apr.', 'May.', 'Jun.', 'Jul.', 'Aug.', 'Sep.', 'Oct.', 'Nov.', 'Dec.' ]
        
        date_formatted = +''    # If strings are concatted with '<<' the variable must be mutable (changable), 
                                # which is what the '+' sign before the literal means.  Otherwise the literal is 
                                # frozen.
        if ( yyyyDmmDdd.maxoffset >= 5 ) then
            if ( yyyyDmmDdd[ 4, 1 ] != '-' ) then
                SE.puts "#{SE.lineno}: Bad date '#{yyyyDmmDdd}', no dash at offset 4"
                SE.q {[ 'yyyyDmmDdd' ]}
                raise
            end
            stringer = yyyyDmmDdd[ 5, 2 ]
            if ( stringer.length == 2 && stringer.between?( '01', '12' ) && stringer.to_i.between?( 1, 12 ) ) then
                date_formatted << short_month[ stringer.to_i - 1 ] + ' '
            else
                SE.puts "#{SE.lineno}: Bad month '#{stringer}'"
                SE.q {[ 'yyyyDmmDdd' ]}
                raise
            end
            if ( yyyyDmmDdd.maxoffset >= 8 ) then
                if ( yyyyDmmDdd[ 7, 1 ] != '-' ) then
                    SE.puts "#{SE.lineno}: Bad date '#{yyyyDmmDdd}', no dash at offset 7"
                    SE.q {[ 'yyyyDmmDdd' ]}
                    raise
                end
                stringer = yyyyDmmDdd[ 8, 2 ]
                if    ( stringer.length == 2 && stringer.between?( '01', '09' ) && stringer.to_i.between?(  1,  9 ) ) then
                    date_formatted << stringer[ 1, 1 ] + ', '
                elsif ( stringer.length == 2 && stringer.between?( '10', '31' ) && stringer.to_i.between?( 10, 31 ) ) then
                    date_formatted << stringer + ', '
                else
                    SE.puts "#{SE.lineno}: Bad day '#{stringer}'"
                    SE.q {[ 'yyyyDmmDdd' ]}
                    raise
                end
            end
        end
        stringer = yyyyDmmDdd[ 0, 4 ]
        if ( stringer.length == 4 && stringer.to_i.between?( 1000, 2200 ) ) then
            date_formatted << stringer
        else
            SE.puts "#{SE.lineno}: Bad year '#{stringer}'"
            SE.q {[ 'yyyyDmmDdd' ]}
            raise
        end  
        return date_formatted
    end
    
    def format_date_expression( from_date:, thru_date: '', certainty: '' )
#
#       Turns out, the dates are optional(!) for a date as long as you've got an expression.
#
        date_expression = +''   # If strings are concatted with '<<' the variable must be mutable (changable), 
                                # which is what the '+' sign before the literal means.  Otherwise the literal is 
                                # frozen.
        
        if ( from_date.not_blank? ) then
            date_expression << format_date( from_date )      
        end
         
        if ( thru_date.not_blank? ) then
            if ( from_date.not_blank? ) then         
                if ( from_date != thru_date ) then                              
                    date_expression << date_expression_separator
                    date_expression << format_date( thru_date )      
                end
            else
                date_expression << format_date( thru_date )      
            end
        end
        if ( date_expression.blank? ) then
            date_expression << 'Undated' 
        else 
            if ( certainty == K.approximate ) then            
                date_expression << 's' if ( date_expression.length == 4 && date_expression.last == '0' ) 
                date_expression.prepend( K.circa + ' ' )
            else
                date_expression << certainty
            end 
        end
        return date_expression
    end
    
    def query( what_to_query )
        return ASpace_Query.new( self, nil, self, what_to_query )
    end
    
    def search( record_type:, search_text:, search_uri: '/search' )
        return ASpace_Search.new( self, nil, self, record_type, search_uri )
                            .record_H_A__having_the_text( search_text )
    end
    
end

class ASpace_Query
    attr_accessor :aspace_O,  :rep_O,  :uri_addr,  :my_creator_O
    attr_accessor :result_A
    alias :record_H_A :result_A
    alias :ids_A      :result_A
   
    def initialize( aspace_O, rep_O, my_creator_O, what_to_query )
        self.aspace_O     = aspace_O
        self.rep_O        = rep_O
        self.my_creator_O = my_creator_O 
        if ( self.uri_addr.nil? ) then
            self.uri_addr = "/#{what_to_query}"
        end
        self.result_A = nil
    end
            
    def id_A__all
        self.result_A = self.aspace_O.http_calls_O.get( self.uri_addr, { 'all_ids' => 'true' } )
        return self
    end
       
    def record_H_A__all
       #SE.q {['self.aspace_O', 'self.my_creator_O', 'self.uri_addr']}
        record_H_A = [ ]
        page_total = nil
        page_size = 250
        page = 0; loop do
            page += 1
            page_H = self.aspace_O.http_calls_O.get( self.uri_addr, { 'page' => page, 'page_size' => page_size } )
            if ( not ( [ K.first_page, K.last_page, K.results, K.total ] - page_H.keys ).empty? ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Missing key in 'page_H'"
                SE.q {'self.uri_addr'}
                SE.q {'page_H.keys'}
                SE.q {'page_H'}
                raise
            end        
            record_H_A.concat( page_H[ K.results ] )
            page_total = page_H[ K.total ]
            break if ( page > page_H[ K.last_page ])
        end
        if ( record_H_A.length != page_total ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Length of 'record_H_A' != to page_H[ K.total ]"
            SE.puts "'#{record_H_A.length}' != '#{page_total}'"
            SE.q {'page_H'}
            raise
        end
        if ( record_H_A.empty? ) then
            SE.puts "#{SE.lineno}: Nothing found for query uri '#{self.uri_addr}'"
        end
        self.result_A = record_H_A
        return self
    end
    
    def record_H_A__of_id_A( id_A )
        if ( id_A.is_not_a?( Array ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Array, it's: '#{id_A.class}'"
            raise
        end   
        int_id_A = []
        id_A.each do | id | 
            case true
            when id.is_a?( Integer )
                int_id_A.push( id )
            when id.integer? 
                int_id_A.push( id.to_i )
            else
                stringer = id.delete_prefix( "{self.uri_addr}/" )
                if ( stringer.not_integer? ) then
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "The param 1 array isn't all integers: '#{stringer}'"
                    SE.puts "or convert to integers after removing the 'uri' prefix."
                    raise
                end
                int_id_A.push( stringer.to_i )
            end
        end
        record_H_A = []
        int_id_A.each_slice( 250 ) do | sliced_A |        
            http_response_body = self.aspace_O.http_calls_O.get( self.uri_addr, { 'id_set' => sliced_A.join( ',' ) } )
            if ( http_response_body.is_not_a?( Array ) ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Unexpected response from #{self.uri_addr}"
                SE.q {'http_response_body'}
                raise
            end
            if ( http_response_body.length < 1 ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Unable to find '#{self.uri_addr}' with 'id_set'='#{id_A}'"
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
        if ( record_H_A.length != id_A.length ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "record_H_A.length != id_A.length"
            SE.q {[ 'record_H_A.length', 'id_A.length' ]}
#           SE.q {[ 'record_H_A' ]}
            SE.q {[ 'id_A' ]}            
            raise
        end     
        if ( record_H_A.empty? ) then
            SE.puts "#{SE.lineno}: Nothing found for query uri '#{self.uri_addr}'"
        end
        self.result_A = record_H_A
        return self
    end
end

class ASpace_Search
=begin
        Endpoints I found (as of 12/17/2025)
        
        /search	                            GET, POST	Search this archive
        /search/location_profile	        GET	        Search across Location Profiles
        /search/published_tree	            GET	        Find the tree view for a particular archival record
        /search/record_types_by_repository	GET, POST	Return the counts of record types of interest 
                                                        by repository
        /search/records	                    GET, POST	Return a set of records by URI
        /search/repositories	            GET, POST	Search across repositories

        /repositories/:repo_id/search	                GET, POST	Search this repository
        /repositories/:repo_id/top_containers/search	GET	        Search for top containers
            
=end
    attr_accessor :aspace_O, :rep_O, :my_creator_O, :uri_addr, :record_type 
    attr_accessor :result_A
    alias :record_H_A :result_A
    
    def initialize( aspace_O, rep_O, my_creator_O, record_type, search_uri = '/search' )
        self.aspace_O     = aspace_O
        self.rep_O        = rep_O
        self.my_creator_O = my_creator_O
        self.record_type  = record_type
        if ( self.uri_addr.nil? ) then
            self.uri_addr = search_uri
        end
    end
   
    def record_H_A__having_the_text( text )
        record_H_A = []
        page = 1
        while true
            http_call_response = self.aspace_O.http_calls_O
                                     .get(  self.uri_addr, 
                                            { 'q'      => "#{text}", 
                                              'type[]' => self.record_type.delete_suffix( 's' ), 
                                              K.page   => page 
                                             }
                                          )
            if ( !  (   http_call_response.has_key?( K.first_page ) &&
                        http_call_response.has_key?( K.last_page ) &&
                        http_call_response.has_key?( K.results ) && 
                        http_call_response.has_key?( K.page_size )
                     ) ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Unexpected response from /search, missing keys."
                SE.q {'http_call_response'}
                raise
            end
            if ( http_call_response[ K.results ].empty? ) then
                SE.puts "#{SE.lineno}: #{SE.my_caller}: =============================================="
                SE.puts "Empty response using 'type[]' => '#{self.record_type.delete_suffix( 's' )}'"
            end
            http_call_response[ K.results ].each do | result_H |
                result_H.reject! { | key, value | key == K.json }
                record_H_A << result_H                   
            end
            page += 1
            break if ( page > http_call_response[ K.last_page ] )
        end
        self.result_A = record_H_A
        return self

    end       
 
end



