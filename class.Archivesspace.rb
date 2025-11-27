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
        __ = reads as: 'in a(n)', e.g.: record_H__A = 'record' Hash "in an" Array.

=end

require 'pp'
require 'awesome_print'
require 'io/console'
require 'module.SE.rb'
require 'class.Array.extend.rb'
require 'class.Hash.extend.rb'
require 'class.Object.extend.rb'
require 'class.String.extend.rb'
require 'class.Symbol.extend.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'class.Archivesspace.Buffer_Base.rb'
require 'class.ArchivesSpace.Record_Buf.rb'
require 'class.Archivesspace.Record_Format.rb'
require 'class.ArchivesSpace.http_calls.rb'


class ASpace
    def initialize()
        env_var_aspace_uri_base='ASPACE_URI_BASE'
        env_var_aspace_user='ASPACE_USER'
        @allow_updates = false
        @session = 'NEVER_LOGGED_IN! SEE:class.Archivespace.rb'
        @api_uri_base = nil
        @http_calls_O = 'NEVER_LOGGED_IN! SEE:class.Archivespace.rb'
        @date_expression_format = 'aspace_default'      # The default is the yyyyDmmDdd format.   or :mmmddyyyy = MMM. nn, yyyy
        @date_expression_separator = ' - '
        if ( ENV.has_key?( env_var_aspace_uri_base ) and ENV[ env_var_aspace_uri_base ].not_blank? ) then
            if ( ENV.has_key?( env_var_aspace_user ) and ENV[ env_var_aspace_user ].not_blank? ) then
                @api_uri_base = ENV[ env_var_aspace_uri_base ]
                login_using_env_vars( ENV[ env_var_aspace_user ] )
            else
                SE.puts "#{SE.lineno}: ENV[ '#{env_var_aspace_uri_base}' ] is set, but ENV[ '#{env_var_aspace_user}' ] isn't."
                raise
            end
        else
            if ( ENV.has_key?( env_var_aspace_user ) and ENV[ env_var_aspace_user ].blank? ) then
                SE.puts "#{SE.lineno}: ENV[ '#{env_var_aspace_user}' ] is set, but ENV[ '#{env_var_aspace_uri_base}' ] isn't."
                raise
            else
#               SE.puts "#{SE.lineno}: No database login as ENV[ '#{env_var_aspace_user}' ] and ENV[ '#{env_var_aspace_uri_base}' ] aren't set."
            end
        end
#       SE.puts "================ In Aspace:initialize @session=#{@session}"
    end       
    public  attr_reader :allow_updates, :api_uri_base, :session, :http_calls_O, :date_expression_format, :date_expression_separator
    public  attr_writer :allow_updates
    private attr_writer                 :api_uri_base, :session, :http_calls_O 
    
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
    #   SE.puts "session = #{self.session}"
        return http_response_body_H
    end
    
    def date_expression_format=( date_format )
        if ( date_format.not_in?( [ 'aspace_default', 'mmmddyyyy' ] ) ) then
            SE.puts "#{SE.lineno}: Invalid date_format '#{date_format}', was expecting 'aspace_default' or 'mmmddyyyy'"
            SE.q {[ 'date_format' ]}
            raise
        end
        @date_expression_format = date_format
    end

    def date_expression_separator=( date_separator )
        if ( date_separator.not_in?( [ ' - ', '-' ] ) ) then
            SE.puts "#{SE.lineno}: Invalid date_separator '#{date_separator}', was expecting ' - ' or '-'"
            SE.q {[ 'date_separator' ]}
            raise
        end
        @date_expression_separator = date_separator
    end
    
    def format_date( yyyyDmmDdd ) 
        return yyyyDmmDdd + '' if ( self.date_expression_format == 'aspace_default' )
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
            if ( stringer.length == 2 and stringer.between?( '01', '12' ) and stringer.to_i.between?( 1, 12 ) ) then
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
                if    ( stringer.length == 2 and stringer.between?( '01', '09' ) and stringer.to_i.between?(  1,  9 ) ) then
                    date_formatted << stringer[ 1, 1 ] + ', '
                elsif ( stringer.length == 2 and stringer.between?( '10', '31' ) and stringer.to_i.between?( 10, 31 ) ) then
                    date_formatted << stringer + ', '
                else
                    SE.puts "#{SE.lineno}: Bad day '#{stringer}'"
                    SE.q {[ 'yyyyDmmDdd' ]}
                    raise
                end
            end
        end
        stringer = yyyyDmmDdd[ 0, 4 ]
        if ( stringer.length == 4 and stringer.to_i.between?( 1000, 2200 ) ) then
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
                date_expression << 's' if ( date_expression.length == 4 and date_expression.last == '0' ) 
                date_expression.prepend( K.circa + ' ' )
            else
                date_expression << certainty
            end 
        end
        return date_expression
    end

end



