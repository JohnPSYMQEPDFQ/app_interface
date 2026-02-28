require 'optparse'

require 'class.Archivesspace.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'

module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :cmdln_option_H, :aspace_O, :rep_O, :res_O, :res_buf_O
                      
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

BEGIN {}
END {}

binding.pry if ( respond_to? :pry )
self.myself_name = File.basename( $0 )

self.cmdln_option_H = { :rep_num => 2  ,
                      :res_num => nil,
                      :res_title => nil,
                      :ao_num => nil,
                      :ao_title => nil ,
                      :update => false ,
                      }
OptionParser.new do |option|
    option.banner = "Usage: #{self.myself_name} [options] FILE"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        self.cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )" ) do |opt_arg|
        self.cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "--res-title x", "Resource Title ( required )" ) do |opt_arg|
        self.cmdln_option_H[ :res_title ] = opt_arg
    end
    option.on( "--ao-num n", OptionParser::DecimalInteger, "Parent AO URI number ( optional, but must have children )" ) do |opt_arg|
        self.cmdln_option_H[ :ao_num ] = opt_arg
    end
    option.on( "--ao-title x", "Parent AO Title  ( optional, optional, but must have children )" ) do |opt_arg|
        self.cmdln_option_H[ :ao_title ] = opt_arg
    end
    option.on( "--update", "Do updates" ) do |opt_arg|
        self.cmdln_option_H[ :update ] = true
    end
  # option.on( "--last-record-num n", OptionParser::DecimalInteger, "Stop after record N" ) do |opt_arg|
  #     self.cmdln_option_H[ :last_record_num ] = opt_arg
  # end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
    
    option.separator '' 
    option.separator 'Example:'
    option.separator "    rr -a[lc] #{self.myself_name} --res-num NNN --res-title 'XXX'"
    option.separator ''
    
end.parse!  # Bang because ARGV is altered
# SE.q {[ 'self.cmdln_option_H' ]}

if ( self.cmdln_option_H[ :rep_num ].nil? ) then
    SE.puts "The --rep-num option is required."
    raise
end
if ( self.cmdln_option_H[ :res_num ].nil? ) then
    SE.puts "The --res-num option is required."
    raise
end
if ( self.cmdln_option_H[ :res_title ].nil? ) then
    SE.puts "The --res-title option is required."
    raise
end

SPACE = ' '
self.aspace_O = ASpace.new
self.aspace_O.allow_updates=self.cmdln_option_H[ :update ] 

self.rep_O = Repository.new( self.aspace_O, self.cmdln_option_H[ :rep_num ] )

self.res_O = Resource.new( self.rep_O, self.cmdln_option_H[ :res_num ] )
self.res_buf_O = self.res_O.new_buffer.read

if ( self.cmdln_option_H[ :res_title ].downcase != self.res_buf_O.record_H[ K.title ].downcase ) then
    SE.puts "#{SE.lineno}: The --res-title value must match the title of --res-num #{self.cmdln_option_H[ :res_num ]}. They don't:"
    SE.q {[ 'self.cmdln_option_H[ :res_title ].downcase' ]}
    SE.q {[ 'self.res_buf_O.record_H[ K.title ].downcase' ]}
    raise
end

ao_query_O = AO_Query_of_Resource.new( resource_O: self.res_O )

index_orig_count = ao_query_O.index_H_A.count
index_H_with_children_A = ao_query_O.index_H_A.select { | h | h[ K.child_count ] > 0 }

resource_children_cnt = index_H_with_children_A.count { | h | h[ K.parent_id ].nil?}
if ( index_orig_count != index_H_with_children_A.sum { | h | h[ K.child_count ]} + resource_children_cnt ) then
    SE.puts "#{SE.lineno}: child count error!"
    SE.q {'index_orig_count'}
    SE.q {'index_H_with_children_A.sum { | h | h[ K.child_count ]}'}
    SE.q {'index_H_with_children_A.length'}
    SE.q {'index_H_with_children_A'}
    raise
end

parent_uri = nil
if ( self.cmdln_option_H[ :ao_num ] ) then
    if ( self.cmdln_option_H[ :ao_title ] ) then
        SE.puts "#{SE.lineno}: The '--ao-num' and 'ao-title' options are mutually exclusive"
        raise
    end
    uri = "#{self.rep_O.uri_addr}/#{K.archival_objects}/#{self.cmdln_option_H[ :ao_num ]}"
    arr = index_H_with_children_A.select { | h | h[ K.uri ] == uri }
    if ( arr.length > 1 ) then
        SE.puts "#{SE.lineno}: Found more than 1 record with a uri = '#{uri}' (which is a really bad thing...)"
        SE.q {'arr'}
        SE.q {'index_H_with_children_A'}
        raise
    end
    if ( arr.length < 1 ) then
        SE.puts "#{SE.lineno}: Didn't find uri = '#{uri}'"
        SE.q {'arr'}
        SE.q {'index_H_with_children_A'}
        raise
    end
    parent_uri = arr[ 0 ][ K.uri ]
    SE.puts "#{SE.lineno}: Parent uri = #{parent_uri}"
    SE.puts "#{SE.lineno}: Parent Title = '#{arr[ 0 ][ K.title ]}'"
else
    if ( self.cmdln_option_H[ :ao_title ] ) then
        arr = index_H_with_children_A.select { | h | h[ K.title ].downcase == self.cmdln_option_H[ :ao_title ].downcase }
        if ( arr.length > 1 ) then
            SE.puts "#{SE.lineno}: Found more than 1 record with a title = '#{self.cmdln_option_H[ :ao_title ]}'"
            SE.q {'arr'}
            SE.q {'index_H_with_children_A'}
            raise
        end
        if ( arr.length < 1 ) then
            SE.puts "#{SE.lineno}: Didn't find title = '#{self.cmdln_option_H[ :ao_title ]}'"
            SE.q {'arr'}
            SE.q {'index_H_with_children_A'}
            raise
        end
        parent_uri = arr[ 0 ][ K.uri ]
        SE.puts "#{SE.lineno}: Parent Title = '#{arr[ 0 ][ K.title ]}'"
        SE.puts "#{SE.lineno}: Parent AO uri = #{parent_uri}"
    else
        parent_uri = self.res_buf_O.record_H[ K.uri ]
        SE.puts "#{SE.lineno}: Parent AO_uri = #{parent_uri} (The Resource)"
        SE.puts "#{SE.lineno}: Parent Title = '#{self.res_buf_O.record_H[ K.title]}'"
        parent_uri = ''
    end
end

if ( parent_uri.nil? ) then
    SE.puts "#{SE.lineno}: No Parent uri"
    SE.q {[ 'parent_uri' ]}
    raise
end

SE.puts "#{SE.lineno}: PRE-SORT"
ao_query_O = AO_Query_of_Resource.new( resource_O: self.res_O, 
                                       get_full_ao_record_TF: true, 
                                       starting_node_uri: parent_uri, 
                                       recurse_index_children_TF: false 
                                      )
SE.q {[ 'ao_query_O.record_H_A.length' ]}

# current_min_position = ao_query_O.record_H_A.min_by { | h | h[ K.position ] }[ K.position ]
# current_max_position = ao_query_O.record_H_A.max_by { | h | h[ K.position ] }[ K.position ]
# starting_max_position = 10 ** ( current_max_position.to_s.length )
# SE.q {['current_min_position','current_max_position', 'starting_max_position']}

#ao_query_O.record_H_A.first( 10 ).each do | record_H |
#   SE.q {[ 'record_H[ K.title ]', 'record_H[ K.position ]', 'record_H[ K.uri ]' ]}
#end

sort_jost = lambda{ | p1_title |
    format = '%09d'
    ignore_this_character_except_for_spliting = '^'
    title = p1_title.strip
                    .downcase
                    .sub( /[^0-9a-z ]/, ignore_this_character_except_for_spliting )
                    .sub( /\s\s+/, SPACE )
    arr = title.split( /([^0-9])/ )
               .reject { | e | e.empty? or e == ignore_this_character_except_for_spliting }
               .map { | e | ( e.integer? ) ? sprintf( format, e ) : e }
    idx = arr.find_index { | e | ! ( e == SPACE or e.integer? ) }  
    arr.insert( idx, SPACE  ) if ( idx.not_nil? )
    stringer = arr.join( '' )
#   SE.q {['idx', 'p1_title','stringer']} if ( title.start_with?( "1338" ) )
#   SE.q {['arr']} if ( title.start_with?( "1338" ) )
    return stringer
}

sorted_record_H_A = ao_query_O.record_H_A.sort_by { | record_H | sort_jost.call( record_H[ K.title ] ) }
SE.q {[ 'sorted_record_H_A.length' ]}

SE.puts "#{SE.lineno}: POST-SORT"

sorted_record_H_A.each_with_index do | record_H, new_position |   
    ao_buf_O = Archival_Object.new( self.res_buf_O ).new_buffer.load( record_H )
    if ( ao_buf_O.record_H[ K.position ] != new_position ) then
        ao_buf_O.record_H[ K.position ] = new_position
        ao_buf_O.store
        SE.q {[ 'record_H[ K.title ]', 'record_H[ K.position ]', 'new_position' ]}
    end
#   puts "#{record_H[ K.title ]}"
end

