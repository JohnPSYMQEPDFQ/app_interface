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

class Resource
=begin
      Resource just holds the resource-number and uri.   
      An object of this is needed to create a Resource_Record_Buf, but
      there's a 'new_buffer' method that will do it from inside here too, eg:
          resource_buffer_Obj = Resource.new(repository_Obj, resource-num|uri).new_buffer[.read|create]
=end
    def initialize( p1_rep_O, p2_res_identifier = nil )
        if ( p1_rep_O.nil? or p1_rep_O.is_not_a?( Repository ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Repository class object, it's a '#{p1_rep_O.class}'"
            raise
        end    
        @rep_O = p1_rep_O
        if ( p2_res_identifier.nil? ) then
            @num = nil
            @uri = nil
        else
            if ( p2_res_identifier.integer? ) then
                @num = p2_res_identifier
                @uri = "#{@rep_O.uri}/resources/#{@num}"
            else
                stringer = "#{@rep_O.uri}/archival_objects"
                if ( stringer == p2_res_identifier[ 0 .. stringer.maxindex ]) then
                    @uri = p2_res_identifier
                    @num = p2_res_identifier.trailing_digits
                    if (not @num.integer? ) then
                        SE.puts "#{SE.lineno}: =============================================="
                        SE.puts "Invalid param2: #{p2_res_identifier}"
                        raise
                    end
                else
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Invalid param2: #{p2_res_identifier}"
                    raise
                end
            end
        end 
    end
    attr_reader :rep_O, :num, :uri
    
    def new_buffer
        res_buf_O = Resource_Record_Buf.new( self )
        return res_buf_O
    end
 
end

class Resource_Record_Buf < Record_Buf
=begin
      A "CRUD-like" class for the /resources, but (as of 4/19/2020) I don't want anything accidently
      updating a Resource, so the U.D. part are missing.   
      Note that: The 'create' just initializes the buffer, and the Update is called 'store' (so it's IRSD)
=end
    def initialize( p1_res_O )
        if ( not p1_res_O.is_a?( Resource )) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a Resource class object, it's a '#{p1_res_O.class}'"
            raise
        end 
        @rec_jsonmodel_type =  K.resource
        @res_O = p1_res_O
        @uri = @res_O.uri
        @num = @res_O.num
        super( @res_O.rep_O.aspace_O )
    end
    attr_reader :num, :uri, :res_O
    
    def create
        @record_H.merge!( Record_Format.new( @rec_jsonmodel_type ).record_H )
        @cant_change_A << K.level 
        @cant_change_A << K.resource
        return self
    end

    def load( external_record_H, filter_record_B = true )
        @record_H = super
        # if ( not (@record_H.has_key?( K.resource ) and @record_H[K.resource].has_key?( K.ref ) and 
                  # @record_H[ K.resource ][ K.ref ] == @ao_O.p1_res_O.uri )) then
            # SE.puts "#{SE.lineno}: =============================================="
            # SE.puts "Archival_object doesn't belong to current Resource."
            # SE.puts "@record_H[K.resource][K.ref] != @ao_O.p1_res_O.uri"
            # SE.ap "@record_H:", @record_H
            # raise
        # end
        @cant_change_A << K.level 
        @cant_change_A << K.resource
        return self
    end
    
    def read( filter_record_B = true )
        @record_H = super( filter_record_B )
#       SE.q { [ '@record_H' ] }
        if ( @record_H.key?( @rec_jsonmodel_type ) and  @record_H[ @rec_jsonmodel_type ].key?( K.ref )) then
            if ( ! ( @record_H[ @rec_jsonmodel_type ][ K.ref ] == "#{@uri}" ) ) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "uri is not part of resource '#{@num}'"
                SE.puts "resource => uri = '#{@uri}'"
                SE.q { [ '@record_H' ] }
                raise
            end
        end
        return self
    end
    
    def store( )
        if ( not (  @record_H[K.title] and @record_H[K.title] != K.undefined )) then 
            SE.puts "#{SE.lineno}: =========================================="
            SE.puts "I was expecting a @record_H[K.title] value";
            SE.ap "@record_H:", @record_H
            raise
        end

        if ( @uri.nil? ) then
            @uri = "#{@res_O.rep_O.uri}/resources"
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Created Resource, uri = #{http_response_body_H[ K.uri ]}";
        else
            http_response_body_H = super
            SE.puts "#{SE.lineno}: Updated Resource, uri = #{http_response_body_H[ K.uri ]}";
        end
        @uri = http_response_body_H[ K.uri ] 
        @num = @uri.trailing_digits
    end
end   


 
