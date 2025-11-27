require 'class.Object.extend.rb' 
require 'module.SE.rb'

class Hash__where__store_calls_writer < Hash
#
#       See 'class.Archivesspace.Buffer_Base.rb for example

    def initialize( *argv )   
        attr_writer_Method = argv.shift
        if ( attr_writer_Method.is_not_a?( Method ) ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 is not a 'Method', it's a '#{attr_writer_Method.class}'"
            raise
        end
        if ( attr_writer_Method.original_name[ -1 ] != '=' ) then
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "Param 1 'method name'(#{attr_writer_Method.original_name}) doesn't end with an '=' sign."
            SE.q {[ attr_writer_Method ]}
            raise
        end
#       SE.puts attr_writer_Method
        @attr_writer_Method = attr_writer_Method
        super
    end
    def []=( *argv )    # This is aliased to 'store', hense the name of the class.
#       SE.puts "#{SE.lineno}: #{argv}"
#       SE.ap_stack
        h = [ argv ].to_h
#       SE.q {[ 'h' ]}
        @attr_writer_Method.call( h )
    end
end


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

    def flatten_hash(hash, prefix = "")
        hash.each_pair.reduce({}) do |acc, (key, value)|
            full_key = prefix.empty? ? key : "#{prefix}.#{key}"
            if value.is_a?(Hash)
                acc.merge(flatten_hash(value, full_key))
            else
                acc.merge(full_key.to_sym => value)
            end
        end
    end

end

