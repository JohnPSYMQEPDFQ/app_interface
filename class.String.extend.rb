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

    def integer?( )
        return false if ( self == nil ) 
        val = Integer self rescue nil
        return false if ( val == nil ) 
        return true
    end   
end

