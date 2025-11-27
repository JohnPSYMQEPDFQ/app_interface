=begin


Usage:  this_program.rb --res-num n [other options] FILE
        this_program.rb --help

To attach the records in FILE to the "Resource Record", only the --res-num option is needed.
To attach the records to a specific AO, enter the --res-num option along with:
    1)  the --ao-num of the child AO. The --ao-num is the number at the end of the AO's uri.
    2)  OR use the 'new_parent' record level along with desired title in the input FILE (see below)


The input FILE has the following three formats( JSONized ):

        1 = {
              K.fmtr_record =>
                {
                  K.level => ''             # the AO level (eg. 'file', 'series', 'recordgrp', ...) 
                                            # -OR- a value of K.fmtr_new_parent (see below).
                  K.title => '',            # the AO title field.
-optional-        K.dates => [ ],           # An array of AO date hashes, single or inclusive.
-optional-        K.notes => [ ],           # An array of AO note hashes, singlepart or miltipart.
-optional-        K.fmtr_container =>       # References to TC of "type => indicator", creates the TC if needed.
                    {
                      K.fmtr_tc_type      => 'VALUE'     # eg. 'box'
                      K.fmtr_tc_indicator => 'n'         # Box number (must be a number)
                      K.fmtr_sc_type      => 'VALUE'     # eg. 'folder'
                      K.fmtr_sc_indicator => 'STRING'    # Anything identifing the folder
                    }
                }
            }
  
        2 = {
              K.fmtr_indent => [ K.fmtr_right, 'Any text' ]    # Text only used for debugging
            }
  
        3 = {
              K.fmtr_indent => [ K.fmtr_left, 'Any text' ]     # Text only used for debugging
            }

    Record format 1 is the data record.  As-of 3/18/2020 only the "series", "subseries", "recordgrp", and "file" AO-level types
    were tested.  If the record level (K.level) is equal to 'K.fmtr_new_parent' this causes the program to find an existing AO record 
    equal to the 'Title' value.  This AO then becomes the parent record for all subsequent records in FILE.

    Record format 2 causes all the records following the "indent => right" record to be attached to the record PRIOR to 
    the "indent => right" record.

    Record format 3 causes all the records following the "indent => left" record to be attached to the record PRIOR to
    the previous "indent => right" record. At the end of the program run, an "indent counter" is displayed, which should
    be 0 IF the number of right-dents equals the number left-dents.  Sometimes, there's no final indent-left tho.

=end

require 'json'
require 'optparse'

require 'class.Archivesspace.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'

class Res_Q < AO_Query_of_Resource

    def uri_of( title )  # Find the URI with the matching title
        a1 = [ ]
        self.index_H_A.each do | index_H |
            if ( index_H[ K.title ].downcase == title.downcase and index_H[ K.level ] != K.file ) then
                a1 << index_H[ K.uri ]
#               SE.puts "New parent: #{index_H[ K.uri ]} '#{index_H[ K.title ]}'"
            end
        end
        if ( a1.maxindex < 0 ) then
            SE.puts "#{SE.lineno}: Couldn't find a non-file AO with a title of '#{title}'"
            raise
        end
        if ( a1.maxindex > 1 ) then
            SE.puts "#{SE.lineno}: Found more than 1 AO with a title of '#{title}'.",
                    "Use the uri number and the '--ao-num' option."
            raise
        end
        return a1[ 0 ]
    end
end

BEGIN {}
END {}

binding.pry if ( respond_to? :pry )
myself_name = File.basename( $0 )

cmdln_option = { :rep_num => 2  ,
                 :res_num => nil,
                 :res_title => nil,
                 :ao_num => nil,
                 :ao_title => nil ,
                 :reuse_TCs => false ,
                 :update => false ,
                 :last_record_num => nil ,
                 }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] FILE"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )" ) do |opt_arg|
        cmdln_option[ :res_num ] = opt_arg
    end
    option.on( "--res-title x", "Resource Title ( required )" ) do |opt_arg|
        cmdln_option[ :res_title ] = opt_arg
    end
    option.on( "--ao-num n", OptionParser::DecimalInteger, "Initial parent AO URI number ( optional, but must be member of suppled Resource number )" ) do |opt_arg|
        cmdln_option[ :ao_num ] = opt_arg
    end
    option.on( "--ao-title x", "Initial parent AO Title  ( optional, but must be member of suppled Resource number )" ) do |opt_arg|
        cmdln_option[ :ao_title ] = opt_arg
    end
    option.on( "--reuse-tcs", "Reuse TC records." ) do |opt_arg|
        cmdln_option[ :reuse_TCs ] = true
    end
    option.on( "--update", "Do updates" ) do |opt_arg|
        cmdln_option[ :update ] = true
    end
    option.on( "--last-record-num n", OptionParser::DecimalInteger, "Stop after record N" ) do |opt_arg|
        cmdln_option[ :last_record_num ] = opt_arg
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
    
    option.separator '' 
    option.separator 'Example:'
    option.separator "    rr -aL #{myself_name} --res-num NNN --res-title 'XXX' file.json"
    option.separator ''
    
end.parse!  # Bang because ARGV is altered
if ( ARGV.length != 1 ) then
    SE.puts "#{SE.lineno}: No input-file provided (or extra param found)"
    SE.q {'ARGF'}
    raise
end
if ( ARGV[ 0 ].start_with?( '.' ) ) then
    ARGV[ 0 ] = File.basename( Dir.getwd ) + ARGV.first
end

if not File.exist?( ARGV[ 0 ] ) then
    SE.puts "#{SE.lineno}: File '#{ARGV[ 0 ]}' not-found."
    raise
end

# SE.q {[ 'cmdln_option' ]}

if ( cmdln_option[ :rep_num ].nil? ) then
    SE.puts "The --rep-num option is required."
    raise
end
if ( cmdln_option[ :res_num ].nil? ) then
    SE.puts "The --res-num option is required."
    raise
end
if ( cmdln_option[ :res_title ].nil? ) then
    SE.puts "The --res-title option is required."
    raise
end

aspace_O = ASpace.new
aspace_O.allow_updates=cmdln_option[ :update ] 

rep_O = Repository.new( aspace_O, cmdln_option[ :rep_num ] )

res_O = Resource.new( rep_O, cmdln_option[ :res_num ] )
res_buf_O = res_O.new_buffer.read

if ( cmdln_option[ :res_title ].downcase != res_buf_O.record_H[ K.title ].downcase ) then
    SE.puts "#{SE.lineno}: The --res-title value must match the title of --res-num #{cmdln_option[ :res_num ]}. They don't:"
    SE.q {[ 'cmdln_option[ :res_title ]' ]}
    SE.q {[ 'res_buf_O.record_H[ K.title ]' ]}
    raise
end


res_Q_O = Res_Q.new( res_O, false )
parent_ref_stack_A = [ ]
if ( cmdln_option[ :ao_num ] ) then
    if ( cmdln_option[ :ao_title ] ) then
        SE.puts "#{SE.lineno}: The '--ao-num' and 'ao-title' options are mutually exclusive"
        raise
    end
    parent_ref_stack_A << res_Q_O.index_H_of_uri_num( cmdln_option[ :ao_num ] )[ K.uri ]
    SE.puts "#{SE.lineno}: initial parent uri = #{parent_ref_stack_A[ 0 ]} (From the cmd_line)"
else
    if ( cmdln_option[ :ao_title ] ) then
        parent_ref_stack_A << res_Q_O.uri_of_title( cmdln_option[ :ao_title ] )
        SE.puts "#{SE.lineno}: initial parent AO uri = #{parent_ref_stack_A[ 0 ]} (From the cmd_line)"
    else
        parent_ref_stack_A << res_buf_O.record_H[ K.uri ]
        SE.puts "#{SE.lineno}: initial parent AO_uri = #{parent_ref_stack_A[ 0 ]} (The Resource)"
    end
end
if ( parent_ref_stack_A.maxindex != 0 ) then
    SE.puts "#{SE.lineno}: Was expecting parent_ref_stack_A.maxindex to be 0"
    SE.q {[ 'parent_ref_stack_A' ]}
    raise
end

tc_uri_H__by_type_and_indicator = {}
if ( cmdln_option[ :reuse_TCs ] ) then
    SE.puts "Finding Top_Containers (which takes some time) ..."
    time_begin = Time.now
    all_TC_S = TC_Query.new( rep_O ).get_all_TC_S
    elapsed_seconds = Time.now - time_begin
    SE.puts "Elapsed seconds = #{elapsed_seconds}"
    all_TC_S.for_res__record_H_A( res_O ).each do | record_H |
        if ( record_H.key?( K.type ) and record_H.key?( K.indicator )) then
            stringer=record_H[ K.type ] + record_H[ K.indicator ]
            SE.puts "Reusing TC: #{record_H[ K.uri ].trailing_digits}, type=#{record_H[ K.type ]}, indicator='#{record_H[ K.indicator ]}'"
            if ( tc_uri_H__by_type_and_indicator.key?( stringer ) ) then
                SE.puts "#{SE.lineno}: Duplicate record_H 'type+indicator' #{stringer}, K.uri=#{record_H[ K.uri ]}"
                next
            end
            tc_uri_H__by_type_and_indicator[ stringer ] = record_H[ K.uri ]
        end
    end
end

net_indent_cnt = 0
record_level_cnt = Hash.new( 0 )  # h.default works too...
last_AO_uri_created = ""
for argv in ARGV do
    File.foreach( argv ) do |input_record_J|
        if (cmdln_option[ :last_record_num ] != nil and $. >cmdln_option[ :last_record_num ] ) then 
            break
        end
        input_record_J.chomp!
        if ( input_record_J.match?( /^\s*$/ ) ) then
            next
        end
        input_record_H = JSON.parse( input_record_J )

        if ( input_record_H.key?( K.fmtr_indent ) ) then
            SE.puts "#{SE.lineno}: '#{input_record_J}'"
            record_level_cnt[ input_record_H[ K.fmtr_indent ][ 0 ] ] += 1
            case input_record_H[ K.fmtr_indent ][ 0 ]
            when K.fmtr_right then
                net_indent_cnt += 1
                parent_ref_stack_A.push( last_AO_uri_created )
                SE.puts "#{SE.lineno}: New parent: #{last_AO_uri_created}"
                next
            when K.fmtr_left then
                net_indent_cnt -= 1
                parent_ref_stack_A.pop( 1 )
                last_AO_uri_created = parent_ref_stack_A[ parent_ref_stack_A.maxindex ]
                SE.puts "#{SE.lineno}: New parent: #{last_AO_uri_created}"
                next
            else
                SE.puts "#{SE.lineno}: Invalid indent direction '#{input_record_H[ K.fmtr_indent ][ 0 ]}'"
                raise                
            end
        end

        if ( input_record_H.key?( K.fmtr_record ) ) then
            SE.puts "#{SE.lineno}: '#{input_record_J}'"
            record_level = input_record_H[ K.fmtr_record ][ K.level ]
            record_level_cnt[ record_level ] += 1
            if ( record_level == K.fmtr_new_parent ) then
                if (cmdln_option[ :ao_num ] or cmdln_option[ :ao_title ] ) then
                    SE.puts "#{SE.lineno}: Hit 'new_parent' record, but"
                    SE.puts "the --ao-num and --ao-title options aren't allowed for this record type."
                    raise
                end
                if ( parent_ref_stack_A.maxindex != 0 ) then
                    SE.puts "#{SE.lineno}: Hit 'new_parent' record, but parent_ref_stack_A.maxindex != 0"
                    SE.puts "The formatter should insure the indent level is at 0 for a 'new_parent' record."
                    SE.q {[ 'parent_ref_stack_A' ]}
                    SE.q {[ 'input_record_H' ]}
                    raise
                end                
                parent_ref_stack_A[ 0 ] = res_Q_O.uri_of( input_record_H[ K.fmtr_record ][ K.title ] )
                SE.puts "#{SE.lineno}: New parent: #{parent_ref_stack_A[ 0 ]}"
                next
            end

            ao_buf_O = Archival_Object.new( res_buf_O ).new_buffer.create( record_level )
          # SE.q {'ao_buf_O.record_H'}
            if ( record_level == K.otherlevel ) then
                if ( input_record_H[ K.fmtr_record ].has_key?( K.other_level ) ) then
                    ao_buf_O.record_H = { K.other_level => input_record_H[ K.fmtr_record ][ K.other_level ] }
                else
                    SE.puts "#{SE.lineno}: Hit a 'otherlevel' record with no ' K.fmtr_record ][ K.other_level ]' value."
                    SE.q {[ 'input_record_H' ]}
                    raise                    
                end
            end
            if ( ao_buf_O.record_H[ K.resource ][ K.ref ] == parent_ref_stack_A[ parent_ref_stack_A.maxindex ] ) then
                ao_buf_O.record_H = { K.parent => '' }
            else
                ao_buf_O.record_H = { K.parent => { K.ref => parent_ref_stack_A[ parent_ref_stack_A.maxindex ] }} 
            end
            if ( input_record_H[ K.fmtr_record ].key?( K.component_id )) then
                ao_buf_O.record_H = { K.component_id => input_record_H[ K.fmtr_record ][ K.component_id ] }
            end
            ao_buf_O.record_H = { K.title => input_record_H[ K.fmtr_record ][ K.title ] }
            if ( input_record_H[ K.fmtr_record ].key?( K.dates ) and
                 input_record_H[ K.fmtr_record ][ K.dates ].not_empty? ) then
                ao_buf_O.record_H = { K.dates => input_record_H[ K.fmtr_record ][ K.dates ] }
            end
            if ( input_record_H[ K.fmtr_record ].key?( K.notes ) and
               ! input_record_H[ K.fmtr_record ][ K.notes ].empty? ) then
                ao_buf_O.record_H = { K.notes => input_record_H[ K.fmtr_record ][ K.notes ] }
            end
            if ( input_record_H[ K.fmtr_record ].key?( K.fmtr_container ) and 
                 input_record_H[ K.fmtr_record ][ K.fmtr_container ].not_empty? ) then
                ao_buf_O.record_H[ K.instances ] = [ ] 
                SE.puts "#{SE.lineno}: More than one TC" if ( input_record_H[ K.fmtr_record ][ K.fmtr_container ].length > 1 )
                input_record_H[ K.fmtr_record ][ K.fmtr_container ].each do | container_H |
                    type           = container_H[ K.type ]
                    indicator      = container_H[ K.indicator ]
                    unique_TC_key  = "#{type}#{indicator}"
                    if ( tc_uri_H__by_type_and_indicator.has_no_key?( unique_TC_key ) ) then
                        tc_buf_O = Top_Container.new( res_buf_O ).new_buffer.create
                        tc_buf_O.record_H = { K.type => type }
                        tc_buf_O.record_H = { K.indicator => indicator }
                        tc_buf_O.store
                        tc_uri_H__by_type_and_indicator[ unique_TC_key ] = tc_buf_O.uri
                      # SE.q {'tc_uri_H__by_type_and_indicator'}
                    end

                    it_frag_O = Record_Format.new( :instance_type )
                    it_frag_O.record_H = { K.instance_type => K.mixed_materials}
                    it_frag_O.record_H = { K.sub_container => { K.top_container => { K.ref => tc_uri_H__by_type_and_indicator[ unique_TC_key ] }}}
                    it_frag_O.record_H = { K.sub_container => { K.type_2 => container_H[ K.type_2 ] }}
                    it_frag_O.record_H = { K.sub_container => { K.indicator_2 => container_H[ K.indicator_2 ] }}
                    if ( container_H[ K.type_3 ].not_nil? ) then
                        it_frag_O.record_H = { K.sub_container => { K.type_3 => container_H[ K.type_3 ] }}
                        it_frag_O.record_H = { K.sub_container => { K.indicator_3 => container_H[ K.indicator_3 ] }}
                    end

                    ao_buf_O.record_H[ K.instances ].push( it_frag_O.record_H )
                end
            end

          # SE.q {'ao_buf_O.record_H'}
            ao_buf_O.store
            last_AO_uri_created = ao_buf_O.uri
            next
        end
        SE.puts "#{SE.lineno}: I should't be here!"
        SE.q {'input_record_H'}
        raise
    end
end
#SE.q {'tc_uri_H__by_type_and_indicator'}
SE.puts "#{SE.lineno}: net indent count = #{net_indent_cnt}"
SE.puts "record counts:", record_level_cnt.ai



