require 'pp'
module Se
    def Se.puts(*params)
        params.each do |e|
            $stderr.puts e
        end
    end
    def Se.pp(*params)
        params.each do |e|
            $stderr.puts PP.pp(e, '')
        end
    end
    def Se.p(*params)
        params.each do |e|
            $stderr.puts e.inspect
        end
    end
    
    def Se.pov( p1_O )  # Print Object's Variables
        Se.puts "#{Se.lineno(1)}:#{p1_O.class.name} Variables:"
        p1_O.instance_variables.map{|var| Se.puts [ var, p1_O.instance_variable_get( var ) ].join( "=" )}
    end
    def Se.pom( p1_O )  # Print Object's Methods
        Se.puts "#{Se.lineno(1)}:#{p1_O.class.name} Methods:"
        Se.puts ( p1_O.methods - Object.methods ).map{|x| x = "#{p1_O.class.name} #{x}"}.sort
    end
    def Se.lineno( e = 0 )
        s = caller[e].sub(/^.*\//,"").sub(/:in .* in /,":in ").gsub(/[`']/,"")
        if ( defined?( $. ) and $. and $. > 0 ) then
            s += " $.=#{$.}"
        end
        return s
    end

    def Se.pp_stack()
        $stderr.puts PP.pp(Se.stack, '')
    end
    def Se.stack()
        a = []
        caller.each do |e|
            a << e.sub(/^.*\//,"").sub(/:in .* in /,":in ").gsub(/[`']/,"")
        end
        return a
    end    
end

