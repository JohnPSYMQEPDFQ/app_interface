module Se
    def Se.puts(*params)
        params.each do |e|
            $stderr.puts e
        end
    end
    def Se.pp(*params)
        params.each do |e|
            $stderr.puts "#{Se.lineno(3)}:" + PP.pp(e, '')
        end
    end
    def Se.p(*params)
        params.each do |e|
            $stderr.puts "#{Se.lineno(3)}:" + e.inspect
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
        return caller[e].sub(/^.*\//,"").sub(/:in .* in /,":in ")
    end
end

