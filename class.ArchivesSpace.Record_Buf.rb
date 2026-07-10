
class Record_Buf < Buffer_Base

public  attr_reader :http_calls_O, :buffer_action_stack_A
private attr_writer :http_calls_O, :buffer_action_stack_A

BUFFER_ACTION_INIT   = :BUFFER_ACTION_INIT
BUFFER_ACTION_CREATE = :BUFFER_ACTION_CREATE
BUFFER_ACTION_READ   = :BUFFER_ACTION_READ
BUFFER_ACTION_LOAD   = :BUFFER_ACTION_LOAD
BUFFER_ACTION_STORE  = :BUFFER_ACTION_STORE
BUFFER_ACTION_DELETE = :BUFFER_ACTION_DELETE
    
    def initialize( p1_aspace_O )
        super( )
        self.rec_id                = self.rec_id.to_s if ( self.rec_id.is_a? (Integer) )
        self.http_calls_O          = p1_aspace_O.http_calls_O
        self.buffer_action_stack_A = [ BUFFER_ACTION_INIT, BUFFER_ACTION_INIT ] 
        if ( self.http_calls_O.is_not_a?( Http_Calls ) ) then
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "self.http_calls_O.is_not_a?( Http_Calls )"
            SE.q {'self.http_calls_O'}
            raise
        end
    end
    
    def jsonmodel_filter__what_to_keep( jsonmodel_type )
        if ( jsonmodel_type.nil? || jsonmodel_type == '' )
        then   
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "jsonmodel_type is nil or ''"
            raise
        end
        jsonmodel_H = Record_Format.new( jsonmodel_type ).record_H
        return nil if ( jsonmodel_H.empty? )
#
#       Additional stuff to keep:
        h = { K.child_count => '',
              K.parent_id => '',
              K.position => '',
              K.ref => '', 
              K.ref_id => '',
              K.tree => '',
              K.uri => '',  
              K.lock_version => '',     # Needed to update a record.
            }
        jsonmodel_H.merge!( h )
        return jsonmodel_H
    end
    
    def what_to_throw_away( )
        h = {   K.created_by => '',
                K.last_modified_by => '',
                K.create_time => '',
                K.system_mtime => '',
                K.user_mtime => '',
            }
        return h
    end
    
    def filter_jsonmodel( jsonmodel_H )
        if ( jsonmodel_H.is_not_a?( Hash )) then
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.ap "jsonmodel_H is a #{jsonmodel_H.class} not a hash:", jsonmodel_H
            raise
        end
        if ( jsonmodel_H.has_key?( K.jsonmodel_type ) ) then
            jsonmodel_filter__what_to_keep_H = jsonmodel_filter__what_to_keep( jsonmodel_H[ K.jsonmodel_type ] )
        else
            jsonmodel_filter__what_to_keep_H = nil
        end
        h = {}
        begin
            jsonmodel_H.sort.to_h.each_pair do | k, v |
#               puts "k = #{k}, v = #{v}, v.class = #{v.class}"
                if ( v.is_a?( Array )) then
                    a = v.map do | e |
                        if ( e.is_a?( Hash ) && e.has_key?( K.jsonmodel_type )) then
                            filter_jsonmodel( e )
                        else
                            e
                        end
                    end
                    h.merge!( { k => a } )
                elsif ( v.is_a?( Hash ) ) then
                    h.merge!( { k => filter_jsonmodel( v ) } )
                else
                    if ( jsonmodel_filter__what_to_keep_H ) then
                        h.merge!( { k => v } ) if ( jsonmodel_filter__what_to_keep_H.has_key?( k )) 
                    else
                        h.merge!( { k => v } ) if ( what_to_throw_away.has_no_key?( k ))         
                    end
                end
            end
        rescue
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.q {'jsonmodel_H'}
            raise
        end
        return h
    end
    
    def create
        if ( self.buffer_action_stack_A.last.not_in?( BUFFER_ACTION_INIT ) )
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "A 'create' should follow a ( INIT ), not a #{self.buffer_action_stack_A.last}"
            SE.q {'self.buffer_action_stack_A'}
            raise
        end
        self.buffer_action_stack_A = [ self.buffer_action_stack_A.last, BUFFER_ACTION_CREATE ]

        if self.uri_addr.not_nil? 
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "The uri-address '#{self.uri_addr}' set to nil for create." 
            self.uri_addr = nil
        end
        if self.rec_id.not_nil? 
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "The rec-id '#{self.rec_id}' set to nil for create." 
            self.rec_id = nil
        end
        self.record_H.clear               # If creating into an already existing buffer
                                          # the data should be cleared out.
        self.record_H.merge!( Record_Format.new( self.rec_jsonmodel_type ).record_H )
        return self
    end
    
    def load( external_record_H, filter_record_TF: false )
        if ( self.buffer_action_stack_A.last.not_in?( BUFFER_ACTION_INIT, BUFFER_ACTION_CREATE, BUFFER_ACTION_READ ) ) 
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "A 'load' should follow a ( INIT, CREATE, READ ), not a #{self.buffer_action_stack_A.last}"
            SE.q {'self.buffer_action_stack_A'}
            raise
        end
        self.buffer_action_stack_A = [ self.buffer_action_stack_A.last, BUFFER_ACTION_LOAD ]

#       NOTE:  The load is merged into what is already in the buffer. This is intentional.  
       
#       SE.puts "#{SE.lineno}"
#       SE.ap "external_record_H:", external_record_H
#       SE.ap "filter_jsonmodel_template_H:", filter_jsonmodel_template_H
        if not ( external_record_H[K.jsonmodel_type] && external_record_H[K.jsonmodel_type] == self.rec_jsonmodel_type ) 
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "I was expecting a #{self.rec_jsonmodel_type} jsonmodel_type record."
            SE.q {'self.uri_addr'}
            SE.q {'external_record_H'}
            raise
        end 

        if ( external_record_H.has_no_key?( K.jsonmodel_type ) ) then
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "Was expecting a jsonmodel_type in external_record_H"
            SE.q {'self.uri_addr'}
            SE.q {'external_record_H'}
            raise
        end
   
#       if the previous buffer action was :create, then delete any keys that aren't in the record_H
#       created by Record_Format.new( self.rec_jsonmodel_type ) 

        if self.buffer_action_stack_A.first == BUFFER_ACTION_CREATE
            external_record_H.delete_if { | k, v | k.not_in?( record_H.keys ) }
        end
         
        load_result_H = Hash.new              
        if ( filter_record_TF ) then
#           SE.ap "Before:", external_record_H
            load_result_H.merge!( filter_jsonmodel( external_record_H ) )
#           SE.ap "After:", external_record_H
        else
            load_result_H.merge!( external_record_H )
        end
        
        if ( self.buffer_action_stack_A.last.not_in?( BUFFER_ACTION_CREATE, BUFFER_ACTION_LOAD ) ) then
            if ( self.uri_addr != external_record_H.fetch( K.uri ) ) then
                SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
                SE.puts "BECAUSE: self.uri_addr != external_record_H[ K.uri ]"
                SE.q {'self.uri_addr'}
                SE.q {'external_record_H'}
                raise            
            end
            if ( self.rec_id != external_record_H.fetch( K.uri ).trailing_digits ) then
                SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
                SE.puts "BECAUSE: self.rec_id != external_record_H.fetch( K.uri ).trailing_digits"
                SE.q {'self.rec_id'}
                SE.q {'external_record_H.fetch( K.uri ).trailing_digits'}
                SE.q {'external_record_H'}
                raise            
            end
        end
        return load_result_H            
    end
    
    def read( filter_record_TF: false )
        if ( self.buffer_action_stack_A.last.in?( BUFFER_ACTION_CREATE, BUFFER_ACTION_LOAD ) ) 
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "A 'read' should NOT follow a ( CREATE, LOAD )"
            SE.q {'self.buffer_action_stack_A'}
            raise
        end
        self.buffer_action_stack_A = [ self.buffer_action_stack_A.last, BUFFER_ACTION_READ ]
        
        self.record_H.clear               # If reading into an already existing buffer
                                          # the data should be cleared out so the 
                                          # 'cant_change' logic won't be applied to the newly
                                          # read record.   
        http_response_body_H = self.http_calls_O.get( self.uri_addr )
#       SE.puts "#{SE.lineno}"
#       SE.ap "http_response_body_H:", http_response_body_H
#       SE.ap "filter_jsonmodel_template_H:", filter_jsonmodel_template_H
        if not ( http_response_body_H[K.jsonmodel_type] && http_response_body_H[K.jsonmodel_type] == self.rec_jsonmodel_type )
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "I was expecting a #{self.rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "self.uri_addr = #{self.uri_addr}"
            SE.ap "http_response_body_H:", http_response_body_H
            raise
        end 
        if ( filter_record_TF ) then
#           SE.ap "Before:", http_response_body_H
            http_response_body_H = filter_jsonmodel( http_response_body_H )
#           SE.ap "After:", http_response_body_H
        end
#       SE.ap "http_response_body_H:", http_response_body_H
        return http_response_body_H
    end
    
    def store
        if ( self.buffer_action_stack_A.last.not_in?( BUFFER_ACTION_LOAD, BUFFER_ACTION_READ, BUFFER_ACTION_CREATE ) ) 
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "A 'store' should follow a ( LOAD, READ, CREATE ), not a #{self.buffer_action_stack_A.last}"
            SE.q {'self.buffer_action_stack_A'}
            raise
        end
        self.buffer_action_stack_A = [ self.buffer_action_stack_A.last, BUFFER_ACTION_STORE ]
        
#       SE.ap self.record_H
        if not ( self.record_H[K.jsonmodel_type] && self.record_H[K.jsonmodel_type] == self.rec_jsonmodel_type )  
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "I was expecting a #{self.rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "self.uri_addr = #{self.uri_addr}"
            SE.ap "self.record_H:", self.record_H
            raise
        end 
        if ( self.record_H.nil? || ( self.record_H.has_key?( K.uri) && self.record_H[ K.uri ] != self.uri_addr ) ) then
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "Current self.record_H[ K.uri ] != self.uri_addr"
            SE.puts "self.uri_addr = #{self.uri_addr}"
            SE.ap "Current self.record_H:", self.record_H
            raise
        end
        if ( self.http_calls_O.aspace_O.allow_updates ) then
            http_response_body_H = self.http_calls_O.post_with_body( self.uri_addr, self.record_H )
            if not ( http_response_body_H[K.status].in?( [ 'Created', 'Updated' ] ) ) 
                SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
                SE.puts "Store failed!"
                SE.puts "self.uri_addr = #{self.uri_addr}"
                SE.puts "self.record_H:", self.record_H
                SE.ap "http_response_body_H:", http_response_body_H
                raise
            end
           #lock_version = self.record_H.fetch( K.lock_version, 0 )  Not sure what this was for
           #lock_version += 1
        else
            stringer = "NO UPDATE MODE: #{self.uri_addr}"
            stringer.concat ( "/999999999" ) if self.rec_id.nil? 
            http_response_body_H = { K.uri => stringer }
        end
        return http_response_body_H
    end

    def delete
        if ( self.buffer_action_stack_A.last.not_in?( BUFFER_ACTION_READ ) ) 
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "A 'delete' should follow a ( READ ), not a #{self.buffer_action_stack_A.last}"
            SE.q {'self.buffer_action_stack_A'}
            raise
        end
        self.buffer_action_stack_A = [ self.buffer_action_stack_A.last, BUFFER_ACTION_DELETE ]
        if not ( self.record_H[K.jsonmodel_type] && self.record_H[K.jsonmodel_type] == self.rec_jsonmodel_type )  
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "I was expecting a #{self.rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "self.uri_addr = #{self.uri_addr}"
            SE.ap "self.record_H:", self.record_H
            raise
        end 
        if ( self.record_H.nil? || ! ( self.record_H.has_key?( K.uri) && self.record_H[ K.uri ] == self.uri_addr ) ) then
            SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
            SE.puts "Current self.record_H[ K.uri ] != self.uri_addr"
            SE.puts "self.uri_addr = #{self.uri_addr}"
            SE.ap "Current self.record_H:", self.record_H
            raise
        end
        if ( self.http_calls_O.aspace_O.allow_updates ) then
            http_response_body_H = self.http_calls_O.delete( self.uri_addr, { } )
            if ( http_response_body_H[K.status] != 'Deleted' ) then 
                SE.puts "#{SE.lineno}, called from: #{SE.my_caller}:  =============================================="
                SE.puts "Delete failed!"
                SE.puts "self.uri_addr = #{self.uri_addr}"
                SE.ap "http_response_body_H:", http_response_body_H
                raise
            end
            http_response_body_H = {K.uri => self.uri_addr}
        else
            http_response_body_H = {K.uri => "NO UPDATE MODE: #{self.uri_addr}"}
        end
        return http_response_body_H
    end
end




