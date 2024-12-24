class Array

  
#
#   A zero-relative length method
#
    def maxindex( )
        self.length - 1
    end
    
#
#   Return column N
#
    def column( n )
        self.map{ | row | row[ n ] }
    end
#
#
#       The maximum depth of all the arrays in the arrays.
#
    def maxdepth( n=0 )

#           From https://stackoverflow.com/a/36533220/13159909

        return  case
                when self.class != Array
                    #SE.print "NOT ARRAY: "
                    #SE.q {[ 'n', 'self.class', 'self' ]}
                    n
                when self == []
                    #SE.print "EMPTY ARRAY: "
                    #SE.q {[ 'n', 'self.class', 'self' ]}
                    n + 1
                else
                    #SE.print "ARRAY: "
                    #SE.q {[ 'n', 'self.class', 'self' ]}
                    self.collect{|x| (x.is_a?( Array ) ? x.maxdepth( n+1 ) : n + 1)}.max
                end
    end

end
