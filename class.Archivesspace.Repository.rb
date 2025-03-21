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
        __ = reads as: 'in a(n)', e.g.: record_H__A = 'record' Hash "in an" Array.

=end

require 'class.Archivesspace.Resource.rb'

class Repository
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
        @num = p2_rep_num
        @uri = "/repositories/#{@num}"
#       SE.puts "#{SE.lineno}: ================ In Repository:initialize,@num=#{@num}"
    end
    attr_reader :aspace_O, :num, :uri
       
end

class Repository_Query   

    def initialize( rep_O )
        if ( not rep_O.is_a?( Repository )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Repository class object, it's a '#{rep_O.class}'"
            raise
        end 
        @rep_O = rep_O
        @buf_A = nil
 
    end
    attr_reader :buf_A, :rep_O

    def get_all_Resource( )
        res_num_A = @rep_O.aspace_O.http_calls_O.get( "#{@rep_O.uri}/resources", { 'all_ids' => 'true' } )
        @buf_A = []
        res_num_A.each do | res_num |
            @buf_A << Resource.new( rep_O, res_num ).new_buffer.read( )
        end
        return self
    end

end
