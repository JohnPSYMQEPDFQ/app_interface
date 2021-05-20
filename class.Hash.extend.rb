class Hash

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

