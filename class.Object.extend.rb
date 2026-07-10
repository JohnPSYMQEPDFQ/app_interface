
class Object
#
#   Return column c
#       If self is a hash, 'c' can be a key.

    def column( c )
        self.map{ | row | row[ c ] }
    end
#
    def blank?( )
        return true if self.nil?
        return ! self.match?( /\S/ )       
    end
    def not_blank?( )
        return ! self.blank?
    end
    
    def in?( *args )
        return args.flatten.include?( self )
    end
    def not_in?( *args )
        return ! self.in?( *args )
    end
 
#   SEE THE END for all the KNOTS! 

    def to_CKA_h( sort_TF: false, _parent_CKA: [], _flattened_H: {} )
#

#   This method only builds the "endpoints" of the nested structure.  If you need all the combinations (like
#   if you want to rebuild a new structure from the composite-keys) the following code will return all combinations
#   of the keys:      
#       arr = comp_key_A.keys.flat_map { | ck | ( 1..ck.size ).map { | i | ck.take( i ) } }.uniq
#                            .sort_by { | e | [ e.object_id ] }

        self.each_with_index do | thingy, idx |
            case true
            when self.respond_to?( :transform_keys ) && thingy.is_a?( Array )
                SE.raise if ( thingy.length != 2 )
                key   = thingy.first 
                value = thingy.last
            else
                key   = idx
                value = thingy
            end
               
            if _parent_CKA.empty? 
                current_CKA =               [ key ]
            else
                current_CKA = _parent_CKA + [ key ]                                                           
            end
            if value.not_nil? && value.respond_to?( :each_with_index ) && value.is_not_a?( Range )
                value.to_CKA_h(     sort_TF: sort_TF,
                                _parent_CKA: current_CKA, 
                               _flattened_H: _flattened_H ) 
            else
                _flattened_H[ current_CKA ] = value
            end
        end
        return sort_TF ? _flattened_H.sort_by{ | key, value | key }.to_h : _flattened_H
    end    
    
    def _cka_value_stack_A( the_CKA )     
               
        if the_CKA.empty?
            SE.raise 
            return nil
        end        
       #SE.q {'the_CKA'}    
        ck_attempted_A     = [ ]
        cka_value_stack_A  = [ self ]    #       NOTE: The last entry on the stack is the value !!!!
        key                = nil
        value              = nil
  
        0.upto( the_CKA.length ) do | idx |     # It will never hit the limit, see the last 'break'
           #SE.q {'idx'}
            break if ( cka_value_stack_A.last.nil? )
            key = the_CKA[ idx ]
           #SE.q {'key'}
            SE.raise if ( key.nil? )
            ck_attempted_A.push( key )
            case true
            when cka_value_stack_A.last.respond_to?( :has_key? )
                break if ( not cka_value_stack_A.last.has_key?( key ) )
                value     = cka_value_stack_A.last[ key ]
            when cka_value_stack_A.last.is_a?( Array )
                break if ( not key.is_a?( Integer ) )
                break if ( key > cka_value_stack_A.last.maxindex )
                value     = cka_value_stack_A.last[ key ]
            when cka_value_stack_A.last.is_a?( Set )
                value     = cka_value_stack_A.last.to_a[ key ]
            else
                value     = cka_value_stack_A.last[ key ]
            end
           #SE.q {['key','value', 'idx', 'the_CKA.maxindex']}            
            cka_value_stack_A.push( value )    # Don't do a .dup, as it will change the object_id 
            break if ( idx >= the_CKA.maxindex )
        end 
        if ( cka_value_stack_A.length != the_CKA.length + 1 )   
            SE.puts "#{SE.lineno}, called from: #{SE.stack[2]}: composite-key not-found '#{the_CKA}'"                 
            ck_attempted_A.each_index do | idx |
                SE.print "Object[ #{ck_attempted_A[ idx ].inspect} ] "
                if ( idx < cka_value_stack_A.maxindex )
                    SE.print "is a '#{cka_value_stack_A[ idx + 1 ].class}', "
                else
                    SE.print "not-found."
                end
            end
            SE.puts ''
            SE.q {['cka_value_stack_A.length','the_CKA.length']}
            SE.q {'the_CKA'}
            SE.q {'ck_attempted_A'}
            SE.q {'cka_value_stack_A'}
            raise 
        end        
        return cka_value_stack_A                 
    end

    def value__using_CKA!( the_CKA, &block )
  
#   This BANG! method is used to change the value in the SOURCE hash using a CKA, when
#   used with a &block.
#           
#           For example:
#               record_H.value__using_CKA( the_CKA ){ 'xxx' }   
#                   Changes the value at the_CKA in record_H to 'xxx'.
#
#           Without a BANG!, or if no block is given, it simply returns the existing value.
#
#           WARNING!  This method does NOT change the CKA hash.  That's got to be done outside 
#                     using the value passed back!
#  
#
#   NOTE:   This method IS NOT NEEDED to get values from a flattened hash HAVING a CKA.   
#
#           For example:
#               record_H -> flattened_CKA_H
#               record_H.value__using_CKA( the_CKA )
#                   -NOT-
#               flattened_CKA_H.value__using_CKA( come_CK ) 
#                   -JUST DO THIS-
#               flattened_CKA_H[ the_CKA ]
#                   
#           Using the above example:
#               record_H.value__using_CKA( the_CKA )
#                   -IS THE SAME AS-
#               record_H.dig( *the_CKA )
#                   except the #dig will return nil if 'the_CKA' isn't in record_H
#                   and dig won't work on Sets

        with_a_BANG_TF  = __callee__[ -1 ] == '!'
        SE.raise if ( the_CKA.maxindex < 0 )
       #SE.q {'the_CKA'} 
     
        cka_value_stack_A = self._cka_value_stack_A( the_CKA )
       #SE.q {'cka_value_stack_A'}
        SE.raise if ( cka_value_stack_A.length < 2 )         
        the_CKA_key     = the_CKA[ -1 ]
        the_CKA_value   = cka_value_stack_A[ -1 ] 
        if ( block_given? )
            the_CKA_value = the_CKA_value.yield_self( &block )
            if ( with_a_BANG_TF )
                SE.raise if ( cka_value_stack_A[ -2 ].has_no_key?( the_CKA_key ) )
                cka_value_stack_A[ -2 ][ the_CKA_key ] = the_CKA_value
            end
        end
        return the_CKA_value
    end
    alias_method :value__using_CKA, :value__using_CKA!

    def to_h__using_CKA( the_CKA )
        SE.raise if ( the_CKA.maxindex < 0 ) 
        cka_value_stack_A = self._cka_value_stack_A( the_CKA )
        SE.raise if ( cka_value_stack_A.length < 2 )         
        
        container = cka_value_stack_A[ -2 ]
        container = container.yield_self block if ( block_given? )
        return container  
    end
    
       
    def deep_copy( )
#       This is the equivalent of doing a .dup ( NOT a .clone ) on each embedded object.
#       See deep_yield (below) for doing a deep_clone.
        begin
            return Marshal.load( Marshal.dump( self ) )
        rescue StandardError => e
            SE.puts "#{SE.lineno}: self.class='#{self.class}'"
            raise e.message   
        end
    end

    def deep_object_id( object_id_A = [] )
    
        # Add the ID of the current container/object itself:
        object_id_A << [ self.object_id, self.class, self ]
       
        case true
        when self.is_a?( Hash )
            self.each do | key, value |
                key.deep_object_id( object_id_A )   # Keys are objects too!
                value.deep_object_id( object_id_A )
            end
        when self.respond_to?( :each )
            self.each do | element | 
                element.deep_object_id( object_id_A )
            end
        end
      
        object_id_A
    end
    
=begin
    Notes on deeply__(Pre|Post)_yield.
    
    The conceptual difference lies in dependency direction and execution timing.

    Choosing between pre-order and post-order changes whether you act on an object 
    before or after you explore its deeper contents.

    The Core Conceptual Difference

    *   Pre-order (Top-Down/Context First): You process the parent container before 
        knowing anything about its contents. This is a discovery-first approach. You establish 
        the outer context before dealing with the internal details.
        
    *   Post-order (Bottom-Up/Result First): You process all internal contents before acting 
        on the parent container. This is a synthesis-first approach. You gather all the small 
        details to build or evaluate the big picture.
        
    Real-World Concept Comparison

        Feature     Pre-Order (Yield Before)        Post-Order (Yield After)
        
        Flow        Top-down                        Bottom-up
        
        Main Idea   "Here is the container,         "Let's finish the contents, then seal the 
                    now let's look inside."         container."
        
        Best For    Searching, cloning, or          Operations requiring child data to process 
                    filtering from the top.         the parent.


    The default is: deep_yield[!] is aliased to deeply__post_yield[!]  (It seemed to most defaulty at the time...)
    
        Option parameter:  fail_on__yield_nil_TF == true   means: If the yield returns nil and the value wasn't already nil, fail. 
    
        DON'T FORGET: The 'yield' code MUST return something!!! 
                      If nothing is returned, that's a 'nil'.  If 'fail_on__yield_nil_TF' is true
                      AND the pre-yield value wasn't nil, the method will fail.

        Methods: 
            deep_yield! { | y | y }   Change Obj in-place.
            deep_yield  { | y | y }   Make a new Obj. 
           

        To do the equivalent of:
            deep_freeze       ->  deep_yield { | y | y.freeze }   Freeze a new Obj
            deep_freeze!      ->  deep_yield!{ | y | y.freeze }   Freeze existing Obj
            deep_copy         ->  { | y | y.dup }                 Make new Obj. Anything frozen will become unfrozen ( by the .dup )
            deep_clone        ->  { | y | y.clone }               Make new Obj. Anything frozen will stay frozen ( by the .clone )
            deep_delete[!]    ->  { | y | y.delete_if { | k, v | k.not_in?( some_A ) } }


=end

    def _deep_yield(               a_new_O = nil,  # Passed to the 'yield'
                     fail_on__yield_nil_TF: true,                                       
                                  do_debug: false, 
                              _my_parent_O: self.class.superclass, 
                            _recurse_level: 1,                                     
                                            &block 
                     )
                     
#   See above for documentation... 
  
        if not ( fail_on__yield_nil_TF.is_a?( TrueClass ) || fail_on__yield_nil_TF.is_a?( FalseClass ) )
            SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: 'fail_on__yield_nil_TF:' not T or F"
            raise
        end        
       
        case true
        when __callee__ == :deep_yield       # This 
            yield_location = :post           # seems
            with_a_BANG_TF = false           # to 
        when __callee__ == :deep_yield!      # be 
            yield_location = :post           # the
            with_a_BANG_TF = true            # default.
        when __callee__ == :deep_post_yield
            yield_location = :post
            with_a_BANG_TF = false
        when __callee__ == :deep_post_yield!
            yield_location = :post
            with_a_BANG_TF = true
        when __callee__ == :deep_pre_yield
            yield_location = :pre
            with_a_BANG_TF = false
        when __callee__ == :deep_pre_yield!
            yield_location = :pre
            with_a_BANG_TF = true
        when __callee__ == :deep_both_yield
            yield_location = :both
            with_a_BANG_TF = false
        when __callee__ == :deep_both_yield!
            yield_location = :both
            with_a_BANG_TF = true
        else
            SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: No idea who or what I am..."
            SE.q {['__callee__']}
            raise
        end
        
        recurse_LP = lambda{ | recurse_this_O |
            case true
            when recurse_this_O.respond_to?( :transform_values! )
                values_iteration_method = :transform_values!   # These MUST BE !'s, because the 'recurse_this_O'
            when recurse_this_O.respond_to?( :map! )           # object is what's being changed.  See the 'with_a_BANG_TF
                values_iteration_method = :map!                # code below.  It's up to the yield_self code to get the 
            else                                               # object_id correct based on the '!' (or not).
                values_iteration_method = nil
            end
            if values_iteration_method.nil?
                SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: No idea what to do with a '#{recurse_this_O.class}'."
            else
                SE.puts "Bf USING: #{_recurse_level}, #{values_iteration_method}" if ( do_debug )
                recurse_this_O.send( values_iteration_method ) do | thingy |
                    SE.puts "Bf RECUR: #{_recurse_level}, #{thingy.class} of #{recurse_this_O.class}, object_id=#{thingy.object_id}, '#{thingy}'" if ( do_debug )
                    result_of_sending_thingy = thingy.send( __callee__,
                                                            a_new_O, 
                                     fail_on__yield_nil_TF: fail_on__yield_nil_TF,                                                                                    
                                                  do_debug: do_debug,
                                              _my_parent_O: recurse_this_O,
                                            _recurse_level: _recurse_level + 1,                                                            
                                                            &block )
                    SE.puts "Af RECUR: #{_recurse_level}, #{result_of_sending_thingy.class} of #{recurse_this_O.class}, object_id=#{result_of_sending_thingy.object_id}, '#{result_of_sending_thingy}'" if ( do_debug )
                    next result_of_sending_thingy
                end
            end
            if ( with_a_BANG_TF && self.object_id != recurse_this_O.object_id )
                SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: In '!' mode, but a container's object-id changed."
                SE.q {['self.object_id','self']}
                SE.q {['recurse_this_O.object_id','recurse_this_O']}
                SE.q {'_recurse_level'}
                raise
            end
            return recurse_this_O
        } 
        yield_LP = lambda{ | yield_this_O, yield_location |
            begin
                yielded_O = yield( yield_this_O, _my_parent_O, _recurse_level, a_new_O ) 
            rescue
                if ( yield_this_O.frozen? )
                    SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: '#{yield_this_O.class}' is frozen!"  
                    SE.puts "As-of 5/20/2026, it seems values in Set's are frozen..."
                end
                raise
            end
            if ( with_a_BANG_TF == false && yielded_O.object_id == yield_this_O.object_id )
                yielded_O = yielded_O.dup                                     
            end
            SE.puts "Af #{yield_location}: #{_recurse_level}, #{yielded_O.class} of #{_my_parent_O.class}, object_id=#{yielded_O.object_id}, '#{yielded_O}'" if ( do_debug )          
            if ( yielded_O.nil? && fail_on__yield_nil_TF == true && yield_this_O.not_nil? )
                SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: Fail on nil!"
                SE.q{ 'fail_on__yield_nil_TF' }
                SE.q{ 'yielded_O' }
                SE.q{ 'yield_this_O' }
                raise
            end                   
            return yielded_O
        }
        
        SE.puts "ENTER:    #{_recurse_level}, #{self.class} of #{_my_parent_O.class}, object_id=#{self.object_id}, '#{self}'" if ( do_debug )

        thee_O = ( with_a_BANG_TF ) ? self : self.dup

        if ( block_given? and ( yield_location == :pre || yield_location == :both ) )
            thee_O = yield_LP.( thee_O, 'Ypre ' )       
        end        

        if ( thee_O.respond_to?( :each ) )
            thee_O = recurse_LP.( thee_O )     
        end 

        if ( block_given? and ( yield_location == :post || yield_location == :both ) )
            thee_O = yield_LP.( thee_O, 'Ypost' )              
        end
 
        SE.puts "RETURN:   #{_recurse_level}, #{thee_O.class} of #{_my_parent_O.class}, object_id=#{thee_O.object_id}, '#{thee_O}'" if ( do_debug )
        return thee_O
       
    end
    
    alias_method :deep_yield       , :_deep_yield   #  This seems to be the default name,
    alias_method :deep_yield!      , :_deep_yield   #  which also defaults to 'post_yield'.  See above.
        
    alias_method :deep_pre_yield   , :_deep_yield
    alias_method :deep_pre_yield!  , :_deep_yield
    
    alias_method :deep_post_yield  , :_deep_yield
    alias_method :deep_post_yield! , :_deep_yield   

    alias_method :deep_both_yield  , :_deep_yield
    alias_method :deep_both_yield! , :_deep_yield       

=begin
    def deeply__post_yield(          a_new_O = nil,
                        fail_on__yield_nil_TF: true,                                       
                                     do_debug: false, 
                                   _my_parent: self.class.superclass, 
                               _recurse_level: 1,                                     
                                               &block 
                            )

#   See above for documentation...                  

        if ( not ( fail_on__yield_nil_TF.is_a?( TrueClass ) || fail_on__yield_nil_TF.is_a?( FalseClass ) ) )
            SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: 'fail_on__yield_nil_TF:' not T or F"
            raise
        end
        
       #if ( _recurse_level == 1 )
       #    beginning_deep_object_id_A = self.deep_object_id
       #end
       
        with_a_BANG_TF  = __callee__[ -1 ] == '!'
                        
        SE.puts "ENTER:    #{_recurse_level}, #{self.class} of #{_my_parent.class}, object_id=#{self.object_id}, '#{self}'" if ( do_debug )

        pre_yield_O = ( with_a_BANG_TF ) ? self : self.dup        
        if ( pre_yield_O.respond_to?( :each ) )
            case true
            when pre_yield_O.respond_to?( :transform_values! )
                values_iteration_method = :transform_values!   # These MUST BE !'s, because the 'pre_yield_O'
            when pre_yield_O.respond_to?( :map! )              # object is what's being changed.  See the 'with_a_BANG_TF
                values_iteration_method = :map!                # code below.  It's up to the yield_self code to get the 
            else                                               # object_id correct based on the '!' (or not).
                values_iteration_method = nil
            end
            if values_iteration_method.nil?
                SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: No idea what to do with a '#{pre_yield_O.class}'."
            else
                SE.puts "Bf USING: #{_recurse_level}, #{values_iteration_method}" if ( do_debug )
                pre_yield_O.send( values_iteration_method ) do | thingy |
                    SE.puts "Bf RECUR: #{_recurse_level}, #{thingy.class} of #{pre_yield_O.class}, object_id=#{thingy.object_id}, '#{thingy}'" if ( do_debug )
                    result_of_sending_thingy = thingy.send( __callee__,
                                                            a_new_O, 
                                     fail_on__yield_nil_TF: fail_on__yield_nil_TF,                                                                                    
                                                  do_debug: do_debug,
                                                _my_parent: pre_yield_O,
                                            _recurse_level: _recurse_level + 1,                                                            
                                                            &block )
                    SE.puts "Af RECUR: #{_recurse_level}, #{result_of_sending_thingy.class} of #{pre_yield_O.class}, object_id=#{result_of_sending_thingy.object_id}, '#{result_of_sending_thingy}'" if ( do_debug )
                    next result_of_sending_thingy
                end
            end
            if ( with_a_BANG_TF && self.object_id != pre_yield_O.object_id )
                SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: In '!' mode, but a container's object-id changed."
                SE.q {['self.object_id','self']}
                SE.q {['pre_yield_O.object_id','pre_yield_O']}
                SE.q {'_recurse_level'}
                raise
            end
        end 

        if ( block_given? )
            begin
                yielded_O = yield( pre_yield_O, a_new_O, _recurse_level) 
            rescue
                if ( pre_yield_O.frozen? )
                    SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: '#{pre_yield_O.class}' is frozen!"  
                    SE.puts "As-of 5/20/2026, it seems values in Set's are frozen..."
                end
                raise
            end
            if ( with_a_BANG_TF == false && yielded_O.object_id == pre_yield_O.object_id )
                yielded_O = yielded_O.dup                                     
            end
            SE.puts "Af YIELD: #{_recurse_level}, #{yielded_O.class} of #{_my_parent.class}, object_id=#{yielded_O.object_id}, '#{yielded_O}'" if ( do_debug )          
            if ( yielded_O.nil? && fail_on__yield_nil_TF == true && pre_yield_O.not_nil? )
                SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: Fail on nil!"
                SE.q{ 'fail_on__yield_nil_TF' }
                SE.q{ 'yielded_O' }
                SE.q{ 'pre_yield_O' }
                raise
            end                   
        else            
            yielded_O = ( with_a_BANG_TF ) ? pre_yield_O : pre_yield_O.dup
        end
        
       #if ( _recurse_level == 1 )
       #    ending_deep_object_id_A = yielded_O.deep_object_id
       #    SE.q {'beginning_deep_object_id_A' }
       #    SE.q {'ending_deep_object_id_A' }
       #end     
       
        SE.puts "RETURN:   #{_recurse_level}, #{yielded_O.class} of #{_my_parent.class}, object_id=#{yielded_O.object_id}, '#{yielded_O}'" if ( do_debug )
        return yielded_O
       
    end



    def deeply__pre_yield(           a_new_O = nil,
                        fail_on__yield_nil_TF: true,                                       
                                     do_debug: false, 
                                   _my_parent: self.class.superclass, 
                               _recurse_level: 1,                                     
                                               &block 
                            )                  

#   See above for documentation... 

        if ( not ( fail_on__yield_nil_TF.is_a?( TrueClass ) || fail_on__yield_nil_TF.is_a?( FalseClass ) ) )
            SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: 'fail_on__yield_nil_TF:' not T or F"
            raise
        end
        
       #if ( _recurse_level == 1 )
       #    beginning_deep_object_id_A = self.deep_object_id
       #end
       
        with_a_BANG_TF  = __callee__[ -1 ] == '!'
                        
        SE.puts "ENTER:    #{_recurse_level}, #{self.class} of #{_my_parent.class}, object_id=#{self.object_id}, '#{self}'" if ( do_debug )

        if ( block_given? )
            begin
                yielded_O = yield( self, a_new_O, _recurse_level) 
            rescue
                if ( self.frozen? )
                    SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: '#{self.class}' is frozen!"  
                    SE.puts "As-of 5/20/2026, it seems values in Set's are frozen..."
                end
                raise
            end
            if ( with_a_BANG_TF == false && yielded_O.object_id == self.object_id )
                yielded_O = yielded_O.dup                                     
            end
            SE.puts "Af YIELD: #{_recurse_level}, #{yielded_O.class} of #{_my_parent.class}, object_id=#{yielded_O.object_id}, '#{yielded_O}'" if ( do_debug )          
            if ( yielded_O.nil? && fail_on__yield_nil_TF == true && self.not_nil? )
                SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: Fail on nil!"
                SE.q{ 'fail_on__yield_nil_TF' }
                SE.q{ 'yielded_O' }
                SE.q{ 'self' }
                raise
            end                   
        else            
            yielded_O = ( with_a_BANG_TF ) ? self : self.dup
        end

        
        if ( yielded_O.respond_to?( :each ) )
            case true
            when self.respond_to?( :transform_values! )
                values_iteration_method = :transform_values!   # These MUST BE !'s, because the 'yielded_O'
            when self.respond_to?( :map! )                     # object is what's being changed.  See the 'with_a_BANG_TF
                values_iteration_method = :map!                # code below.  It's up to the yield_self code to get the 
            else                                               # object_id correct based on the '!' (or not).
                values_iteration_method = nil
            end
            if values_iteration_method.nil?
                SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: No idea what to do with a '#{yielded_O.class}'."
            else
                SE.puts "Bf USING: #{_recurse_level}, #{values_iteration_method}" if ( do_debug )
                yielded_O.send( values_iteration_method ) do | thingy |
                    SE.puts "Bf RECUR: #{_recurse_level}, #{thingy.class} of #{yielded_O.class}, object_id=#{thingy.object_id}, '#{thingy}'" if ( do_debug )
                    result_of_sending_thingy = thingy.send( __callee__,
                                                            a_new_O, 
                                     fail_on__yield_nil_TF: fail_on__yield_nil_TF,                                                                                    
                                                  do_debug: do_debug,
                                                _my_parent: yielded_O,
                                            _recurse_level: _recurse_level + 1,                                                            
                                                            &block )
                    SE.puts "Af RECUR: #{_recurse_level}, #{result_of_sending_thingy.class} of #{yielded_O.class}, object_id=#{result_of_sending_thingy.object_id}, '#{result_of_sending_thingy}'" if ( do_debug )
                    next result_of_sending_thingy
                end
            end
            if ( with_a_BANG_TF && self.object_id != yielded_O.object_id )
                SE.puts "#{SE.lineno}, called from: #{SE.stack[3]}: In '!' mode, but a container's object-id changed."
                SE.q {['self.object_id','self']}
                SE.q {['yielded_O.object_id','yielded_O']}
                SE.q {'_recurse_level'}
                raise
            end
        end 

       #if ( _recurse_level == 1 )
       #    ending_deep_object_id_A = yielded_O.deep_object_id
       #    SE.q {'beginning_deep_object_id_A' }
       #    SE.q {'ending_deep_object_id_A' }
       #end        
        SE.puts "RETURN:   #{_recurse_level}, #{yielded_O.class} of #{_my_parent.class}, object_id=#{yielded_O.object_id}, '#{yielded_O}'" if ( do_debug )
        return yielded_O
       
    end
=end

#   A world of KNOTS!!    

    def not_frozen?
        return ! self.frozen?
    end

    def not_nil?
        return ! self.nil?
    end

    def not_empty?
        return ! self.empty?
    end
    
    def is_not_a?( p1 )
        return ! self.is_a?( p1 )
    end
    alias_method :not_a?, :is_not_a? 
    
    def not_match?( p1 )
        return ! self.match?( p1 )
    end
    
    def not_include?( p1 )
        return ! self.include?( p1 )
    end
    
    def not_between?( *args )
        return ! self.between?( *args )
    end
    
    def not_respond_to?( *args )
        return ! self.respond_to?( *args )
    end
    
end
