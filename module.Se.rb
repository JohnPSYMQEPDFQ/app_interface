require 'pp'
require 'awesome_print'

module SE
    def SE.puts(*params)
        params.each do |e|
            $stderr.puts e
        end
    end
    def SE.print(*params)
        params.each do |e|
            $stderr.print e
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
            $stderr.puts e.ai( ( $stderr.isatty ) ? {} : { :plain => true } )
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
                "#{expression} = #{value.ai( ( $stderr.isatty ) ? {} : { :plain => true } )}"
            end.join(', ')
            $stderr.puts SE.lineno(1) + ": " + stringer
        else
            stuff.each do
                |thing| SE.puts SE.lineno(3) + ": " + thing.ai( ( $stderr.isatty ) ? {} : { :plain => true } )
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
    def SE.ap_stack()
        SE.ap( SE.stack )
    end
    def SE.stack()
        a = []
        caller.each do |e|
            a << e.sub(/^.*\//,"").sub(/:in .* in /,":in ").gsub(/[`']/,"")
        end
        return a
    end    
    
    def SE.debug_on_the_range( thing_to_test, debug_range )
        if ( not debug_range.is_a?( Range )) then
            SE.puts "#{SE.lineno}: Was expecting param2 to be a Range, instead it's a #{debug_range.class}"
            raise
        end
#       SE.q {[ 'thing_to_test', 'debug_range', 'debug_range === thing_to_test' ]}
        if ( $DEBUG ) then
            if ( not debug_range === thing_to_test ) then   # The range MUST be on the left of the ===  !!!
                SE.puts "#{SE.lineno}: DEBUG off !!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                $DEBUG = false
                SE.ap_stack
            end
        else
            if ( debug_range === thing_to_test  ) then
                SE.puts "#{SE.lineno}: DEBUG on !!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                $DEBUG = true
                SE.ap_stack
            end
        end
    end
    
    class Loop_detector
        def initialize( loop_limit = 30 )
            @loop_cnt = 0
            @loop_limit = loop_limit
        end
        private attr_accessor :loop_cnt, :loop_limit
        
        def loop
            if ( self.loop_cnt > self.loop_limit ) then
                raise "LOOP DETECTOR: Abort ( loops=#{self.loop_cnt}, limit=#{self.loop_limit} )"
            end
            if ( self.loop_cnt >= self.loop_limit ) then
                SE.puts "#{SE.lineno}: LOOP DETECTOR: DEBUG on !!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                $DEBUG = true
                SE.ap_stack
            end
            self.loop_cnt += 1
        end
    end
end



        
    
        

