=begin
    This doesn't really work because things like start_with? still do a case-SENSITIVE test!
    But it was fun to play with...
=end
module String_refine_case_insensitive
    refine String do
    
        def ==( other )
            if other.is_a?( String )
                self.casecmp?( other ) 
            else
            # Fall back to the original Object#== behavior for non-string comparisons
                super(other)
            end
        end
        def <=>( other )
            if other.is_a?( String )
                self.casecmp( other ) 
            else
            # Fall back to the original Object#== behavior for non-string comparisons
                super(other)
            end
        end
    end
    
end