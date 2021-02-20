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

require 'class.Hash.extend.rb'
class Buffer_Base

    def initialize(  )
        @record_H = Hash.new( )
        @cant_change_A = [ ]
        @cant_change_A << K.jsonmodel_type 
        @cant_change_A << K.persistent_id
    end
    attr_reader :cant_change_A
    #  Shouldn't be an attr_reader :record_H here.
         
    def hash_comp_key_type( h_before, h_after )
#       Se.puts "Before: #{h_before}"
#       Se.puts "After:  #{h_after}"
        h_before.each_pair do | k, v |
#           Se.puts "start loop: k = #{k}, v = #{v}"
            if ( k == K.parent ) then
                next if ( h_after.has_key?( k ) and h_after[ k ].is_a?( String ) and h_after[ k ] == '' ) 
            else
                return { k => v } if ( ! h_after.has_key? (k))
                return { k => v } if ( ! v.class == h_after[ k ].class )
            end
            if ( v.is_a? ( Hash )) then
                return { k => v } if ( ! hash_comp_key_type( h_before[ k ], h_after[ k ]) == { } )
            end
        end
        return {}
    end
    private :hash_comp_key_type
    
    def record_H=( set_values_H )
        set_values_H.each do |k, v|
            if (k.in?( @cant_change_A )) then
                Se.puts "#{Se.lineno}: ======================================"
                Se.puts "Key #{k} can't be changed."
                raise
            end
        end
        pre_change_record_H = Hash.new.merge( @record_H )
#       Se.pp "pre_change_record_H:", pre_change_record_H
        @record_H = @record_H.deep_merge( set_values_H )  
#       Se.pp "@record_H:", @record_H
        h = hash_comp_key_type( pre_change_record_H, record_H )
        if ( h != {} )
            Se.puts "#{Se.lineno}: ======================================"
            Se.puts "Invalid (new?, mistyped?) hash key: #{h}"
            Se.pp "pre_change_record_H:", pre_change_record_H
            Se.pp "post_change_record_H:", record_H
            raise
        end
        
        if ( pre_change_record_H.keys != @record_H.keys ) then
            Se.puts "#{Se.lineno}: ======================================"
            Se.puts "Invalid (new?, mistyped?) hash key: #{set_values_H}"
            Se.pp "pre_change_record_H:", pre_change_record_H
            Se.pp "post_change_record_H:", record_H
            raise
        end
        return @record_H
    end
   
end




