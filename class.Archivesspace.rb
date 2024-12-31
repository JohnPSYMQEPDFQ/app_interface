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

require 'pp'
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
        @date_expression_separator = '-'
        if ( ENV.has_key?( env_var_aspace_uri_base ) and ENV[ env_var_aspace_uri_base ].not_blank? ) then
            if ( ENV.has_key?( env_var_aspace_user ) and ENV[ env_var_aspace_user ].not_blank? ) then
                @api_uri_base = ENV[ env_var_aspace_uri_base ]
                login_using_env_vars( ENV[ env_var_aspace_user ] )
            else
                SE.puts "#{SE.lineno}: ENV[ '#{env_var_aspace_uri_base}' ] is set, but ENV[ '#{env_var_aspace_user}' ] isn't."
                raise
            end
        else
            if ( ENV.has_key?( env_var_aspace_user ) and ENV[ env_var_aspace_user ].not_blank? ) then
                SE.puts "#{SE.lineno}: ENV[ '#{env_var_aspace_user}' ] is set, but ENV[ '#{env_var_aspace_uri_base}' ] isn't."
                raise
            end
        end
#       SE.puts "================ In Aspace:initialize @session=#{@session}"
    end
    attr_reader :allow_updates, :api_uri_base, :session, :http_calls_O, :date_expression_format, :date_expression_separator
    attr_writer :allow_updates
        
    def login_using_env_vars( p1_user )
        if ( @api_uri_base == nil ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "@api_uri_base isn't set."
            raise 
        end
        userid, password = p1_user.split(':')
        if ( password.nil? ) then
            SE.print "Enter password:"
            password = STDIN.noecho(&:gets).chomp
            SE.puts ''
            if ( password.blank? ) then
                SE.puts "#{SE.lineno}: No password entered."
                exit
            end
        end

        @http_calls_O = Http_Calls.new( self )
        @session = nil
        @uri = "/users/#{userid}/login"
        http_response_body_H = @http_calls_O.post_with_params( @uri, { K.password => password } )
        @session = http_response_body_H[ K.session ]
    #   SE.puts "session = #{@session}"
        return http_response_body_H
    end
    
    def login( p1_userid , p2_password )
        SE.puts "#{SE.lineno}: Method: 'ASpace.login' ignored."
    end
    def api_uri_base=( stringer )
        SE.puts "#{SE.lineno}: Method: 'ASpace.api_uri_base=' ignored"
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
        return yyyyDmmDdd + '' if ( @date_expression_format == 'aspace_default' )
        short_month = [ 'Jan.', 'Feb.', 'Mar.', 'Apr.', 'May.', 'Jun.', 'Jul.', 'Aug.', 'Sep.', 'Oct.', 'Nov.', 'Dec.' ]
        date_formatted = ''
        if ( yyyyDmmDdd.maxoffset >= 5 ) then
            if ( yyyyDmmDdd[ 4, 1 ] != '-' ) then
                SE.puts "#{SE.lineno}: Bad date '#{yyyyDmmDdd}', no dash at offset 4"
                SE.q {[ 'yyyyDmmDdd' ]}
                raise
            end
            stringer = yyyyDmmDdd[ 5, 2 ]
            if ( stringer.length == 2 and stringer.between?( '01', '12' ) and stringer.to_i.between?( 1, 12 ) ) then
                date_formatted += short_month[ stringer.to_i - 1 ] + ' '
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
                    date_formatted += stringer[ 1, 1 ] + ', '
                elsif ( stringer.length == 2 and stringer.between?( '10', '31' ) and stringer.to_i.between?( 10, 31 ) ) then
                    date_formatted += stringer + ', '
                else
                    SE.puts "#{SE.lineno}: Bad day '#{stringer}'"
                    SE.q {[ 'from_yyyyDmmDdd' ]}
                    raise
                end
            end
        end
        stringer = yyyyDmmDdd[ 0, 4 ]
        if ( stringer.length == 4 and stringer.to_i.between?( 1000, 2200 ) ) then
            date_formatted += stringer
        else
            SE.puts "#{SE.lineno}: Bad year '#{stringer}'"
            SE.q {[ 'yyyyDmmDdd' ]}
            raise
        end  
        return date_formatted
    end
    
    def format_date_expression( from_yyyyDmmDdd, thru_yyyyDmmDdd = '' )
        from_date_formatted = format_date( from_yyyyDmmDdd )
        if ( thru_yyyyDmmDdd.empty? or from_yyyyDmmDdd == thru_yyyyDmmDdd ) then
            date_expression = from_date_formatted
        else
            if ( from_yyyyDmmDdd > thru_yyyyDmmDdd ) then
                SE.puts "#{SE.lineno}: from date > thru date"
                SE.q {[ 'from_yyyyDmmDdd', 'thru_yyyyDmmDdd' ]}
                raise
            end
            thru_date_formatted = format_date( thru_yyyyDmmDdd ) 
            date_expression = "#{from_date_formatted}#{@date_expression_separator}#{thru_date_formatted}"
        end
        return date_expression      
    end

end



