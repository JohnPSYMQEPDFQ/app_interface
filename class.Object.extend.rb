
class Object
   
    def deep_copy( )
        return Marshal.load( Marshal.dump( self ) )
    end
    alias_method :copy_by_value, :deep_copy
    alias_method :cbv, :deep_copy

    def not_nil?
        return ! self.nil?
    end

    def not_empty?
        return ! self.empty?
    end
    
    def is_not_a?( p1 )
        return ! self.is_a?( p1 )
    end
    
    def not_match?( p1 )
        return ! self.match?( p1 )
    end
    
    def in?( *args )
        args.flatten.include?( self )
    end
    def not_in?( *args )
        return ! self.in?( args )
    end
    
    def integer?( all_your_base_are_belong_to_us = 10 )
        val = Integer( self, all_your_base_are_belong_to_us ) rescue nil
        return false if ( val.nil? ) 
        return true
    end
    def not_integer?( all_your_base_are_belong_to_us = 10 )
        return ! self.integer?( all_your_base_are_belong_to_us )
    end
            
end