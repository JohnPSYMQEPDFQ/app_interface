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

class Resource

    def initialize( p1_rep_O, p2_res_identifier )
        if ( p1_rep_O.class != Repository ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Param 1 is not a Repository class object, it's #{p1_rep_O.class}"
            raise
        end    
        @rep_O = p1_rep_O
        if ( p2_res_identifier == nil ) then
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
                    @num = p2_res_identifier.sub( /^.*\//, '' )
                    if (! @num.integer? ) then
                        Se.puts "#{Se.lineno}: =============================================="
                        Se.puts "Invalid param2: #{p2_res_identifier}"
                        raise
                    end
                end
            end
        end 
    end
    attr_reader :rep_O, :num, :uri
    
    def make_buffer
        res_buf_O = Resource_Record_Buf.new( self )
        return res_buf_O
    end
 
end

class Resource_Record_Buf < Record_Buf

    def initialize( rec_type_O )
        if ( rec_type_O.class != Resource ) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Param 1 is not a Resource class object, it's a #{rec_type_O.class}"
            raise
        end 
        @rec_type_O = rec_type_O
        @uri = @rec_type_O.uri
        @num = @rec_type_O.num
        super( @rec_type_O.rep_O.aspace_O )
    end
    attr_reader :num, :uri, :rec_type_O
    
    def create
        @record_H.merge!( Record_Format.new( K.resource ).record_H )
        return self
    end
    
    def read( filter_record_B = true )
        @record_H = super( filter_record_B )
#       Se.pp "@record_H", @record_H
        if ( ! ( @record_H.has_key?( K.jsonmodel_type ) and @record_H[ K.jsonmodel_type ] == K.resource ) )
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Was expecting a resource jsonmodel_type"
            Se.puts "@uri = #{@uri}"
            Se.pp "@record_H:", @record_H
            raise
        end  
        if ( @record_H.key?( K.resource ) and  @record_H[ K.resource ].key?( K.ref )) then
            if ( ! ( @record_H[ K.resource ][ K.ref ] == "#{@uri}" ) ) then
                Se.puts "uri is not part of resource '#{@num}'"
                Se.puts "resource => uri = '#{@uri}'"
                Se.pp "@record_H:", @record_H
                raise
            end
        end
        return self
    end
    
    def store( )
        Se.puts "Method not coded"
        raise
    end
end   

class Resource_Tree_Query

=begin
{"title"=>"Corporate Archives",
 "id"=>89,
 "node_type"=>"resource",
 "publish"=>false,
 "suppressed"=>false,
 "children"=>
  [{"title"=>"Series Uno",
    "id"=>130317,
    "record_uri"=>"/repositories/2/archival_objects/130317",
    "publish"=>false,
    "suppressed"=>false,
    "node_type"=>"archival_object",
=end
    def initialize( p1_res_O )
        @res_O = p1_res_O
        uri = "#{@res_O.uri}/tree"
        http_response_body = @res_O.rep_O.aspace_O.http_calls_O.http_get( uri, { } )
        if ( not ( http_response_body.has_key?( K.id ) and http_response_body[ K.id ] == @res_O.num )) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Unable to find Resource Tree for res_num = #{@res_O.num}"
            Se.puts "uri = #{uri}"
            Se.pp "http_response_body", http_response_body
            raise
        end		
#       Se.pp http_response_body
        @result = load_children( http_response_body[ K.children], [] )
    end
    attr_reader :result, :res_O
    
    def load_children( child_A, result_A )
        if ( not (child_A.is_a?( Array ))) then
            Se.puts "#{Se.lineno}: =============================================="
            Se.puts "Was expecting an Array here..."
            raise
        end
        child_A.each do | e |
            if ( e.is_a?( Hash )) then
                if ( not (e.has_key?( K.node_type ) and e[ K.node_type ] == K.archival_object )) then
                    Se.puts "#{Se.lineno}: =============================================="
                    Se.puts "Was expecting an archival_object here, not k = #{k} and v = #{v}"
                    raise
                end
                result_A << Archival_Object.new( @res_O, e[ K.record_uri ])
                if ( e.has_key?( K.children ) and e[ K.children] != [] ) then
                    load_children( e[ K.children ], result_A )
                end
            else
                Se.puts "#{Se.lineno}: =============================================="
                Se.puts "Was expecting a Hash here..."
                raise
            end
        end
        return result_A
    end
end
 
