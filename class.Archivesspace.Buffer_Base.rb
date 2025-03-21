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

require 'class.Hash.extend.rb'

class Buffer_Base
    
    def initialize(  )
        @record_H = Hash__where__store_calls_writer.new( self.method( 'record_H=') )
        @cant_change_A = [ ]
        @cant_change_A << K.jsonmodel_type 
        @cant_change_A << K.persistent_id
    end
    attr_reader :cant_change_A, :record_H
    
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
    
    def record_H=( set_values_H )
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
#       SE.q {'pre_change_record_H'}
        @record_H = @record_H.deep_merge( set_values_H )  
#       SE.q {[ '@record_H' ]}
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




