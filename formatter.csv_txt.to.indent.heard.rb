require 'Date'
require 'json'
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'class.ArchivesSpace.rb'


=begin

This formatter has a new feature of being able to supply a parent record to attach sub-record to.
When a 'new_parent' record is wanted, the K.fmtr_new_parent constant is put in the 'level' field of output_record_H.
The title of this record is then searched for in the add_objects program.  That then become the new_parent record
for subsequent records.   The add_objects program will fail if there's no match, more than one match,
or if the indent-level isn't 0.


Input file format                                       <<<<<<<<< Split records on ';', ignore blank lines.

Series 1: Special Trains                                <<<<<<<<< /^Series [0-9]+: / New Parent AO

Box 1                                                   <<<<<<<<< /^Box [0-9]+ *$/ New Box number IF no subject data

Folder 1; 50th Railroad  Anniversary Special, 1977      <<<<<<<<< /^Folder[s]? +/ Folder info.   Subject is rest of line.
Folder 2; 1977 AMTRAK Transcontinental Steam Excursion, [1975]-1977
Folders 3-4; The Adirondack [Press Kit], 1974-1980
Folder 5; American-European Express [Press Kit], 1989   <<<<<<<<< Folders (plural)

Box 47; Stations                                        <<<<<<<<< /^Box [0-9]+ /   New Box number.  Subject is rest of line.
Box 48; Stations

Sunset Limited inaugural                                <<<<<<<<< If no folder or Box, assume a group header but no ident.
Folders 19-22; Sunset Limited inaugural, April 1993
Folder 23; Alabama
Folder 24; Contacts

=end

def initialize_fmtr_container_H()
    fmtr_container_H = { K.fmtr_tc_type => K.undefined ,
                         K.fmtr_tc_indicator => K.undefined ,
                         K.fmtr_sc_type => K.undefined ,
                         K.fmtr_sc_indicator => K.undefined }
    return fmtr_container_H
end

fmtr_container_H = initialize_fmtr_container_H()
rec_cnt = 0
ARGF.each_line do |input_record|

#   if ( $. > 10 ) then 
#       break
#   end
    rec_cnt += 1
    input_record.chomp!
    if ( input_record.match?( /^\s*$/ ) ) then
        next
    end

    input_record_save = input_record + ''
    output_record_H = {}
    record_values = []
  
    input_record_A = input_record.split( ';' ).map( &:to_s ).map( &:strip )

    if ( input_record =~ /^series [0-9]+: /i ) then
        record_values << []                                 # No container info
        record_values << input_record
        output_record_H[ K.level ] = K.fmtr_new_parent
        output_record_H[ K.fmtr_record_indent_keys ] = []
        output_record_H[ K.fmtr_record_values ] = record_values
        output_record_H[ K.fmtr_record_num ] = "#{rec_cnt}"
        output_record_H[ K.fmtr_record_original ] = "#{input_record_save}"
        puts output_record_H.to_json
        next
    end

    if ( input_record =~ /^box +[0-9]+ *$/i ) then           # Box record with no subject info.
        fmtr_container_H[ K.fmtr_tc_type ] = K.box
        fmtr_container_H[ K.fmtr_tc_indicator ] = input_record.split( /\s/ ).map( &:to_s ).map( &:strip )[ 1 ]
        fmtr_container_H[ K.fmtr_sc_type ] = K.undefined
        fmtr_container_H[ K.fmtr_sc_indicator ] = K.undefined 
        next
    end

    if ( input_record_A[ 0 ] =~ /^box [0-9]+$/i ) then                         # Box record with subject, subject is in input_record_A[ 1 ]
        fmtr_container_H[ K.fmtr_tc_type ] = K.box
        fmtr_container_H[ K.fmtr_tc_indicator ] = input_record_A[ 0 ].split( /\s/ ).map( &:to_s ).map( &:strip )[ 1 ]
        fmtr_container_H[ K.fmtr_sc_type ] = ""                                 # No folder info
        fmtr_container_H[ K.fmtr_sc_indicator ] = "" 
        output_record_H[ K.level ] = K.file
        record_values << fmtr_container_H   
        record_values << input_record_A[ 1 ]  
 #      fmtr_container_H[ K.fmtr_tc_type ] = K.undefined               The boxes on these style records, shouldn't bleed-over to the next record.
 #      fmtr_container_H[ K.fmtr_tc_indicator ] = K.undefined          BUT, this doesn't work because the '<<' operator copies JUST the point of fmtr_container_H,
                                                                    # so setting the elements changes their value for when the pointer to the array is 
                                                                    # referenced below!
        fmtr_container_H = initialize_fmtr_container_H()    # Just do this to be save.
    else
        regexp = %r{^folder[s]? +}i
        if ( input_record_A[ 0 ] =~ regexp ) then                                    # Folder record, subject is in input_record_A[ 1 ]
            input_record_A[ 0 ].sub!( regexp, "" )
            fmtr_container_H[ K.fmtr_sc_type ] = K.folder
            fmtr_container_H[ K.fmtr_sc_indicator ] = input_record_A[ 0 ]
            output_record_H[ K.level ] = K.file
            record_values << fmtr_container_H 
            record_values << input_record_A[ 1 ]              
        else 
            output_record_H[ K.level ] = K.recordgrp
            record_values << []                                                                 # No container info on the GROUP: records.
            record_values << input_record_A[ 0 ]  
        end
    end
    
    output_record_H[ K.fmtr_record_indent_keys ] = []
    output_record_H[ K.fmtr_record_values ] = record_values
    output_record_H[ K.fmtr_record_num ] = "#{rec_cnt}"
    output_record_H[ K.fmtr_record_original ] = "#{input_record_save}"
    puts output_record_H.to_json

end
