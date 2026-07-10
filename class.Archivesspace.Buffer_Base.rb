
class Buffer_Base

public  attr_reader :cant_change_A, :record_H_obj_id__at_initialize
private attr_writer :cant_change_A, :record_H_obj_id__at_initialize
    
    def initialize(  )
        @record_H = Hash__where__store_calls_writer.new( self.method( :record_H= ) )
        self.record_H_obj_id__at_initialize = @record_H.object_id
      # SE.puts "#{SE.lineno}, called from: #{SE.my_caller}" 
      # SE.puts "self.record_H.class=#{self.record_H.class}, self.record_H.object_id=#{self.record_H.object_id}"
        self.cant_change_A = [  K.hierarchy,
                                K.id,
                                K.jsonmodel_type, 
                                K.lock_version,
                                K.persistent_id,
                                K.uri
                               ]
    end
    
    def hash_comp_key_type( h_before, h_after )
#       SE.puts "Before: #{h_before}"
#       SE.puts "After:  #{h_after}"
        h_before.each_pair do | k, v |
#           SE.puts "start loop: k = #{k}, v = #{v}"
            if ( k == K.parent ) then
                next if ( h_after.has_key?( k ) && h_after[ k ].is_a?( String ) && h_after[ k ].empty? ) 
            else
                return { k => v } if ( ! h_after.has_key?( k ) )
                return { k => v } if ( ! v.class == h_after[ k ].class )
            end
            if ( v.is_a?( Hash )) then
                return { k => v } if ( ! hash_comp_key_type( h_before[ k ], h_after[ k ]).empty? )
            end
        end
        return {}
    end
    private :hash_comp_key_type
    
    def record_H
#       WARNING: You must use @record_H in this method, as self.record_H calls itself!!!!!!!!!!!
#                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   
        if ( @record_H.object_id != self.record_H_obj_id__at_initialize ) then
            SE.raise
        end
      # SE.puts "#{SE.lineno}, called from: #{SE.my_caller}" 
      # SE.puts "self.record_H.class=#{self.record_H.class}, self.record_H.object_id=#{self.record_H.object_id}"
        return @record_H     
    end
    
    def record_H=( new_values_H )
      # SE.puts "#{SE.lineno}, called from: #{SE.my_caller}" 
      # SE.puts "self.record_H.class=#{self.record_H.class}, self.record_H.object_id=#{self.record_H.object_id}"
        if ( new_values_H.is_not_a?( Hash ) ) then
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}: ======================================"
            SE.puts "I was expecting new_values_H to be a HASH, instead it's a '#{new_values_H.class}'"
            SE.q { 'new_values_H' }
            raise
        end
        
        if ( self.record_H.not_empty? ) then
            new_values_H.delete_if { | k, v | v == FILTERED }
            new_values_H.each do | k, v |
                next if ( self.cant_change_A.not_include?( k ) )                
                if ( self.record_H.has_no_key?( k ) ) then
                    SE.puts "#{SE.lineno}, called from: #{SE.my_caller}: ======================================"                
                    SE.puts "Key '#{k}' can't be changed, but it's not present in the Before-Change self.record_H."
                    SE.puts "New value:'#{k}' => '#{v}'"
                    SE.q {'self.buffer_action_stack_A'}
                    SE.puts 'Before-Change self.record_H ---------------------------------------------'
                    SE.q { 'self.record_H' }
                    SE.puts ''
                    SE.puts 'New-Values new_values_H --------------------------------------------'
                    SE.q { 'new_values_H' }
                    raise
                end 
                next if ( self.record_H[ k ] == UNDEFINED )
                
                if ( self.record_H[ k ] != v ) then 
                    SE.puts "#{SE.lineno}, called from: #{SE.my_caller}: ======================================"                
                    SE.puts "Key '#{k}' can't be changed."
                    SE.puts "Old value:'#{k}' => '#{self.record_H[ k ]}'"
                    SE.puts "New value:'#{k}' => '#{v}'"
                    SE.q {'self.buffer_action_stack_A'}
                    SE.puts 'Before-Change self.record_H ---------------------------------------------'
                    SE.q { 'self.record_H' }
                    SE.puts ''
                    SE.puts 'New-Values new_values_H --------------------------------------------'
                    SE.q { 'new_values_H' }
                    raise
                end
            end
        end
        pre_change_record_H = Hash.new.merge( self.record_H )
        self.record_H.merge!( self.record_H.deep_merge( new_values_H ) )  # There is no deep_merge! method, so
                                                                          # self.record_H.merge!(..., keeps the 
                                                                          # object_id of record_H the same, which
                                                                          # is important because it's not a hash.
        
        if ( pre_change_record_H.not_empty? ) then
            h = hash_comp_key_type( pre_change_record_H, self.record_H )
            if ( h.not_empty? )
                SE.puts "#{SE.lineno}, called from: #{SE.my_caller}: ======================================"
                SE.puts "Invalid (new?, mistyped?) hash key: #{h.keys}"
                SE.q {'self.buffer_action_stack_A'}
                SE.puts 'Before-Change pre_change_record_H -----------------------------------'
                SE.q {'pre_change_record_H'}
                SE.puts ''
                SE.puts 'After-Change self.record_H ----------------------------------------------'
                SE.q { 'self.record_H' }
                SE.puts ''
                SE.puts 'New-Values new_values_H --------------------------------------------'
                SE.q { 'new_values_H' }
                raise
            end
            arr = pre_change_record_H.keys - self.record_H.keys
            if ( arr.not_empty? ) then
                SE.puts "#{SE.lineno}, called from: #{SE.my_caller}: ======================================"
                SE.puts "Missing keys in After-Change self.record_H: #{arr}"
                SE.q {'self.buffer_action_stack_A'}
                SE.puts 'Before-Change pre_change_record_H -----------------------------------'
                SE.q {'pre_change_record_H'}
                SE.puts ''
                SE.puts 'After-Change self.record_H ----------------------------------------------'
                SE.q { 'self.record_H' }
                SE.puts ''
                SE.puts 'New-Values new_values_H --------------------------------------------'
                SE.q { 'new_values_H' }
                raise
            end
        end
        if ( self.record_H.object_id != self.record_H_obj_id__at_initialize ) then
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}: ======================================"
            SE.puts "Programmer malfunction!"
            SE.puts 'if ( self.record_H.object_id != self.record_H_obj_id__at_initialize )'
            raise 
        end
        return self.record_H
    end        
    
end




