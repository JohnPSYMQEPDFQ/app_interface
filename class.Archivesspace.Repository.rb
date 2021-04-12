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

class Repository
    def initialize( p1_aspace_O, p2_rep_num )
        if ( p1_aspace_O.class != ASpace ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a ASpace class object"
            raise
        end    
        if ( ! p1_aspace_O.session or p1_aspace_O.session == K.undefined ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "aspace_O.session undefined, do the ASpace#login method first."
            raise
        end
        @aspace_O = p1_aspace_O
        @num = p2_rep_num
        @uri = "/repositories/#{@num}"
#       SE.puts "#{SE.lineno}: ================ In Repository:initialize,@num=#{@num}"
    end
    attr_reader :aspace_O, :num, :uri
       
end


