require 'pp'
require 'awesome_print'

module SE
    def SE.puts(*params)
        params.each do |e|
            $stderr.puts e
        end
    end
    def SE.pp(*params)
        SE.puts "#{SE.lineno(1)}:"
        params.each do |e|
            $stderr.puts PP.pp(e, '')
        end
    end
    def SE.ap(*params)
        SE.puts "#{SE.lineno(1)}:"
        params.each do |e|
            $stderr.puts e.ai
        end
    end
    def SE.p(*params)
        params.each do |e|
            $stderr.puts e.inspect
        end
    end
    
    def SE.q(*stuff, &block)

    # https://stackoverflow.com/a/3250188/13159909
    #
    # Usage: SE.q { :variable }     Which prints variable = value
    #        SE.q { 'variable' }    Same as above but handles dots,  eg. variable.method
    #        SE.q variable          Which just prints the value
    #
        if block
            stringer = Array(block[]).collect do |expression|
            value = eval(expression.to_s, block.binding)
            "#{expression} = #{value.ai}"
            end.join(', ')
            $stderr.puts SE.lineno(1) + ":" + stringer
        else
            stuff.each do
                |thing| SE.puts SE.lineno(3) + ":" + thing.ai
            end
        end
    end

    def SE.pov( p1_O )  # Print Object's Variables
        SE.puts "#{SE.lineno(1)}:#{p1_O.class.name} Variables:"
        p1_O.instance_variables.map{|var| SE.puts [ var, p1_O.instance_variable_get( var ) ].join( "=" )}
    end
    def SE.pom( p1_O )  # Print Object's Methods
        SE.puts "#{SE.lineno(1)}:#{p1_O.class.name} Methods:"
        SE.puts ( p1_O.methods - Object.methods ).map{|x| x = "#{p1_O.class.name} #{x}"}.sort
    end
    def SE.lineno( e = 0 )
        s = caller[e].sub(/^.*\//,"").sub(/:in .* in /,":in ").gsub(/[`']/,"")
        if ( defined?( $. ) and $. and $. > 0 ) then
            s += " $.=#{$.}"
        end
        return s
    end

    def SE.pp_stack()
        $stderr.puts PP.pp(SE.stack, '')
    end
    def SE.stack()
        a = []
        caller.each do |e|
            a << e.sub(/^.*\//,"").sub(/:in .* in /,":in ").gsub(/[`']/,"")
        end
        return a
    end    

end

