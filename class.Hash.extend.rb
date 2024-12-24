class Hash

    def has_no_key?( key )
        return ! self.has_key?( key )
    end
    alias_method :no_key?, :has_no_key?
    
    def keys_nested
        result_a = [ ]
        self.each_pair do | k, v |
    #              puts "k = #{k}, v = #{v}, v.class = #{v.class}"
            if ( v.is_a?( Array )) then
                a = v.map do | e |
                    if ( e.is_a?( Hash ) ) then
                        e.keys_nested
                    else
                        e
                    end
                end
                result_a << k
                result_a << a if ( a.length > 0 )
            elsif ( v.is_a?( Hash ) ) then
                result_a << k
                result_a << v.keys_nested
            else
                result_a << k
            end
        end
        return result_a
    end
    alias_method :deep_keys, :keys_nested     # Seems like "nested" is more common than "deep"

    def merge_nested(second)
    #       https://stackoverflow.com/a/30225093
        merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
        merge(second.to_h, &merger)
    end
    alias_method :deep_merge, :merge_nested     # Seems like "nested" is more common than "deep"

    #       Next 2:   https://gist.github.com/steveevers/9d584aed053b9b31467101807462a94c
    def except_nested(key)
        r = Marshal.load(Marshal.dump(self))
        r.except_nested!(key)
    end
    
    def except_nested!(key)
        self.reject!{|k, v|k == key}
        self.each do |_, v|
            v.except_nested!(key) if v.is_a?(Hash)
            v.map!{|obj| obj.except_nested!(key) if obj.is_a?(Hash)} if v.is_a?(Array)
        end
    end

end

