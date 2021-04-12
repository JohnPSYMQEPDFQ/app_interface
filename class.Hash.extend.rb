class Hash

def deep_keys_from_stackexchange
    h_map_output_A = self.map do |k, v|
#       puts "k = #{k}, v = #{v}"
#       puts
        va = v.is_a?( Array ) ? v : [ v ]
        if ( va == [] ) then
            r = k
#           puts "Value is []        :  #{r} => []"
#           puts
            r
        else
            y_map_output_A = va.map do |e|
                if (e.is_a?( Hash ))
#                   puts "Into recusion, hash:  #{k} => #{e}"
#                   puts
                    r = [k, e.deep_keys_from_stackexchange]
#                   puts "Return from recusion: #{r}"
#                   puts
                    r
                else
                    r = k
#                   puts "Value wasn't a hash:  #{r} => #{e}"
#                   puts
                    r
                end
            end
    #       puts "y_map_output_A = #{y_map_output_A}"
            y_map_output_A = y_map_output_A.shift
        end
    end 
#   puts "h_map_output_A = #{h_map_output_A}"
#   puts "RETURN ==========================="
#   puts
    h_map_output_A
end

def deep_keys
    result_a = [ ]
    self.each_pair do | k, v |
#              puts "k = #{k}, v = #{v}, v.class = #{v.class}"
        if ( v.is_a?( Array )) then
            a = v.map do | e |
                if ( e.is_a?( Hash ) ) then
                    e.deep_keys
                else
                    e
                end
            end
            result_a << k
            result_a << a if ( a.length > 0 )
        elsif ( v.is_a?( Hash ) ) then
            result_a << k
            result_a << v.deep_keys
        else
            result_a << k
        end
    end
    return result_a
end


def deep_merge(second)
#       https://stackoverflow.com/a/30225093
    merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    merge(second.to_h, &merger)
end


end

