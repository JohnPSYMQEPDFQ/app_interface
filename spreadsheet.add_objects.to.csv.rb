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


Usage:  this_program.rb --ead TITLE [other options] FILE
        this_program.rb --help




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

require 'json'
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'

require 'class.Spreadsheet_CSV.rb'



BEGIN {}
END {}

binding.pry if ( respond_to? :pry )
myself_name = File.basename( $0 )


cmdln_option = { :starting_hierarchy => 2,
                 :ead => "",
                 :last_record_num => nil}
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] FILE"
    option.on( "--starting-hierarchy n", OptionParser::DecimalInteger, "Starting Hierarchy ( default = 2 )" ) do | opt_arg |
        cmdln_option[ :starting_hierarchy ] = opt_arg
    end
    option.on( "--ead x", "EAD (required)" ) do | opt_arg |
        cmdln_option[ :ead ] = opt_arg
    end
    option.on( "--last-record-num n", OptionParser::DecimalInteger, "Stop after record N" ) do | opt_arg |
        cmdln_option[ :last_record_num ] = opt_arg
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV
starting_hierarchy = cmdln_option[ :starting_hierarchy ]
if ( cmdln_option[ :ead ] == "" ) then
    SE.puts "The --ead TITLE is required."
    raise
end
last_record_num = cmdln_option[ :last_record_num ]      


CSV_O = Spreadsheet_CSV.new( cmdln_option[ :ead ] )

current_hierarchy = starting_hierarchy
record_level_cnt = Hash.new(0)  # h.default works too...

ARGF.each_line do |input_record_J|
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
            current_hierarchy += 1
            next
        when K.fmtr_left then
            current_hierarchy -= 1
            next
        else
            SE.puts "#{SE.lineno}: Invalid indent direction '#{input_record_H[ K.fmtr_indent ][ 0 ]}'"
            raise                
        end
    end

    if ( input_record_H.key?( K.fmtr_record ) ) then
#           SE.puts "#{SE.lineno}: '#{input_record_J}'"
        record_level = input_record_H[ K.fmtr_record ][ K.level ]
        record_level_cnt[ record_level ] += 1
 
        CSV_O.row_H[ K.title ] = input_record_H[ K.fmtr_record ][ K.title ] 
        CSV_O.row_H[ K.hierarchy ] = current_hierarchy
        CSV_O.row_H[ K.level ] = record_level
        if ( input_record_H[ K.fmtr_record ].key?( K.dates ) and ! input_record_H[ K.fmtr_record ][ K.dates ].empty? ) then
            CSV_O.load_dates( input_record_H[ K.fmtr_record ][ K.dates ] )
        end
        if ( input_record_H[ K.fmtr_record ].key?( K.notes ) and ! input_record_H[ K.fmtr_record ][ K.notes ].empty? ) then
            CSV_O.load_notes( input_record_H[ K.fmtr_record ][ K.notes ] )
        end
        CSV_O.puts_row
        next
    end
    SE.puts "#{SE.lineno}: I should't be here!"
    SE.ap "#{$.}: input_record_H:", input_record_H
    raise
end
#SE.ap "tc_uri_H__by_type_and_indicator:", tc_uri_H__by_type_and_indicator 
SE.puts ""
SE.puts "starting hierarchy = #{starting_hierarchy}"
SE.puts "  ending hierarchy = #{current_hierarchy}"
SE.puts "record counts:", record_level_cnt.ai

