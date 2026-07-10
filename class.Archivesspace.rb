=begin

Variable Abbreviations:
        __   =  reads as: ','
        _A   = Array
        _BO  = Buffer Object
        _C   = Class of Struct
        _CKA = Composite Key Array
        _H   = Hash
        _I   = Integer
        _J   = Json string
        _LP  = Lambda Proc
        _MO  = Match Object
        _O   = Object
        _QO  = Query Object
        _RE  = Regular Expression, e.g.: find_bozo_RE = /#{find_bozo_RES}/
        _RES = Regular Expression String, e.g: find_bozo_RES = '\s+bozo\s+'
        _S   = Set or Structure of _C 
        _TF  = True/False (Boolean)
    
=end

require 'requires.common.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.Buffer_Base.rb'
require 'class.ArchivesSpace.Record_Buf.rb'
require 'class.Archivesspace.Record_Format.rb'


class ASpace
    public  attr_reader :allow_updates, :res_faft_validated, :api_uri_base, :session, :http_calls_O, :date_expression_format, :date_expression_separator
    public  attr_writer :allow_updates, :res_faft_validated
    private attr_writer                                      :api_uri_base, :session, :http_calls_O 
    
    def initialize( )
        env_var_aspace_uri_base        = 'ASPACE_URI_BASE'
        env_var_aspace_user            = 'ASPACE_USER'
        self.api_uri_base              = nil
        self.session                   = 'NEVER_LOGGED_IN! SEE:class.Archivespace.rb'
        self.allow_updates             = false
        self.res_faft_validated        = false
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
            SE.puts  "(After entering the password: if there's no LF immediately after hitting <enter>, try a 'stty sane' or new window...)"
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
    
    def validate_resource_faft( res_BO, faft_to_validate )
        if ( res_BO.is_not_a?( Resource_Record_Buf )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param-1 is not a 'Resource_Record_Buf' class object, it's a '#{res_BO.class}'"
            raise
        end 
        rep_O = res_BO.res_O.rep_O
        res_title = res_BO.record_H.fetch( K.title ).strip.downcase
        res_faft  = res_BO.record_H.fetch( K.finding_aid_filing_title, '~~no_finding_aid_filing_title~~' ).strip.downcase
        if ( faft_to_validate.not_in?(  res_faft[ 0, faft_to_validate.length ], res_title[ 0, faft_to_validate.length ] ) ) then
            SE.puts "#{SE.lineno}: The 'faft_to_validate'(Param-2) must start with the K.finding_aid_filing_title (FAFT)"
            SE.puts "of the 'res_BO'(Param-1), NOT the resource's K.title (unless there's no FAFT)."
            SE.q {[ 'faft_to_validate' ]}
            SE.q {[ 'res_faft[ 0, faft_to_validate.length ]' ]}
            SE.q {[ 'res_faft' ]}
            SE.q {[ 'res_title[ 0, faft_to_validate.length ]' ]}
            SE.q {[ 'res_title' ]}
            raise
        end
        
        search_text = %Q|title:"#{faft_to_validate}"|
        #   Note that:  The K.title returned by 'search' is NOT the resource's K.title field, it's the K.finding_aid_filing_title
        #               Except that sometimes it IS!   Who knows, check for both.  
        search_record_H_A = rep_O.search( record_type_A: [ K.resource ], search_text: search_text, result_field_A: [ K.title ] ).record_H_A
        if ( search_record_H_A.empty? ) then
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "Nothing found for '#{search_text}'" 
            SE.puts ''
            SE.puts "NOTE THAT: The AS search doesn't seem to be able to find partial words."
            SE.puts "           It won't find 'bozo the cl', but will find 'bozo the clown' (or 'bozo the')"
            SE.puts ''
            SE.puts "Res title '#{res_title}'"
            SE.puts "Res faft  '#{res_faft}'"
            raise
        end
        if ( search_record_H_A.length > 1 ) then
            search_title_A = search_record_H_A.map{ | res_search_H | res_search_H.fetch( K.title ).downcase }
            arr = search_title_A.select { | search_title | search_title[ 0, faft_to_validate.length ] == "#{faft_to_validate}" &&
                                                           search_title                               == res_faft }
            if ( arr.length > 1 ) then
                SE.puts "#{SE.lineno}: =============================="
                SE.puts "Multiple Resource titles found for option: --res_faft '#{faft_to_validate}'"
                SE.q {'search_title_A'}
                SE.q {'arr'}
                raise
            end
        end

        if ( search_record_H_A.first.fetch( K.title ).strip.downcase.not_in?( res_faft, res_title ) ) then
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "search_record_H_A.first.fetch( K.title ).strip.downcase.not_in?( res_faft, res_title )"
            SE.q {'search_record_H_A.first.fetch( K.title ).strip.downcase'}
            SE.q {'res_faft'}
            SE.q {'res_title'}
            raise 
        end
        self.res_faft_validated = true
        return self.res_faft_validated
    end
    
    def query( what_to_query )
        return ASpace_Query.new( self, nil, self, what_to_query )
    end
    
    def search( record_type_A: [], search_text:, search_uri: '/search', result_field_A: [] )
        return ASpace_Search.new( self, nil, self, record_type_A, search_uri, search_text, result_field_A )
    end
    
    def batch_delete( delete_uri_A )
        return ASpace_Batch_delete.new( self, nil, self, delete_uri_A )
    end
    
end

class ASpace_Query
    attr_accessor :aspace_O,  :rep_O,  :uri_addr,  :my_creator_O
   
    def initialize( aspace_O, rep_O, my_creator_O, what_to_query )
        self.aspace_O     = aspace_O
        self.rep_O        = rep_O
        self.my_creator_O = my_creator_O 
        if ( self.uri_addr.nil? ) then
            self.uri_addr = "/#{what_to_query}"
        end
    end
            
    def rec_id_A
        return self.aspace_O.http_calls_O.get( self.uri_addr, { 'all_ids' => 'true' } )
    end
       
    def record_H_A
       #SE.q {['self.aspace_O.class', 'self.my_creator_O.class', 'self.uri_addr']}
        query_record_H_A = [ ]     # This needs to be different because of the method name.
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
            query_record_H_A.concat( page_H[ K.results ] )
            page_total = page_H[ K.total ]
            break if ( page > page_H[ K.last_page ])
        end
        if ( query_record_H_A.length != page_total ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Length of 'query_record_H_A' != to page_H[ K.total ]"
            SE.puts "'#{query_record_H_A.length}' != '#{page_total}'"
            SE.q {'page_H'}
            raise
        end
        if ( query_record_H_A.empty? ) then
            SE.puts "#{SE.lineno}: Nothing found for query uri '#{self.uri_addr}'"
        end
        return query_record_H_A
    end
    
    def record_H_A__OF_rec_id_A( rec_id_A )
        if ( rec_id_A.is_not_a?( Array ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not an Array, it's: '#{rec_id_A.class}'"
            raise
        end   
        rec_id_I_A = []
        rec_id_A.each do | rec_id | 
            case true
            when rec_id.is_a?( Integer )
                rec_id_I_A.push( rec_id )
            when rec_id.integer? 
                rec_id_I_A.push( rec_id.to_i )
            else
                stringer = rec_id.delete_prefix( "#{self.uri_addr}/" )
                if ( stringer.not_integer? ) then
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "The param 1 array isn't all integers: '#{stringer}'"
                    SE.puts "or convert to integers after removing the 'uri' prefix."
                    raise
                end
                rec_id_I_A.push( stringer.to_i )
            end
        end
        query_record_H_A = []
        rec_id_I_A.each_slice( 100 ) do | sliced_A |        
            http_response_body = self.aspace_O.http_calls_O.get( self.uri_addr, { 'id_set' => sliced_A.join( ',' ) } )
            if ( http_response_body.is_not_a?( Array ) ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Unexpected response from #{self.uri_addr}"
                SE.q {'http_response_body'}
                raise
            end
            if ( http_response_body.length < 1 ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Unable to find '#{self.uri_addr}' with 'id_set'='#{rec_id_A}'"
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
            query_record_H_A.concat( http_response_body )
        end
        if ( query_record_H_A.length != rec_id_A.length ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "query_record_H_A.length != rec_id_A.length"
            SE.q {[ 'query_record_H_A.length', 'rec_id_A.length' ]}
#           SE.q {[ 'query_record_H_A' ]}
            SE.q {[ 'rec_id_A' ]}            
            raise
        end     
        if ( query_record_H_A.empty? ) then
            SE.puts "#{SE.lineno}: Nothing found for query uri '#{self.uri_addr}'"
        end
        return query_record_H_A
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
        
        
       Also note THIS comment, from https://archivesspace.github.io/archivesspace/api/?shell#search-this-archive
            For parameter 'q' : 
                A search query string. 
                Uses Lucene 4.0 syntax:
                    http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html 
                    Search index structure can be found in solr/schema.xml
       
            
=end
    attr_accessor :aspace_O, :rep_O, :my_creator_O, :uri_addr, :record_type_A, :result_field_A, :record_H_A 
    
    def initialize( aspace_O, rep_O, my_creator_O, record_type_A, search_uri, search_text, result_field_A )
        self.aspace_O       = aspace_O
        self.rep_O          = rep_O
        self.my_creator_O   = my_creator_O 
        self.record_type_A  = record_type_A.map{ | e | e.delete_suffix('s')}.sort.reverse
        self.result_field_A = result_field_A
        if ( self.uri_addr.nil? ) then
            self.uri_addr = search_uri
        end
        if ( self.result_field_A.is_not_a?( Array ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "'result_field_A' is not an Array, it's a #{self.result_field_A.class}"
            SE.q {'self.result_field_A'}
            raise
        end
        page = 1
        self.record_H_A = []        
        param_H = {}.compare_by_identity
        param_H[ 'q'.dup ]    = "#{search_text}"
        param_H[ K.page.dup ] = page.dup
        if ( self.record_type_A.not_empty? ) then
            self.record_type_A.each do | record_type |
                if ( record_type.not_in?( [ 'resource','archival_object','accession','digital_object',
                                            'agent_person','agent_family','agent_corporate_entity','agent_software',
                                            'subject','location','event','classification' ] ) ) then
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Invalid record_type `#{record_type}`"
                    raise
                end
                param_H[ 'type[]'.dup ] = record_type             
            end
        end
        if ( self.result_field_A.not_empty? ) then
            param_H[ 'fields[]'.dup ] = self.result_field_A.join( ',' )  # For some reason this allows a comma-delimited list
                                                                         # but 'type[]' doesn't.
        end
       #SE.q{['self.uri_addr','param_H']}
        while true
            http_call_response = self.aspace_O.http_calls_O.get( self.uri_addr, param_H )
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
                SE.print "Empty search response "
                SE.print "using 'type[]' => '#{self.record_type_A.join( ',' )}'" if ( self.record_type_A.not_empty? )
                SE.puts  "."
                SE.puts  "Search text: '#{search_text}'"
                SE.puts  ''
            end
            http_call_response[ K.results ].each do | result_H |
                result_H.reject! { | key, value | key == K.json }
                self.record_H_A << result_H                   
            end
            page += 1
            break if ( page > http_call_response[ K.last_page ] )
        end        
        return self
    end           
 
end

class ASpace_Batch_delete
    attr_accessor :aspace_O,  :rep_O, :my_creator_O
    attr_accessor :deleted_cnt
   
    def initialize( aspace_O, rep_O, my_creator_O, delete_uri_A )
        self.aspace_O     = aspace_O
        self.rep_O        = rep_O
        self.my_creator_O = my_creator_O 
        self.deleted_cnt  = 0
        if self.aspace_O.allow_updates
            delete_uri_A.each_slice( 100 ) do | chunk__delete_uri_A |
                SE.q {'chunk__delete_uri_A.length'}
                param_H = {}.compare_by_identity
                chunk__delete_uri_A.each do | delete_uri |
                    param_H[ "#{K.record_uris}[]" ] = delete_uri
                end
                response = aspace_O.http_calls_O.post_with_params( "/batch_delete", param_H )
                if response[ K.status ] != 'OK'     
                    SE.puts "#{SE.lineno}: response['status'] != 'OK'"
                    SE.q {'response'}
                    SE.q {'param_H'}
                    raise
                end
                response[ K.results ].each do | result_H |
                    if result_H[ K.status ].downcase != 'Deleted'.downcase
                        SE.puts "#{SE.lineno}: response[ 'results' ][ 'status' ] != 'Deleted'"
                        SE.q {'response'}
                        SE.q {'param_H'}
                        raise
                    end
                    self.deleted_cnt += 1
                end                       
            end
        else
            SE.puts "#{SE.lineno}: NO UPDATE MODE."
            self.deleted_cnt = delete_uri_A.length
        end
    end
       
end



