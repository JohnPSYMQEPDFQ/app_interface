
class Buffer_Base
    
    def initialize(  )
        @record_H = Hash__where__store_calls_writer.new( self.method( 'record_H=') )
      # SE.puts "#{SE.lineno}, called from: #{SE.my_caller}" 
      # SE.puts "@record_H.class=#{@record_H.class}, @record_H.object_id=#{@record_H.object_id}"
        @cant_change_A = [ ]
        @cant_change_A << K.jsonmodel_type 
        @cant_change_A << K.persistent_id     
    end
    attr_reader :cant_change_A  
    
    def hash_comp_key_type( h_before, h_after )
#       SE.puts "Before: #{h_before}"
#       SE.puts "After:  #{h_after}"
        h_before.each_pair do | k, v |
#           SE.puts "start loop: k = #{k}, v = #{v}"
            if ( k == K.parent ) then
                next if ( h_after.has_key?( k ) and h_after[ k ].is_a?( String ) and h_after[ k ] == '' ) 
            else
                return { k => v } if ( ! h_after.has_key? (k))
                return { k => v } if ( ! v.class == h_after[ k ].class )
            end
            if ( v.is_a?( Hash )) then
                return { k => v } if ( ! hash_comp_key_type( h_before[ k ], h_after[ k ]) == { } )
            end
        end
        return {}
    end
    private :hash_comp_key_type
    
    def record_H
      # SE.puts "#{SE.lineno}, called from: #{SE.my_caller}" 
      # SE.puts "@record_H.class=#{@record_H.class}, @record_H.object_id=#{@record_H.object_id}"
        return @record_H
    end
    
    def record_H=( set_values_H )
      # SE.puts "#{SE.lineno}, called from: #{SE.my_caller}" 
      # SE.puts "@record_H.class=#{@record_H.class}, @record_H.object_id=#{@record_H.object_id}"
        if ( set_values_H.is_not_a?( Hash ) ) then
            SE.puts "#{SE.lineno}: ======================================"
            SE.puts "I was expecting set_values_H to be a HASH, instead it's a '#{set_values_H.class}'"
            raise
        end
        set_values_H.each do |k, v|
            if (k.in?( self.cant_change_A )) then
                SE.puts "#{SE.lineno}: ======================================"
                SE.puts "Key #{k} can't be changed."
                raise
            end
        end
        pre_change_record_H = Hash.new.merge( @record_H )
        @record_H.merge!( @record_H.deep_merge( set_values_H ) )  # This keeps @record_H object_id the same.
        h = hash_comp_key_type( pre_change_record_H, @record_H )
        if ( h.not_empty? )
            SE.puts "#{SE.lineno}: ======================================"
            SE.puts "Invalid (new?, mistyped?) hash key: #{h}"
            SE.q {'pre_change_record_H'}
            SE.q {[ '@record_H' ]}
            raise
        end
        
        if ( pre_change_record_H.keys != @record_H.keys ) then
            SE.puts "#{SE.lineno}: ======================================"
            SE.puts "Invalid (new?, mistyped?) hash key: #{set_values_H}"
            SE.q {'pre_change_record_H'}
            SE.q {[ '@record_H' ]}
            raise
        end
        return @record_H
    end        
    
end




