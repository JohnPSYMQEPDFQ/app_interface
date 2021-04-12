=begin

Abbreviations,  AO = archival object(Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                AS = ArchivesSpace
                IT = instance type
                TC = top container
                SC = Sub-container
                _H = Hash
                _A = Array
                _I = Index(of Array)
                _O = Object
               _0R = Zero Relative

=end



class Record_Buf < Buffer_Base
    def initialize( p1_aspace_O )
        super( )
        @cant_change_A << K.uri
        @http_calls_O = p1_aspace_O.http_calls_O
    end
    attr_reader :record_H, :http_calls_O
    #  Shouldn't be an attr_writer :record_H here.
    
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
            }
        jsonmodel_H.merge!( h )
        return jsonmodel_H
    end
    
    def what_to_throw_away( )
        h = {   K.created_by => '',
                K.last_modified_by => '',
                K.create_time => '',
                K.system_mtime => '',
                K.user_mtime => '' }
        return h
    end
    
    def filter_jsonmodel( jsonmodel_H )
        if ( not jsonmodel_H.is_a?( Hash )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.pp "jsonmodel_H is a #{jsonmodel_H.class} not a hash:", jsonmodel_H
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
#       SE.pp "external_record_H:", external_record_H
#       SE.pp "filter_jsonmodel_template_H:", filter_jsonmodel_template_H
        if (!(  external_record_H[K.jsonmodel_type] and external_record_H[K.jsonmodel_type] == @rec_jsonmodel_type)) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "I was expecting a #{@rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "@uri = #{@uri}"
            SE.pp "external_record_H:", external_record_H
            raise
        end 
        if ( @uri == nil or @num == nil ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Was expecting the @uri and @num variables to be set"
            SE.puts "@uri = #{@uri}"
            SE.puts "@num = #{@num}"
            SE.pp "external_record_H:", external_record_H
            raise               
        end
        if ( ! ( external_record_H.has_key?( K.jsonmodel_type ) ) )
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Was expecting a jsonmodel_type in external_record_H"
            SE.puts "@uri = #{@uri}"
            SE.pp "external_record_H:", external_record_H
            raise
        end
        
        load_result_H = Hash.new
        if ( filter_record_B ) then
#           SE.pp "Before:", external_record_H
            load_result_H.merge!( filter_jsonmodel( external_record_H ))
#           SE.pp "After:", external_record_H
        else
            load_result_H.merge!( external_record_H )
        end
#       SE.pp "external_record_H:", external_record_H
        return load_result_H            
    end
    
    def read( filter_record_B = false )
        http_response_body_H = @http_calls_O.get( @uri )
#       SE.puts "#{SE.lineno}"
#       SE.pp "http_response_body_H:", http_response_body_H
#       SE.pp "filter_jsonmodel_template_H:", filter_jsonmodel_template_H
        if (!(  http_response_body_H[K.jsonmodel_type] and http_response_body_H[K.jsonmodel_type] == @rec_jsonmodel_type)) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "I was expecting a #{@rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "@uri = #{@uri}"
            SE.pp "http_response_body_H:", http_response_body_H
            raise
        end 
        if ( filter_record_B ) then
#           SE.pp "Before:", http_response_body_H
            http_response_body_H = filter_jsonmodel( http_response_body_H )
#           SE.pp "After:", http_response_body_H
        end
#       SE.pp "http_response_body_H:", http_response_body_H
        return http_response_body_H
    end
    
    def store
#       SE.pp @record_H
        if (!(  @record_H[K.jsonmodel_type] and @record_H[K.jsonmodel_type] == @rec_jsonmodel_type)) then 
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "I was expecting a #{@rec_jsonmodel_type} jsonmodel_type record."
            SE.puts "@uri = #{@uri}"
            SE.pp "@record_H:", @record_H
            raise
        end 
        if (@record_H == nil or ( @record_H.has_key?( K.uri) and @record_H[ K.uri ] != @uri )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Current @record_H[ K.uri ] != @uri"
            SE.puts "@uri = #{@uri}"
            SE.pp "Current @record_H:", @record_H
            raise
        end
        if ( $global_update ) then
            http_response_body_H = @http_calls_O.post_with_body( @uri, @record_H )
            if ( http_response_body_H[K.status] != 'Created' ) then 
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Create failed"
                SE.puts "@uri = #{@uri}"
                SE.puts "@record_H:", @record_H
                SE.pp "http_response_body_H:", http_response_body_H
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
            SE.pp "@record_H:", @record_H
            raise
        end 
        if (@record_H == nil or not ( @record_H.has_key?( K.uri) and @record_H[ K.uri ] == @uri )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Current @record_H[ K.uri ] != @uri"
            SE.puts "@uri = #{@uri}"
            SE.pp "Current @record_H:", @record_H
            raise
        end
        if ( $global_update ) then
            http_response_body_H = @http_calls_O.delete( @uri, { } )
            if ( http_response_body_H[K.status] != 'Deleted' ) then 
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Delete failed"
                SE.puts "@uri = #{@uri}"
                SE.pp "http_response_body_H:", http_response_body_H
                raise
            end
        else
            http_response_body_H = {K.uri => "NO UPDATE MODE"}
        end
        return http_response_body_H
    end
end




