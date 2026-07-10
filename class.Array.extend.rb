class Array

  
#
#   A zero-relative length method
#
    def maxindex( )
        self.length - 1
    end
    
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
                when self.empty?
                    #SE.print "EMPTY ARRAY: "
                    #SE.q {[ 'n', 'self.class', 'self' ]}
                    n + 1
                else
                    #SE.print "ARRAY: "
                    #SE.q {[ 'n', 'self.class', 'self' ]}
                    self.collect{|x| (x.is_a?( Array ) ? x.maxdepth( n+1 ) : n + 1)}.max
                end
    end
    
    def bulk_change_indexes!( index_change_H )
        # Sort index_change_H based on direction to prevent data loss
        # If moving to a higher index, process from last to first
        # If moving to a lower index, process from first to last
        ordered_index_change_H = index_change_H.sort do |a, b|
            if a[1] > b[1]
                b[1] <=> a[1]
            else
                a[1] <=> b[1]
            end
        end.to_h

          # Apply index_change_H
        ordered_index_change_H.each do | old_index, new_index |
            self[ new_index ] = self.delete_at( old_index )
        end
    end

end
