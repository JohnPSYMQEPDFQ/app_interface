=begin
    The main purpose of this is to test the method_name code and make sure that:
        1) A deep_yield! would actually change the existing Object.
        2) A deep_yield (no !) would NOT change the existing Object.
    That's why the object_id's are displayed
=end
BEGIN {}
END {}

myself_name = File.basename( $0 )

require 'optparse'
cmdln_option_H = { :debug_TF_str => 'false',
                   :fail_on__yield_nil_TF_str => 'true',
                 }
                
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] <test_num>"
    option.on( "-d", "--debug", "Debug mode." ) do 
        cmdln_option_H[ :debug_TF_str ] = 'true'
    end
    option.on( "-f", "--fon", "Fail when yield result is nil AND the pre-yield value wasn't nil." ) do 
        cmdln_option_H[ :fail_on__yield_nil_TF_str ] = 'true'
    end
    option.on( "-h", "--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
SE.raise if ARGV.length > 2
if ARGV[ 1 ].nil? || ARGV[ 1 ].not_integer?
    SE.puts "No numeric test-number supplied (arg 2)"
    exit
end
SE.q {'cmdln_option_H'}

pre_or_post_bang = ARGV[ 0 ] 
test_num = ARGV[ 1 ].to_i
method_modifier = pre_or_post_bang.sub( /(!)$/, '' )
to_BANG_or_not_to_BANG = $~      
method_name = "deep_#{method_modifier}_yield#{to_BANG_or_not_to_BANG}"

original_thing = { 'a' => [ +'a.1', [ +'a.2' , 3 ] ], 
                   'b' => { 'b1' => +'b1.3',
                            'b2' =>    [ +'b2.4', +'b2.5' , 6 ],
                           },                            
#                  'b' => { 'b2' => Set[ +'b2.4', +'b2.5' , 6 ] },    This causes the ! tests to fail due to Set's being frozen
                  }
#original_thing = [ +'aa', +'bb' ]
old_thing = original_thing                
#old_thing[ 'b' ][ 'b2'] << '7'
#old_thing[ 'b' ][ 'b2'].each do | item |
#  puts "item=#{item} frozen=#{item.frozen?}"
#end
#As-of 5/20/2026, it seems values in Set's are frozen...

#old_thing   = original_thing  
#old_thing.deep_object_id.sort_by{ | e | [ e[ 0 ] ]}.each { | o | SE.puts "obj_id=#{o}" }
SE.q {'old_thing'}
old_thing_CKA = old_thing.to_CKA_h
#SE.q {'old_thing_CKA'}

#ck_A = []
#old_thing_CKA.keys.each do | ck | 
#    SE.puts "ck=#{ck}"
#    ck.each_with_index do |_, i| 
#      t = ck.take(i + 1) 
#      t = ck[ 0 .. i ]
#      SE.puts "i=#{i} t=#{t}"
#      ck_A.push( t ) if ( ! ck_A.include?( t ))
#    end 
#  end
#ck_A = []; old_thing_CKA.keys.each    do | ck | ck.each_with_index do | _, i | t = ck[ 0 .. i ]; ck_A.push( t ) if ( ! ck_A.include?( t )); end; end
 ck_A =     old_thing_CKA.keys.flat_map { | ck_A | 
              ( 1 .. ck_A.size ).map { | i | ck_A.take( i ) } 
             }.uniq.sort_by{ | e | [ e.object_id ] }
              
#SE.q {'ck_A'}
SE.puts "old_thing.class=#{old_thing.class}, old_thing.object_id=#{old_thing.object_id}" 
ck_A.each { | ck | old_thing.value__using_CKA( ck ).tap { | y | SE.puts "ck=#{ck}, class=#{y.class}, object_id=#{y.object_id} value='#{y}'" } }

SE.puts ''
SE.puts "test-num #{test_num}, debug=#{cmdln_option_H[ :debug_TF_str ]}"

method_formatted_LP = lambda { | method_name |
        "old_thing.#{method_name}( " + 
        "do_debug: #{cmdln_option_H.fetch( :debug_TF_str )}, " +
        "fail_on__yield_nil_TF: #{cmdln_option_H.fetch( :fail_on__yield_nil_TF_str )} )"
    }
case test_num
when 1
  SE.puts "    Code: new_thing = old_thing.deep_copy"
  SE.puts ''
  new_thing = old_thing.deep_copy
when 2 # .clone
  code = method_formatted_LP.( method_name )
  code += '{ | y | y.clone }.tap{ | y | SE.puts "class=#{y.class}, object_id=#{y.object_id}, #{y}" }'
  SE.puts "    Code: new_thing = #{code}"
  SE.puts ''
  new_thing = eval( code )
when 3 # .freeze
  code = method_formatted_LP.( method_name )
  code += '{ | y | y.freeze }'
  SE.puts "    Code: new_thing = #{code}"
  SE.puts ''
  new_thing = eval( code )
  SE.q {'new_thing[ "b" ][ "b1" ].frozen?'}
when 4 # CHANGES
  code = method_formatted_LP.( method_name )
  code += '{ | y | if y.is_a?( String ) && y.not_frozen? then y + "CCCCC" else y end }'
  SE.puts "    Code: new_thing = #{code}"
  SE.puts ''
  new_thing = eval( code )
when 5 # .dup
#  For some reason the following line won't work:
#      code = %(old_thing.deep_yield.each { | x | SE.puts "x=#{x}" })
  
# Doing an 'each' changes a Hash into an Array which changes the object id. Doing a 'map' right off of yield returns 
# new values, which isn't what we want in this case.  So, 'tap' gets the object and then 'maps' gets each object. 
# code += '{ | y,k,c,p | SE.puts "class=#{y.class}(of #{p.class}), object_id=#{y.object_id}, #{y}"; y }.tap { | y| y.each { | x | SE.puts "class=#{x.class}, object_id=#{x.object_id}, \'#{x}\'" }}'
  code = method_formatted_LP.( method_name )
  code += '{ | y, p_O, r, n_O | y }.tap{ | y | SE.puts "class=#{y.class}, object_id=#{y.object_id}, #{y}" }'
  SE.puts "    Code: new_thing = #{code}"
  SE.puts ''
  new_thing = eval( code )
else
  SE.puts "    Not coded."
  exit
end
SE.puts ''


SE.q {'new_thing'}
#old_thing.deep_object_id.sort_by{ | e | [ e[ 0 ] ]}.each { | o | SE.puts "obj_id=#{o}" }
#new_thing.deep_object_id.sort_by{ | e | [ e[ 0 ] ]}.each { | o | SE.puts "obj_id=#{o}" }
SE.q {'new_thing == old_thing'}

SE.puts "old_thing.class=#{old_thing.class}, old_thing.object_id=#{old_thing.object_id}" 
ck_A.each { | ck | old_thing.value__using_CKA( ck ).tap { | y | SE.puts "ck=#{ck}, class=#{y.class}, object_id=#{y.object_id} value='#{y}'" } }
SE.puts ''
SE.puts "new_thing.class=#{new_thing.class}, new_thing.object_id=#{new_thing.object_id}" 
ck_A.each { | ck | new_thing.value__using_CKA( ck ).tap { | y | SE.puts "ck=#{ck}, class=#{y.class}, object_id=#{y.object_id} value='#{y}'" } }


