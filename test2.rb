require 'json'
require 'class.Hash.extend.rb'
require 'class.Array.extend.rb'
require 'class.String.extend.rb'
j='{"root": [{'
j+='"archival_object":[ {"jsonmodel_type":"archival_object",
"external_ids":[],
"resource":{ "ref":"/repositories/2/resources/1"}}]'
j+=','
j+='"resource":[{"jsonmodel_type":"resource",
"external_ids":[],
"ead_location":"KLUC995"}]' 
j+='}]}'


def deep_keys_to_a_XXX(h)
            ar = [ ]
            h.each_pair do | k, v |
 #              puts "k = #{k}, v = #{v}, v.class = #{v.class}"
                if ( v.is_a?( Array )) then
                    a = v.map do | e |
                        if ( e.is_a?( Hash ) ) then
                            deep_keys_to_a( e )
                        else
                            e
                        end
                    end
                    ar << k
                    ar << a if ( a.maxindex >= 0 )
                elsif ( v.is_a?( Hash ) ) then
                    ar << k
                    ar << deep_keys_to_a( v ) 
                else
                    ar << k
                end
            end
            return ar
end

h = JSON.parse( j )
a = h.deep_keys_to_a

h.each do | k, v |
    puts "k = #{k}, v = #{v}"
end
