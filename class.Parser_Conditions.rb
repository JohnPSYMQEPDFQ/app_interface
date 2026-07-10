#
#   Used by Se.raise
#

begin
    original_verbose = $VERBOSE
    $VERBOSE = nil
    require 'parser/current'
    $VERBOSE = original_verbose
end

class Parser_Conditions < Parser::AST::Processor
attr_reader :condition_A
    def initialize
        @condition_A = []
    end
    
    def on_if(node)
        @condition_A.push( [ node.loc.line, node.children[ 0 ], __method__ ] )
      # lineno    = node.loc.line          # 1 relative
      # column    = node.loc.column
      # condition = node.children[0]
      # body      = node.children[1]
      # else_body = node.children[2]
      # puts "--- Found If Structure ---"
      # puts "lineno, column:  #{lineno}, #{column}"
      # puts "Condition:       #{Unparser.unparse(condition)}"
      # puts "Condition Array: #{condition.inspect}"
      # puts "Body Array:      #{body.inspect}"
      # puts "Else Array:      #{else_body.inspect}"
        super
    end
    def on_while(node)
        @condition_A.push( [ node.loc.line, node.children[ 0 ], __method__ ] )
        super
    end
    def on_until(node)
        @condition_A.push( [ node.loc.line, node.children[ 0 ], __method__ ] )
        super
    end
    def on_when(node)
        @condition_A.push( [ node.loc.line, node.children[ 0 ], __method__ ] )
        super
    end
    
end

