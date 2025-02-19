
class String

    def maxoffset( )    # This seems to be the more correct term for a String.
        self.length - 1
    end
    alias_method :maxindex, :maxoffset     # But I had code already using maxindex so I'm leaving it for now

    def integer?( all_your_base_are_belong_to_us = 10 )
        val = Integer( self, all_your_base_are_belong_to_us ) rescue nil
        return false if ( val == nil ) 
        return true
    end   
        
    def blank?( )
        return self.to_s.strip.empty?
    end
    def not_blank?( )
        return ! self.to_s.strip.empty?
    end
    
end

class String_with_before_after_STORE_and_ASSIGN_methods 
#
#   See below for an example
#
    class String_with_before_after_STORE_methods < String
     
#           store is an alias for []=
     
        def initialize( before_change_method, after_change_method, argv )
#           SE.puts "\n#{SE.lineno}: class='#{self.class}', before_change_method=#{before_change_method}, after_change_method=#{after_change_method}, arg='#{argv}'"
            @before_change_method = before_change_method
            @after_change_method = after_change_method
            if ( argv.nil? ) then
                super(  )
            else
                super( argv )
            end
        end
        def []=( *argv )
#           SE.puts "\n#{SE.lineno}: class='#{self.class}', argv='#{argv}'"
            @before_string = ( @before_change_method or @after_change_method ) ? self + '' : nil
            @before_change_method.call( @before_string, argv ) if ( @before_change_method )
            super
            @after_change_method.call( @before_string, self, argv ) if ( @after_change_method )
        end
        attr_accessor :before_change_method, :after_change_method
    end
    def initialize( before_change_method: nil, after_change_method: nil  )
#       SE.puts "\n#{SE.lineno}: class='#{self.class}', before_change_method=#{before_change_method}, after_change_method=#{after_change_method}"
        @before_change_method = before_change_method 
        @after_change_method = after_change_method 
    end
    attr_accessor :before_change_method, :after_change_method
    def string=( argv )
#       SE.puts "\n#{SE.lineno}: class='#{self.class}', argv='#{argv}'"
        @before_string = nil
        @string = String_with_before_after_STORE_methods.new( @before_change_method, @after_change_method, argv )
#       SE.puts "\n#{SE.lineno}: @string.class='#{@string.class}', @string[]='#{@string.method( :[]= )}'"
        @after_change_method.call( @before_string, @string, argv ) if ( @after_change_method )
    end
    attr_reader :string, :before_string  
end

#    class Run
#        def my_main
#            
#            vanilla_string = ''
#            SE.puts "\n#{SE.lineno}: vanilla_string.class='#{vanilla_string.class}', vanilla_string[]='#{vanilla_string.method( :[]= )}'"
#      
#            test_class_obj = String_with_before_after_STORE_and_ASSIGN_methods.new(  )
#            SE.puts "\n#{SE.lineno}: test_class_obj.class='#{test_class_obj.string.class}'"
#            test_class_obj.before_change_method = self.method( :before_change_validate )
#            test_class_obj.after_change_method = self.method( :after_change_validate )
#            SE.puts "\n#{SE.lineno}: test_class_obj.class='#{test_class_obj.string.class}'"
#            
#            change_string( test_class_obj )
#            
#            test_class_obj = String_with_before_after_STORE_and_ASSIGN_methods.new( before_change_method: self.method( :before_change_validate ), after_change_method: self.method( :after_change_validate )  )
#            SE.puts "\n#{SE.lineno}: test_class_obj.class='#{test_class_obj.string.class}'"
#            
#            change_string( test_class_obj )
#            
#            test_class_obj.before_change_method = self.method( :before_change_alternate )
#            test_class_obj.after_change_method = self.method( :after_change_alternate )
#            SE.puts "\n#{SE.lineno}: test_class_obj.class='#{test_class_obj.string.class}'"
#            
#            change_string( test_class_obj )
#                   
#            test_class_obj.before_change_method = nil
#            test_class_obj.after_change_method = nil
#            SE.puts "\n#{SE.lineno}: test_class_obj.class='#{test_class_obj.string.class}'"
#            
#            change_string( test_class_obj )
#            
#        end
#             
#        def change_string( test_class_obj )
#            SE.q {[ 'test_class_obj' ]}
#            test_class_obj.string = 'bozo'    
#            SE.puts "test_class_obj.string = '#{test_class_obj.string}'"
#            SE.puts "\n#{SE.lineno}: test_class_obj.string.class='#{test_class_obj.string.class}', test_class_obj.string[]='#{test_class_obj.string.method( :[]= )}'"
#            
#            test_class_obj.string[ 'bozo' ] = 'bonzo'
#            SE.puts "test_class_obj.string = '#{test_class_obj.string}'"
#            
#            test_class_obj.string[ 3..4 ] = 'bon'
#            SE.puts "test_class_obj.string = '#{test_class_obj.string}'"
#            
#            test_class_obj.s[ 4 ] = 'u'
#            SE.puts "test_class_obj.string = '#{test_class_obj.string}'"
#        end
#        
#        def before_change_validate( before_string, *argv )
#            SE.puts "\n#{SE.lineno}: class='#{self.class}', before_string=#{before_string}, argv='#{argv}' PRE-VALIDATION"
#        end
#        def after_change_validate( before_string, after_string, *argv )
#            SE.puts "\n#{SE.lineno}: class='#{self.class}', before_string=#{before_string}, after_string=#{after_string}, argv='#{argv}' POST-VALIDATION"
#        end
#        def before_change_alternate( after_string, *argv )
#            SE.puts "\n#{SE.lineno}: class='#{self.class}', after_string=#{after_string}, argv='#{argv}' ALT-PRE-VALIDATION"
#        end
#        def after_change_alternate( before_string, after_string, *argv )
#            SE.puts "\n#{SE.lineno}: class='#{self.class}', before_string=#{before_string}, after_string=#{after_string}, argv='#{argv}' ALT-POST-VALIDATION"
#        end
#    end
#    
#    Run.new.my_main