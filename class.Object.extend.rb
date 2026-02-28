
class Object
   
    def deep_copy( )
        return Marshal.load( Marshal.dump( self ) )
    end
    alias_method :copy_by_value, :deep_copy
    alias_method :cbv,           :deep_copy
    alias_method :nested_copy,   :deep_copy

#
#   Return column c
#       If self is a hash, 'c' can be a key.

    def column( c )
        self.map{ | row | row[ c ] }
    end
#
    def blank?( )
        return self.to_s.strip.empty?        #  .to_s on a nul variable returns ''
    end
    def not_blank?( )
        return ! self.blank?
    end
    
    def of_composite_key( composite_key )
        if composite_key.is_not_a?( Array )
            SE.puts "The composite key should be an Array, not a #{composite_key.class}"
            SE.q {'composite_key'}
            raise
        end
        
    end
    
    def to_composite_key_h( separator: [], sort_TF: false, _parent_key: nil, _flattened_H: {} )
#
#   If the 'separator' is an 'Array', the resulting flattened hash will have an 'Array' for its keys.
#   If the 'separator' is a 'String', the resulting flattened hash will have the a 'String" with they keys 
#   separated by 'separator'.  

        self.each_with_index do | thingy, idx |
            case true
            when thingy.is_a?( Array )
                raise "Array isn't length of 2" if ( thingy.length != 2 )
                key   = thingy.first 
                value = thingy.last
            else
                key   = idx
                value = thingy
            end
            
            if separator.is_a?( String ) && key.is_a?( String ) && key.include?( separator )
                raise "Separator '#{separator}' found in key '#{key}'!"
            end
            if _parent_key 
                current_key = separator.is_a?( String ) ? _parent_key + "#{separator}#{key}" 
                                                        : _parent_key + [ key ]
            else
                current_key = separator.is_a?( String ) ? key       # Creates the 'String'
                                                        : [ key ]   # or the 'Array'
            end
            if value.not_nil? && value.respond_to?( :each_with_index ) && value.is_not_a?( Range )
                value.to_composite_key_h( separator: separator, 
                                            sort_TF: sort_TF,
                                        _parent_key: current_key, 
                                       _flattened_H: _flattened_H ) 
            else
                _flattened_H[ current_key.freeze ] = value
            end
        end
        return sort_TF ? _flattened_H.sort_by{ | key, value | key }.to_h : _flattened_H
    end    
    

    def deep_flatten_to_h   # Replaced by: to_composite_key_h (above...)  
        do_one_thing = lambda { | thing |
            return thing if ( ! thing.respond_to?( :each_with_index ) )
            
            get_k_v = lambda { | parent_obj, item, idx | 
                case true
                when parent_obj.is_a?( Hash) && item.is_a?( Array )      # if PARENT = hash  ITEM is an ARRAY of its K,V pair                                     
                    raise "Array isn't length of 2" if ( item.length != 2 )
                    key   = item.first 
                    value = item.last
                else                         
                    key   = idx
                    value = item
                end  
                return key, value
            }
            new_hash = {}
            thing.each_with_index do | outer_item, outer_idx |
                outer_key, outer_value = get_k_v.( thing, outer_item, outer_idx )      
               #SE.q {'outer_key'}
               #SE.q {'outer_value'}
               #SE.q {'outer_item'}
               #SE.q {'outer_idx'}
               #SE.q {'new_hash'}
                if ( ! outer_value.respond_to?( :each_with_index ) ) then
                    new_hash[ [ outer_key ] ] = outer_value
                    next
                end
               #SE.q {['thing.class','outer_key','outer_value']}
                outer_value.each_with_index do | inner_item, inner_idx |
                    inner_key, inner_value = get_k_v.( outer_value, inner_item, inner_idx )
                   #SE.q {['outer_value.class','inner_key','inner_value']}
                    if ( inner_key.is_not_a?( Array ) ) then
                        SE.puts "Was expecting inner_key to be an 'Array', not a '#{inner_key.class}'!"
                        SE.q {'inner_key'}
                        SE.q {'inner_value'}
                        SE.q {'outer_key'}
                        SE.q {'outer_value'}
                        SE.q {'inner_item'}
                        SE.q {'inner_idx'}
                        SE.q {'outer_item'}
                        SE.q {'outer_idx'}
                        SE.q {'new_hash'}
                        raise
                    end
                    new_hash[ inner_key.prepend( outer_key ) ] = inner_value
                end
            end
            return new_hash  
        }
        self.deep_yield { | y | do_one_thing.( y ) }
    end 
    
    def deep_yield( yield_to: nil, &block )
#       yield_to == nil means yield_to all classes
#       The 'yield_to' param can be a single Object type (eg. deep_yield( Hash ) ) or an array of them.
        if self.respond_to?( :map ) 
            maybe_with_a_bang = __callee__.end_with?( '!' ) ? '!' : ''
            case true
            when self.is_a?( Hash ) 
                transform_method = 'transform_values'
            when self.is_a?( Array )
                transform_method = 'map'
            else
                transform_method = nil
            end
            if transform_method.nil?
                SE.puts "#{SE.lineno}: No idea what to do with a '#{self.class}'."
                result = self
            else
                result = self.send( transform_method + maybe_with_a_bang ) { | v | 
                         v.send( __callee__, yield_to: yield_to, &block ) }
            end
        else
            result = self            
        end 
#       SE.q {['yield_to', 'self.class']}

#       The 'yield_to' variable will have the .class results of the passed-in
#       classes (e.g. Hash passes-in the result of Hash.class), which is why 
#       the statement below reads: ... self.class.in?( *yield_to ).  
        if block_given? && ( yield_to.nil? || self.class.in?( *yield_to ) )  
            result = yield( result )
        end
        return result
    end

    alias_method :deep_yield!, :deep_yield
    

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
        return ! self.in?( *args )
    end
    
    def not_respond_to?( *args )
        return ! self.respond_to?( *args )
    end
    
end
