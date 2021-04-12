=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                AS = ArchivesSpace
                IT = instance type
                TC = top container
                SC = Sub-container
                _H = Hash
                _J = Json string
                _A = Array
                _I = Index(of Array)
                _O = Object
                _Q = Query
               _0R = Zero Relative


Usage:  this_program.rb --res-num n [other options] FILE
        this_program.rb --help

To attach the records in FILE to the "Resource Record", only the --res-num option is needed.
To attach the records to a specific AO, enter the --res-num option along with:
    1)  the --ao-ref of the child AO. The --ao-ref is the long unique-id of the AO record that looks like this:
            aspace_dd30f87692b9fcc97b9a1e3fe14f8b40  (sometimes it won't have the 'aspace_' prefix)
    2)  the --ao-num of the child AO. The --ao-num is the number at the end of the AO's uri.
    3)  OR used the 'new_parent' record-type in the input FILE.


The input FILE has the following three formats( JSONized ):

        1 = {
              K.fmtr_record =>
                {
                  K.level => ''             # the AO level (eg. 'file', 'series', 'recordgrp', ...) -OR- a value of K.fmtr_new_parent.
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
    were tested.  If the record-type is 'K.fmtr_new_parent' this causes the program to find an existing AO record equal to
    the 'Title' value.  This AO then becomes the parent record for all subsequent records in FILE.

    Record format 2 causes all the records following the "indent => right" record to be attached to the record PRIOR to 
    the "indent => right" record.

    Record format 3 causes all the records following the "indent => left" record to be attached to the record PRIOR to
    the previous "indent => right" record. At the end of the program run, an "indent counter" is displayed, which should
    be 0 IF the number of right-dents equals the number left-dents.  Sometimes, there's no final indent-left tho.

=end

require "json"
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'

require 'class.Archivesspace.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'

def get_TC_buf_A( p1_res_buf_O, p2_TC_num_A )
    tc_buf_A = [ ]
    p2_TC_num_A.each { |current_TC_num|
        tc_buf_A << Top_Container.new( p1_res_buf_O, current_TC_num ).new_buffer.read
    }
    return tc_buf_A
end

def get_TC_buf_A__for_all_unused_AND_for_this_resource( p1_res_buf_O, p2_tc_buf_A )
    tc_buf_A__unused_and_this_resource=[ ]
    p2_tc_buf_A.each { |tc_buf_O|
        record_H = tc_buf_O.record_H
        if ( record_H.key?( K.collection ) && record_H[ K.collection ].count > 0 ) then
            record_H[ K.collection ].each { |ref_A|
                if ( ref_A.key?( K.ref ) ) then
                    if ( ref_A[ K.ref ] == p1_res_buf_O.uri ) then
                        tc_buf_A__unused_and_this_resource << [ tc_buf_O, '' ]
                    end
                end
            }
        else
            tc_buf_A__unused_and_this_resource << [ tc_buf_O, K.undefined ]
        end
    }
    return tc_buf_A__unused_and_this_resource
end

def get_A_of_AO_ref( p1_H_of_AO_ref_A )
    array_of_AO_ref= [ ]
    p1_H_of_AO_ref_A[ K.archival_objects ].each do |current_A_element| 
        array_of_AO_ref<< current_A_element[ K.ref ]
    end
#   SE.pp "#{SE.lineno}: array_of_AO_ref:", array_of_AO_ref
    return array_of_AO_ref
end
    

BEGIN {}
END {}

myself_name = File.basename( $0 )
api_uri_base = "http://localhost:8089"

cmdln_option = { :repository_num => 2  ,
                 :resource_num => nil  ,
                 :ao_ref => nil  ,
                 :ao_num => nil  ,
                 :delete_TC_only => false ,
                 :update => false ,
                 :last_record_num => nil}
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] FILE"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ :repository_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )" ) do |opt_arg|
        cmdln_option[ :resource_num ] = opt_arg
    end
    option.on( "--ao-ref x", "Archival Object ReferenceID ( optional, but must be member of suppled Resource number )" ) do |opt_arg|
        cmdln_option[ :ao_ref ] = opt_arg
    end
    option.on( "--ao-num n", OptionParser::DecimalInteger, "Archival Object URI number ( optional, but must be member of suppled Resource number )" ) do |opt_arg|
        cmdln_option[ :ao_num ] = opt_arg
    end
    option.on( "--delete-tc-only", "Delete TC records, then stop" ) do |opt_arg|
        cmdln_option[ :delete_TC_only ] = true
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
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV
if ( cmdln_option[ :repository_num ] ) then
    repository_num = cmdln_option[ :repository_num ]
else
    SE.puts "The --rep-num option is required."
    raise
end
if ( cmdln_option[ :resource_num ] ) then
    resource_num = cmdln_option[ :resource_num ]
else
    SE.puts "The --res-num option is required."
    raise
end
if ( cmdln_option[ :ao_ref ] ) then
    cmdln_AO_ref = cmdln_option[ :ao_ref ]      
else
    cmdln_AO_ref = nil
end
if ( cmdln_option[ :ao_num ] ) then
    cmdln_AO_num = cmdln_option[ :ao_num ]      
else
    cmdln_AO_num = nil
end
if ( cmdln_AO_ref and cmdln_AO_num ) then
    SE.puts "The --ao-ref and --ao-num options are mutually exclusive."
    raise
end

if ( cmdln_option[ :last_record_num ] ) then
    last_record_num = cmdln_option[ :last_record_num ]      
else
    last_record_num = nil
end
$global_update=cmdln_option[ :update ] 
delete_TC_records_only=cmdln_option[ :delete_TC_only ] 

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )
#SE.pom(aspace_O)
#SE.pov(aspace_O)
rep_O = Repository.new( aspace_O, repository_num )
#SE.pom(rep_O)
#SE.pov(rep_O)
res_O = Resource.new( rep_O, resource_num )
res_buf_O = res_O.new_buffer.read
#SE.pom(res_buf_O)
#SE.pov(res_buf_O)

res_Q_all_AO_O = nil
if ( cmdln_AO_ref ) then
    initial_parent_AO_uri = get_A_of_AO_ref( AO_Query.new( rep_O ).get_H_of_A_of_AO_ref__find_by_ref( [ cmdln_AO_ref ] ).result ) [ 0 ]
    SE.puts "#{SE.lineno}: initial_parent_AO_uri = #{initial_parent_AO_uri}"
    initial_parent_AO_H = Archival_Object.new( res_buf_O, initial_parent_AO_uri).new_buffer.read.record_H
elsif ( cmdln_AO_num ) then
    initial_parent_AO_H = Archival_Object.new( res_buf_O, cmdln_AO_num ).new_buffer.read.record_H
    initial_parent_AO_uri = initial_parent_AO_H[ K.uri ]
    SE.puts "#{SE.lineno}: initial_parent_AO_uri = #{initial_parent_AO_uri}"
else
    initial_parent_AO_H = res_buf_O.record_H
    initial_parent_AO_uri = initial_parent_AO_H[ K.uri ]
    SE.puts "#{SE.lineno}: initial_parent_AO_uri = #{initial_parent_AO_uri}"
    res_Q_all_AO_O = Resource_Query.new( res_O ).get_all_AO
    cnt = 0; res_Q_all_AO_O.buf_A.each do | ao_buf_O |
        cnt += 1
        SE.puts "#{ao_buf_O.record_H[ K.uri ]} '#{ao_buf_O.record_H[ K.title ]}'"
    end
end

SE.puts "Finding Top_Containers (which takes some time) ..."
tc_buf_A = get_TC_buf_A( res_buf_O, TC_Query.new( rep_O ).get_A_of_TC_nums( { 'all_ids' => 'true' } ).result )
#SE.pp "#{SE.lineno}: tc_buf_A.length = #{tc_buf_A.length}"

tc_buf_A__all_unused_AND_for_this_resource = get_TC_buf_A__for_all_unused_AND_for_this_resource( res_buf_O, tc_buf_A )
#SE.pp "#{SE.lineno}: tc_buf_A__all_unused_AND_for_this_resource = ", tc_buf_A__all_unused_AND_for_this_resource

tc_uri_H__by_type_and_indicator = {}
tc_buf_A__all_unused_AND_for_this_resource.each do |element|
    record_H = element[ 0 ].record_H
#   SE.pp record_H
    if ( element[ 1 ] == K.undefined ) then
        SE.puts "#{SE.lineno}: Delete top_container: #{record_H[ K.uri ]}"
        element[ 0 ].delete
    else
        if ( record_H.key?( K.type ) and record_H.key?( K.indicator )) then
            stringer=record_H[ K.type ] + record_H[ K.indicator ]
            if ( tc_uri_H__by_type_and_indicator.key?( stringer ) ) then
                SE.puts "#{SE.lineno}: Duplicate record_H 'type+indicator' #{stringer}, K.uri=#{record_H[ K.uri ]}"
                next
            end
            tc_uri_H__by_type_and_indicator[ stringer ] = record_H[ K.uri ]
        end   
    end 
end
if (delete_TC_records_only or ARGV.maxindex < 0 ) then
    exit
end

#SE.pp "tc_uri_H__by_type_and_indicator:", tc_uri_H__by_type_and_indicator

net_indent_cnt = 0
record_level_cnt = Hash.new(0)  # h.default works too...
last_AO_uri_created = ""
parent_ref_stack_A = [ initial_parent_AO_uri ]
initial_parent_AO_H = nil

for argv in ARGV do
    File.foreach( argv ) do |input_record_J|
        if ( last_record_num != nil and $. > last_record_num ) then 
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
                SE.puts "New parent: #{last_AO_uri_created}"
                next
            when K.fmtr_left then
                net_indent_cnt += -1
                parent_ref_stack_A.pop( 1 )
                last_AO_uri_created = parent_ref_stack_A[ parent_ref_stack_A.maxindex ]
                SE.puts "New parent: #{last_AO_uri_created}"
                next
            else
                SE.puts "#{SE.lineno}: Invalid indent direction '#{input_record_H[ K.fmtr_indent ][ 0 ]}'"
                raise                
            end
        end

        if ( input_record_H.key?( K.fmtr_record ) ) then
            SE.puts "#{SE.lineno}: '#{input_record_J}'"
            stringer = input_record_H[ K.fmtr_record ][ K.level ]
            record_level_cnt[ stringer ] += 1
            if ( stringer == K.fmtr_new_parent ) then
                if ( cmdln_AO_ref or cmdln_AO_num ) then
                    SE.puts "#{SE.lineno}: Hit 'new_parent' record, but"
                    SE.puts "the --ao-ref and --ao-num options aren't allowed for this record type."
                    raise
                end
                if ( parent_ref_stack_A.maxindex != 0 ) then
                    SE.puts "#{SE.lineno}: Hit 'new_parent' record, but parent_ref_stack_A.maxindex != 0"
                    SE.puts "The formatter should insure the indent level is at 0 for a 'new_parent' record."
                    SE.pp "parent_ref_stack_A:", parent_ref_stack_A
                    SE.pp "#{$.}: input_record_H:", input_record_H
                    raise
                end
                cnt = 0; res_Q_all_AO_O.buf_A.each do | ao_buf_O |
                    if ( input_record_H[ K.fmtr_record ][ K.title ].downcase == ao_buf_O.record_H[ K.title ].downcase ) then
                        parent_ref_stack_A[ 0 ] = ao_buf_O.record_H[ K.uri ]
                        SE.puts "New parent: #{ao_buf_O.record_H[ K.uri ]} '#{ao_buf_O.record_H[ K.title ]}'"
                        cnt += 1
                    end
                end
                if ( cnt == 0 ) then
                    SE.puts "#{SE.lineno}: Hit '#{K.fmtr_new_parent}' record, ",
                            "but couldn't find an AO with a Title of '#{input_record_H[ K.fmtr_record ][ K.title ]}'"
                    raise
                end
                if ( cnt > 1 ) then
                    SE.puts "#{SE.lineno}: Hit '#{K.fmtr_new_parent}' record, ",
                            "but found more than 1 AO with a Title of '#{input_record_H[ K.fmtr_record ][ K.title ]}'"
                    raise
                end
                next
            end

            ao_buf_O = Archival_Object.new( res_buf_O ).new_buffer.create( stringer )
#           SE.pp ao_buf_O.record_H
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
               ! input_record_H[ K.fmtr_record ][ K.dates ].empty? ) then
                ao_buf_O.record_H = { K.dates => input_record_H[ K.fmtr_record ][ K.dates ] }
            end
            if ( input_record_H[ K.fmtr_record ].key?( K.notes ) and
               ! input_record_H[ K.fmtr_record ][ K.notes ].empty? ) then
                ao_buf_O.record_H = { K.notes => input_record_H[ K.fmtr_record ][ K.notes ] }
            end
            if ( input_record_H[ K.fmtr_record ].key?( K.fmtr_container ) and 
               ! input_record_H[ K.fmtr_record ][ K.fmtr_container ].empty? ) then
                type      = "#{input_record_H[ K.fmtr_record ][ K.fmtr_container ][ K.fmtr_tc_type ]}"
                indicator = "#{input_record_H[ K.fmtr_record ][ K.fmtr_container ][ K.fmtr_tc_indicator ]}"
                unique_TC_key  = "#{type}#{indicator}"
                if ( ! tc_uri_H__by_type_and_indicator.key?( unique_TC_key ) ) then
                    tc_buf_O = Top_Container.new( res_buf_O ).new_buffer.create
                    tc_buf_O.record_H = { K.type => type }
                    tc_buf_O.record_H = { K.indicator => indicator }
                    tc_buf_O.store
                    tc_uri_H__by_type_and_indicator[ unique_TC_key ] = tc_buf_O.uri
 #                  SE.pp "#{SE.lineno}: tc_uri_H__by_type_and_indicator:", tc_uri_H__by_type_and_indicator
                end

                mm_frag_O = Record_Format.new( :instance_type )
                mm_frag_O.record_H = { K.instance_type => K.mixed_materials}
                mm_frag_O.record_H = { K.sub_container => { K.top_container => { K.ref => tc_uri_H__by_type_and_indicator[ unique_TC_key ] }}}
                mm_frag_O.record_H = { K.sub_container => { K.type_2 => input_record_H[ K.fmtr_record ][ K.fmtr_container ][ K.fmtr_sc_type ] }}
                mm_frag_O.record_H = { K.sub_container => { K.indicator_2 => input_record_H[ K.fmtr_record ][ K.fmtr_container ][ K.fmtr_sc_indicator ] }}

                ao_buf_O.record_H = { K.instances => [ mm_frag_O.record_H ] }
            end

#           SE.pp ao_buf_O.record_H
            ao_buf_O.store
            last_AO_uri_created = ao_buf_O.uri
            next
        end
        SE.puts "#{SE.lineno}: I should't be here!"
        SE.pp "#{$.}: input_record_H:", input_record_H
        raise
    end
end
#SE.pp "tc_uri_H__by_type_and_indicator:", tc_uri_H__by_type_and_indicator 
SE.puts "#{SE.lineno}: net indent count = #{net_indent_cnt}"
SE.pp "record counts:", record_level_cnt

