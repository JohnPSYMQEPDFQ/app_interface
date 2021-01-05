=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                AS = ArchivesSpace
                IT = instance type
                TC = top container
                SC = Sub-container
                _H = Hash
                _A = Array
                _I = Index(of Array)
                _O = Object
               _0R = Zero Relative


Usage: add_objects.rb --help

To attach the records in FILE to the "Resource Record", only the --resource-num option is needed.
To attach the records to a specific AO, enter the --resource-num option along with the --ao-ref
of the child AO. The --ref is the long unique-id of the record.


The input FILE has the following three formats( JSONized ):

        1 = {
              K.record =>
                {
                  K.level => ''             # the AO level (eg. 'file', 'series', ...)
                  K.title => '',            # the AO title field.
-optional-        K.dates => [ ],           # An array of AO date hashes, single or inclusive
-optional-        K.notes => [ ]            # An array of AO note hashes, singlepart or miltipart
-optional-        K.container_format_1 =>   # References to TC of "type > indicator", creates the TC if needed.
                    {
                      K.tc_type      => 'VALUE'     # eg. 'box'
                      K.tc_indicator => 'n'         # Box number (must be a number)
                      K.sc_type      => 'VALUE'     # eg. 'folder'
                      K.sc_indicator => 'STRING'    # Anything identifing the folder
                    }
                }
            }
  
        2 = {
              K.indent =>                   
                {
                  K.right => 'Any text'      # Text only used for debugging
                }
            }
  
        3 = {
              K.indent =>                   
                {
                  K.left => 'Any text'       # Text only used for debugging
                }
            }

    Record format 1 is the data record.  As-of 3/18/2020 only the "series", "subseries", "recordgrp", and "file" AO-level types
    were tested.

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
require 'module.Se.rb'

require 'class.Archivesspace.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'

def get_A_of_TC_H( p1_res_buf_O, p2_TC_num_A )
    array_of_TC_H = [ ]
    p2_TC_num_A.each { |current_TC_num|
        array_of_TC_H << Top_Container.new( p1_res_buf_O, current_TC_num ).new_buffer.read.record_H
    }
    return array_of_TC_H
end

def get_A_of_TC_H__for_all_unused_AND_for_this_resource( p1_res_buf_O, p2_array_of_TC_H )
    array_of_TC_H__unused_and_this_resource=[ ]
    p2_array_of_TC_H.each { |current_TC_H|
        if ( current_TC_H.key?( K.collection ) && current_TC_H[ K.collection ].count > 0 ) then
            current_TC_H[ K.collection ].each { |ref_A|
                if ( ref_A.key?( K.ref ) ) then
                    if ( ref_A[ K.ref ] == p1_res_buf_O.uri ) then
                        array_of_TC_H__unused_and_this_resource << [ '', current_TC_H ]
                    end
                end
            }
        else
            array_of_TC_H__unused_and_this_resource << [ K.unused, current_TC_H ]
        end
    }
    return array_of_TC_H__unused_and_this_resource
end

def get_A_of_AO_ref( p1_hash_of_AO_ref_A )
    array_of_AO_ref= [ ]
    p1_hash_of_AO_ref_A[ K.archival_objects ].each do |current_A_element| 
        array_of_AO_ref<< current_A_element[ K.ref ]
    end
#   Se.pp "#{Se.lineno}: array_of_AO_ref:", array_of_AO_ref
    return array_of_AO_ref
end
    

BEGIN {}
END {}

myself_name = File.basename( $0 )
api_uri_base = "http://localhost:8089"

cmdln_option = { "repository-num" => 2  ,
                 "resource-num" => nil  ,
                 "ao-ref" => nil  ,
                 "delete-TC-only" => false ,
                 "delete-tc-only" => false ,
                 "update" => false ,
                 'last_record_num' => nil}
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ] FILE"
    option.on( "--repository-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ 'repository-num' ] = opt_arg
    end
    option.on( "--resource-num n", OptionParser::DecimalInteger, "Resource number ( required )" ) do |opt_arg|
        cmdln_option[ 'resource-num' ] = opt_arg
    end
    option.on( "--ao-ref x", "Archival Object ReferenceID ( optional, but must be member of suppled Resource number )" ) do |opt_arg|
        cmdln_option[ 'ao-ref' ] = opt_arg
    end
    option.on( "--delete-TC-only", "Delete TC records only" ) do |opt_arg|
        cmdln_option[ 'delete-TC-only' ] = true
    end
    option.on( "--delete-tc-only", "Delete TC records only" ) do |opt_arg|
        cmdln_option[ 'delete-TC-only' ] = true
    end
    option.on( "--update", "Do updates" ) do |opt_arg|
        cmdln_option[ 'update' ] = true
    end
    option.on( "--last-record-num n", OptionParser::DecimalInteger, "Stop after record N" ) do |opt_arg|
        cmdln_option[ 'last-record-num' ] = opt_arg
    end
    option.on( "-h","--help" ) do
        Se.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV
if ( cmdln_option[ 'repository-num' ] ) then
    repository_num = cmdln_option[ 'repository-num' ]
else
    Se.puts "The --repository-num option is required."
    raise
end
if ( cmdln_option[ 'resource-num' ] ) then
    resource_num = cmdln_option[ 'resource-num' ]
else
    Se.puts "The --resource-num option is required."
    raise
end
if ( cmdln_option[ 'ao-ref' ] ) then
    cmdln_AO_ref = cmdln_option[ 'ao-ref' ]      
else
    cmdln_AO_ref = nil
end
if ( cmdln_option[ 'last-record-num' ] ) then
    last_record_num = cmdln_option[ 'last-record-num' ]      
else
    last_record_num = nil
end
$global_update=cmdln_option[ 'update' ] 
delete_TC_records_only=cmdln_option[ 'delete-TC-only' ] 

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )
#Se.pom(aspace_O)
#Se.pov(aspace_O)
rep_O = Repository.new( aspace_O, repository_num )
#Se.pom(rep_O)
#Se.pov(rep_O)
res_buf_O = Resource.new( rep_O, resource_num ).new_buffer.read
#Se.pom(res_buf_O)
#Se.pov(res_buf_O)

if ( cmdln_AO_ref ) then
    initial_parent_AO_uri = get_A_of_AO_ref( AO_Query.new( rep_O ).get_H_of_A_of_AO_ref__find_by_ref( [ cmdln_AO_ref ] ).result ) [ 0 ]
    Se.puts "#{Se.lineno}: initial_parent_AO_uri = #{initial_parent_AO_uri}"
    initial_parent_AO_H = Archival_Object.new(res_buf_O, initial_parent_AO_uri).new_buffer.read.record_H
else
    initial_parent_AO_H = res_buf_O.record_H
    initial_parent_AO_uri = initial_parent_AO_H[ K.uri ]
    Se.puts "#{Se.lineno}: initial_parent_AO_uri = #{initial_parent_AO_uri}"
end

array_of_TC_H = get_A_of_TC_H( res_buf_O, TC_Query.new( rep_O ).get_A_of_TC_nums( { 'all_ids' => 'true' } ).result )
#Se.pp "#{Se.lineno}: array_of_TC_H = ", array_of_TC_H
array_of_TC_H__all_unused_AND_for_this_resource = get_A_of_TC_H__for_all_unused_AND_for_this_resource( res_buf_O, array_of_TC_H )
#Se.pp "#{Se.lineno}: array_of_TC_H__all_unused_AND_for_this_resource = ", array_of_TC_H__all_unused_AND_for_this_resource

hash_of_TC_uri__by_type_indicator = {}
array_of_TC_H__all_unused_AND_for_this_resource.each do |element|
    current_TC_H = element[ 1 ]
#   Se.pp current_TC_H
    if ( element[ 0 ] == K.unused ) then
        Se.puts "#{Se.lineno}: Delete top_container: #{current_TC_H[ K.uri ]}"
        Top_Container.new( res_buf_O, current_TC_H[ K.uri ] ).new_buffer.delete
    else
        if ( current_TC_H.key?( K.type ) and current_TC_H.key?( K.indicator )) then
            stringer=current_TC_H[ K.type ] + current_TC_H[ K.indicator ]
            if ( hash_of_TC_uri__by_type_indicator.key?( stringer ) ) then
                Se.puts "#{Se.lineno}: Duplicate current_TC_H 'type+indicator' #{stringer}, K.uri=#{current_TC_H[ K.uri ]}"
                next
            end
            hash_of_TC_uri__by_type_indicator[ stringer ] = current_TC_H[ K.uri ]
        end   
    end 
end
if (delete_TC_records_only) then
    exit
end

#Se.pp "hash_of_TC_uri__by_type_indicator:", hash_of_TC_uri__by_type_indicator

indent_cnt = 0
record_level_cnt = Hash.new(0)  # h.default works too...
last_AO_uri_created = ""
parent_ref_stack_A = [ initial_parent_AO_uri ]

for argv in ARGV do
    File.foreach( argv ) do |input_record_json|
        if ( last_record_num != nil and $. > last_record_num ) then 
            break
        end
        input_record_json.chomp!
        if ( input_record_json.match?( /^\s*$/ ) ) then
            next
        end
        input_record_H = JSON.parse( input_record_json )

        if ( input_record_H.key?( K.indent ) ) then
            Se.puts "#{Se.lineno}: Rec:#{$.}: '#{input_record_json}'"
            if ( input_record_H[ K.indent ][ 0 ] == K.right ) then
                indent_cnt += 1
                parent_ref_stack_A.push( last_AO_uri_created )
                next
            end
            if ( input_record_H[ K.indent ][ 0 ] == K.left ) then
                indent_cnt += -1
                last_AO_uri_created=parent_ref_stack_A.pop( 1 )[ 0 ]
                next
            end
        end

        if ( input_record_H.key?( K.record ) ) then
            Se.puts "#{Se.lineno}: Rec:#{$.}: '#{input_record_json}'"
            stringer = input_record_H[ K.record ][ K.level ]
            ao_buf_O = Archival_Object.new( res_buf_O ).new_buffer.create( stringer )
#           Se.pp ao_buf_O.record_H
            record_level_cnt[ stringer ] += 1
            if ( ao_buf_O.record_H[ K.resource ][ K.ref ] == parent_ref_stack_A[ parent_ref_stack_A.maxindex ] ) then
                ao_buf_O.record_H = { K.parent => '' }
            else
                ao_buf_O.record_H = { K.parent => { K.ref => parent_ref_stack_A[ parent_ref_stack_A.maxindex ] }} 
            end
            ao_buf_O.record_H = { K.title => input_record_H[ K.record ][ K.title ] }
            if ( input_record_H[ K.record ].key?( K.ao_date_array ) and
               ! input_record_H[ K.record ][ K.ao_date_array ].empty? ) then
                ao_buf_O.record_H = { K.dates => input_record_H[ K.record ][ K.ao_date_array ] }
            end
            if ( input_record_H[ K.record ].key?( K.ao_note_array ) and
               ! input_record_H[ K.record ][ K.ao_note_array ].empty? ) then
                ao_buf_O.record_H = { K.notes => input_record_H[ K.record ][ K.ao_note_array ] }
            end
            if ( input_record_H[ K.record ].key?( K.container_format_1 ) and 
               ! input_record_H[ K.record ][ K.container_format_1 ].empty? ) then
                type      = "#{input_record_H[ K.record ][ K.container_format_1 ][ K.tc_type ]}"
                indicator = "#{input_record_H[ K.record ][ K.container_format_1 ][ K.tc_indicator ]}"
                unique_TC_key  = "#{type}#{indicator}"
                if ( ! hash_of_TC_uri__by_type_indicator.key?( unique_TC_key ) ) then
                    tc_buf_O = Top_Container.new( res_buf_O ).new_buffer.create
                    tc_buf_O.record_H = { K.type => type }
                    tc_buf_O.record_H = { K.indicator => indicator }
                    tc_buf_O.store
                    hash_of_TC_uri__by_type_indicator[ unique_TC_key ] = tc_buf_O.uri
                    Se.pp "#{Se.lineno}: hash_of_TC_uri__by_type_indicator:", hash_of_TC_uri__by_type_indicator
                end

                mm_frag_O = Record_Format.new( :instance_type )
                mm_frag_O.record_H = { K.instance_type => K.mixed_materials}
                mm_frag_O.record_H = { K.sub_container => { K.top_container => { K.ref => hash_of_TC_uri__by_type_indicator[ unique_TC_key ] }}}
                mm_frag_O.record_H = { K.sub_container => { K.type_2 => input_record_H[ K.record ][ K.container_format_1 ][ K.sc_type ] }}
                mm_frag_O.record_H = { K.sub_container => { K.indicator_2 => input_record_H[ K.record ][ K.container_format_1 ][ K.sc_indicator ] }}

                ao_buf_O.record_H = { K.instances => [ mm_frag_O.record_H ] }
            end

#           Se.pp ao_buf_O.record_H
            ao_buf_O.store
            last_AO_uri_created = ao_buf_O.uri
            next
        end
        Se.puts "#{Se.lineno}: I should't be here!"
        Se.pp "#{$.}: input_record_H:", input_record_H
        raise
    end
end
Se.puts "#{Se.lineno}: indent count = #{indent_cnt}"
Se.pp "record counts:", record_level_cnt
Se.pp "hash_of_TC_uri__by_type_indicator:", hash_of_TC_uri__by_type_indicator 
