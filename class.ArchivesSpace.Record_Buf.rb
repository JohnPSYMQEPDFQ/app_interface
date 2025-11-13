=begin

Variable Abbreviations:
        AO = Archival Object ( Resources are an AO too, but they have their own structure. )
        AS = ArchivesSpace
        IT = Instance Type
        TC = Top Container
        SC = Sub-Container
        _H = Hash
        _J = Json string
        _RES = Regular Expression String, e.g: find_bozo_RES = '\s+bozo\s+'
        _RE  = Regular Expression, e.g.: find_bozo_RE = /#{find_bozo_RES}/
        _A = Array
        _O = Object
        _Q = Query
        _C = Class of Struct
        _S = Structure of _C 
        __ = reads as: 'in a(n)', e.g.: record_H__A = 'record' Hash "in an" Array.

=end


class Record_Buf < Buffer_Base
    def initialize( p1_aspace_O )
        super( )
        @cant_change_A << K.uri
        @http_calls_O = p1_aspace_O.http_calls_O
    end
    attr_reader :http_calls_O
    
    def jsonmodel_filter__what_to_keep( jsonmodel_type )
        if ( jsonmodel_type == nil or jsonmodel_type == '' )
        then   
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "jsonmodel_type is nil or ''"
            raise
        end
        jsonmodel_H = Record_Format.new( jsonmodel_type ).record_H
        return nil if ( jsonmodel_H == {} )
#
#       Additional stuff to keep:
        h = { K.child_count => '',
              K.parent_id => '',
              K.position => '',
              K.ref => '', 
              K.ref_id => '',
              K.tree => '',
              K.uri => '',  
              K.lock_version => "",     # Needed to update a record.
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
        if ( not jsonmodel_H.is_a?( Hash )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.ap "jsonmodel_H is a #{jsonmodel_H.class} not a hash:", jsonmodel_H
            raise
        end
        if ( jsonmodel_H.has_key?( K.jsonmodel_type )) then
            jsonmodel_filter__what_to_keep = jsonmodel_filter__what_to_keep( jsonmodel_H[ K.jsonmodel_type ])
        end
        h = {}
        jsonmodel_H.sort.to_h.each_pair do | k, v |
#           puts "k = #{k}, v = #{v}, v.class = #{v.class}"
            if ( v.is_a?( Array )) then
                a = v.map do | e |
                    if ( e.is_a?( Hash ) and e.has_key?( K.jsonmodel_type )) then
                        filter_jsonmodel( e )
                    else
                        e
                    end
                end
                h.merge!( { k => a } )
            elsif ( v.is_a?( Hash ) ) then
                h.merge!( { k => filter_jsonmodel( v ) } )
            else
                if ( jsonmodel_filter__what_to_keep ) then
                    h.merge!( { k => v } ) if ( jsonmodel_filter__what_to_keep.has_key?( k )) 
                else
                    h.merge!( { k => v } ) if ( not what_to_throw_away.has_key?( k ))         
                end
            end
        end
        return h
    end
    
    def load( external_record_H, filter_record_B = false)
#       SE.puts "#{SE.lineno}"
#       SE.ap "external_record_H:", external_record_H
#       SE.ap "filter_jsonmodel_template_H:", filter_jsonmodel_template_H
        if (!(  external_record_H[K.jsonmodel_type] and external_record_H[K.jsonmodel_type] == @rec_jsonmodel_type)) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "I was expecting a #{@rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "@uri = #{@uri}"
            SE.ap "external_record_H:", external_record_H
            raise
        end 

        if (  external_record_H.has_no_key?( K.jsonmodel_type ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Was expecting a jsonmodel_type in external_record_H"
            SE.puts "@uri = #{@uri}"
            SE.ap "external_record_H:", external_record_H
            raise
        end
        
        #   Don't check for the existance of 'external_record_H[ K.uri ]' as new records won't have one.
        if ( @uri.nil? ) then
            @uri = external_record_H[ K.uri ]  # if there's no 'K.uri' (like for a new record) this will still leave @uri nil.
        else
            if ( @uri != external_record_H[ K.uri ] ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "@uri != external_record_H[ K.uri ]"
                SE.puts "@uri = #{@uri}"
                SE.ap "external_record_H:", external_record_H
                raise            
            end
        end
        
        load_result_H = Hash.new
        if ( filter_record_B ) then
#           SE.ap "Before:", external_record_H
            load_result_H.merge!( filter_jsonmodel( external_record_H ))
#           SE.ap "After:", external_record_H
        else
            load_result_H.merge!( external_record_H )
        end
#       SE.ap "external_record_H:", external_record_H
        return load_result_H            
    end
    
    def read( filter_record_B = false )
        http_response_body_H = @http_calls_O.get( @uri )
#       SE.puts "#{SE.lineno}"
#       SE.ap "http_response_body_H:", http_response_body_H
#       SE.ap "filter_jsonmodel_template_H:", filter_jsonmodel_template_H
        if (!(  http_response_body_H[K.jsonmodel_type] and http_response_body_H[K.jsonmodel_type] == @rec_jsonmodel_type)) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "I was expecting a #{@rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "@uri = #{@uri}"
            SE.ap "http_response_body_H:", http_response_body_H
            raise
        end 
        if ( filter_record_B ) then
#           SE.ap "Before:", http_response_body_H
            http_response_body_H = filter_jsonmodel( http_response_body_H )
#           SE.ap "After:", http_response_body_H
        end
#       SE.ap "http_response_body_H:", http_response_body_H
        return http_response_body_H
    end
    
    def store
#       SE.ap @record_H
        if (!(  @record_H[K.jsonmodel_type] and @record_H[K.jsonmodel_type] == @rec_jsonmodel_type)) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "I was expecting a #{@rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "@uri = #{@uri}"
            SE.ap "@record_H:", @record_H
            raise
        end 
        if (@record_H == nil or ( @record_H.has_key?( K.uri) and @record_H[ K.uri ] != @uri )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Current @record_H[ K.uri ] != @uri"
            SE.puts "@uri = #{@uri}"
            SE.ap "Current @record_H:", @record_H
            raise
        end
        if ( @http_calls_O.aspace_O.allow_updates ) then
            http_response_body_H = @http_calls_O.post_with_body( @uri, @record_H )
            if ( ! http_response_body_H[K.status].in?( [ 'Created', 'Updated' ] ) ) then 
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Store failed!"
                SE.puts "@uri = #{@uri}"
                SE.puts "@record_H:", @record_H
                SE.ap "http_response_body_H:", http_response_body_H
                raise
            end
        else
            http_response_body_H = {K.uri => "NO UPDATE MODE"}
        end
        return http_response_body_H
    end

    def delete
        if (!(  @record_H[K.jsonmodel_type] and @record_H[K.jsonmodel_type] == @rec_jsonmodel_type)) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "I was expecting a #{@rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "@uri = #{@uri}"
            SE.ap "@record_H:", @record_H
            raise
        end 
        if (@record_H == nil or not ( @record_H.has_key?( K.uri) and @record_H[ K.uri ] == @uri )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Current @record_H[ K.uri ] != @uri"
            SE.puts "@uri = #{@uri}"
            SE.ap "Current @record_H:", @record_H
            raise
        end
        if ( @http_calls_O.aspace_O.allow_updates ) then
            http_response_body_H = @http_calls_O.delete( @uri, { } )
            if ( http_response_body_H[K.status] != 'Deleted' ) then 
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Delete failed!"
                SE.puts "@uri = #{@uri}"
                SE.ap "http_response_body_H:", http_response_body_H
                raise
            end
        else
            http_response_body_H = {K.uri => "NO UPDATE MODE"}
        end
        return http_response_body_H
    end
end




