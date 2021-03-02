
class String

    def in?( array )
        array.include?( self )
    end

    def maxindex( )
#
#   A zero-relative length method
#
        self.length - 1
    end

    def integer?( all_your_base_are_belong_to_us = 10 )
        val = Integer( self, all_your_base_are_belong_to_us ) rescue nil
        return false if ( val == nil ) 
        return true
    end   
end
