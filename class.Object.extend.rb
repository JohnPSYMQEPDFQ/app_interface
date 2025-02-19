
class Object

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
        return ! args.flatten.include?( self )
    end
    
end