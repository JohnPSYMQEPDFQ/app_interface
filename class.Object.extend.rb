
class Object
   
    def nested_copy( )
        return Marshal.load( Marshal.dump( self ) )
    end
    alias_method :copy_by_value, :nested_copy
    alias_method :cbv,           :nested_copy
    alias_method :deep_copy,     :nested_copy

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
    
    def not_include?( p1 )
        return ! self.include?( p1 )
    end
    
    def in?( *args )
        return args.flatten.include?( self )
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