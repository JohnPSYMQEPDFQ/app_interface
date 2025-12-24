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
      # SE.puts "#{SE.lineno}, called from: #{SE.my_caller}" 
      # SE.puts "self.class=#{self.class}, self.object_id=#{self.object_id}, argv='#{argv}'"
        @attr_writer_Method = attr_writer_Method
        super
    end
    def []=( *argv )    # This is aliased to 'store', hense the name of the class.
      # SE.puts "#{SE.lineno}, called from: #{SE.my_caller}" 
      # SE.puts "self.class=#{self.class}, self.object_id=#{self.object_id}, argv='#{argv}'"
      # SE.q {[ 'self' ]}
      # SE.q {[ 'h' ]}
        h = [ argv ].to_h
        @attr_writer_Method.call( h )
        super                                               # Why did this work without this?
    end
end


class Hash

    def has_no_key?( key )
        return ! self.has_key?( key )
    end
    alias_method :no_key?, :has_no_key?
    
    def deep_merge(second)
    #       https://stackoverflow.com/a/30225093
        merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
        merge(second.to_h, &merger)
    end
    alias_method :nested_merge, :deep_merge     # Seems like "deep" is more common than "nested"
    
end

