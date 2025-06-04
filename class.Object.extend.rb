
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
    
    def in?( *args )
        args.flatten.include?( self )
    end
    def not_in?( *args )
        return ! self.in?( args )
    end
    
end