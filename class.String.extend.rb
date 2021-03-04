
class String

    def in?( array )
        array.include?( self )
    end

    def maxoffset( )    # This seems to be the more correct term for a String.
        self.length - 1
    end
    alias_method :maxindex, :maxoffset     # But I had code already using maxindex so I'm leaving it for now

    def integer?( all_your_base_are_belong_to_us = 10 )
        val = Integer( self, all_your_base_are_belong_to_us ) rescue nil
        return false if ( val == nil ) 
        return true
    end   
end
