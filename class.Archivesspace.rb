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
        @allow_updates = false
        @session = 'not_logged_in'
        @api_uri_base = nil
        @http_calls_O = nil
#       SE.puts "================ In Aspace:initialize @session=#{@session}"
    end
    attr_reader :allow_updates, :api_uri_base, :session, :http_calls_O
    attr_writer :allow_updates, :api_uri_base
        
    def login( p1_userid , p2_password )
        if ( @api_uri_base == nil ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Set it with the ASpace#api_uri_base= method"
            raise 
        end
        @http_calls_O = Http_Calls.new( self )
        @session = nil
        @uri = "/users/#{p1_userid}/login"
        http_response_body_H = @http_calls_O.post_with_params( @uri, { K.password => p2_password } )
        @session = http_response_body_H[ K.session ]
    #   SE.puts "session = #{@session}"
        return http_response_body_H
    end
end



