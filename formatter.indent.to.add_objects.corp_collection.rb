=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                TC = top container
                IT = instance type
                AS = ArchivesSpace
                _H = Hash
                _A = Array
                _I = Index (of Array)
                _O = Object
                _G = Global
               _0R = Zero Relative

Usage: format_for_add_object.rb --help


=end

require "json"
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'module.Se.rb'

require 'class.ArchivesSpace.rb'
require 'class.formatter.Record_Grouping_Indent.rb'

def put_indent( level_number_A, level_title_A )
    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    case level_number_A.length 
    when 0
        Se.puts "#{Se.lineno}: =============================="
        Se.puts "Wasn't expecting param1 level_number_A to be empty"
        raise
    when 1
        output_record_H[ K.fmtr_record ][ K.level ] = K.series
        stringer = "Series"
        if ( level_number_A.length <= $cmdln_option_G[ :max_levels ] ) then
            stringer += " #{level_number_A.join( "." )}" 
            output_record_H[ K.fmtr_record ][ K.component_id ] = level_number_A.join( "." )
        end
        stringer += ": #{level_title_A.join( ". " )}"  
        output_record_H[ K.fmtr_record ][ K.title ] = stringer
    
    when 2 .. $cmdln_option_G[ :max_series ] 
        output_record_H[ K.fmtr_record ][ K.level ] = K.subseries
        stringer = "Subseries"
        if ( level_number_A.length <= $cmdln_option_G[ :max_levels ] ) then
            stringer += " #{level_number_A.join( "." )}" 
            output_record_H[ K.fmtr_record ][ K.component_id ] = level_number_A.join( "." ) 
        end
        stringer += ": #{level_title_A.join( ". " )}"  
        output_record_H[ K.fmtr_record ][ K.title ] = stringer        
    else     
        output_record_H[ K.fmtr_record ][ K.level ] = K.recordgrp
        stringer = ""
        if ( level_number_A.length <= $cmdln_option_G[ :max_levels ] )
            stringer += "#{level_number_A.join( "." )}: " 
            output_record_H[ K.fmtr_record ][ K.component_id ] = level_number_A.join( "." ) 
        end
        stringer += "#{level_title_A.join( ". " )}"
        output_record_H[ K.fmtr_record ][ K.title ] = stringer
    end
    output_record_H[ K.fmtr_record ][ K.title ]
    puts output_record_H.to_json
end

def put_record( stack_record_H )

    stack_record__indent_keys_A = stack_record_H[ K.fmtr_record_indent_keys ]
    stack_record__values_A = stack_record_H[ K.fmtr_record_values ]
    date_A = stack_record__values_A.pop( 1 )[ 0 ]

    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = stack_record_H[ K.level ]
    stringer = stack_record__indent_keys_A[ 0..( stack_record__indent_keys_A.maxindex ) ].join( ". " ) +
               ". " +
               stack_record__values_A[ 0..( stack_record__values_A.maxindex - 1 ) ].join( " " )
    output_record_H[ K.fmtr_record ][ K.title ] = stringer.strip.gsub( /\.$/,'' )
    output_record_H[ K.fmtr_record ][ K.notes ] = [ ]
    output_record_H[ K.fmtr_record ][ K.dates ] = [ ]

    if ( date_A.maxindex >= 0 ) then
        note_multipart_O = Record_Format.new( :note_multipart )
        note_multipart_O.record_H = { K.type  => K.processinfo }
        note_text_O = Record_Format.new( :note_text )
        note_text_O.record_H = { K.content => "Dates converted." } 
        note_multipart_O.record_H = { K.subnotes => [ note_text_O.record_H ] }
        output_record_H[ K.fmtr_record ][ K.notes ].push( note_multipart_O.record_H )

        note_multipart_O = Record_Format.new( :note_multipart )
        note_multipart_O.record_H = {  K.type  => K.processinfo }
        note_text_O = Record_Format.new( :note_text )
        note_text_O.record_H = { K.content =>  "Original record num: #{stack_record_H[ K.fmtr_record_num ]}, " +
                                               "Original record text: '#{stack_record_H[ K.fmtr_record_original ]}'" }
        note_multipart_O.record_H = {  K.subnotes => [ note_text_O.record_H ] }
        output_record_H[ K.fmtr_record ][ K.notes ].push( note_multipart_O.record_H )

        if ( date_A.maxindex == 0 ) then
            single_date_O = Record_Format.new( :single_date )
            single_date_O.record_H = { K.label => K.existence }
            single_date_O.record_H = { K.begin => date_A[ 0 ] }
            output_record_H[ K.fmtr_record ][ K.dates ].push( single_date_O.record_H )
        end
        if ( date_A.maxindex == 1 ) then
            inclusive_dates_O = Record_Format.new( :inclusive_dates )
            inclusive_dates_O.record_H[ K.label ] = K.existence 
            inclusive_dates_O.record_H[ K.begin ] = date_A[ 0 ]
            inclusive_dates_O.record_H[ K.end ] = date_A[ 1 ]
            output_record_H[ K.fmtr_record ][ K.dates ].push( inclusive_dates_O.record_H )
        end
        if ( date_A.maxindex > 1 ) then
            Se.puts "#{Se.lineno}: Didn't expect date_A.maxindex to be > 1, the value is: #{date_A.maxindex}"
            Se.pp "#{Se.lineno}: date_A=", date_A
            raise
        end
    else
        if ( ! ( stack_record__values_A[ 2 ].downcase.in?( [ "", "not dated" ] ) ) ) then
            note_multipart_O = Record_Format.new( :note_multipart )
            note_multipart_O.record_H = { K.type => K.processinfo }
            note_text_O = Record_Format.new( :note_text )
            note_text_O.record_H = { K.content => "Unable to convert dates." }
            note_multipart_O.record_H = { K.subnotes => [  note_text_O.record_H ]}
            output_record_H[ K.fmtr_record ][ K.notes ].push( note_multipart_O.record_H )

            note_multipart_O = Record_Format.new( :note_multipart )
            note_multipart_O.record_H = { K.type => K.processinfo }
            note_text_O = Record_Format.new( :note_text )
            note_text_O.record_H = { K.content =>  "Original record num: #{stack_record_H[ 'record_num' ]}, " +
                                                   "Original record text: '#{stack_record_H[ 'original_input_record' ]}'"}
            note_multipart_O.record_H = { K.subnotes => [  note_text_O.record_H ]}
            output_record_H[ K.fmtr_record ][ K.notes ].push( note_multipart_O.record_H )
        end
    end
    puts output_record_H.to_json
end

BEGIN {}
END {}

myself_name = File.basename( $0 )

$cmdln_option_G = { :min_group_size => 5, 
                    :max_series => 2,
                    :max_levels => nil,
                    :r => nil }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"
    option.on( "-g n", "--min-group-size n", OptionParser::DecimalInteger, "Min records in a Series/Subseries/Record-group (default = 5)" ) do |opt_arg|
        $cmdln_option_G[ :min_group_size ] = opt_arg
    end
    option.on( "-s n", "--max-series n", OptionParser::DecimalInteger, "Max number of Series/Subseries (default = 2)" ) do |opt_arg|
        $cmdln_option_G[ :max_series ] = opt_arg
    end
    option.on( "-l n", "--max-levels n", OptionParser::DecimalInteger, "Max number of N.N.N things to show (default --max-series)" ) do |opt_arg|
        $cmdln_option_G[ :max_levels ] = opt_arg
    end
    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        $cmdln_option_G[ :r ] = opt_arg
    end
    option.on( "-h", "--help" ) do
        warn option
        exit
    end
end.parse!  # Bang because ARGV is altered
$cmdln_option_G[ :min_group_size ] -= 1                   # min-group-size is zero relative.
$cmdln_option_G[ :min_group_size ] = 0 if ( $cmdln_option_G[ :min_group_size ] < 0 )

if ( not $cmdln_option_G[ :max_levels] ) then
    $cmdln_option_G[ :max_levels ] = $cmdln_option_G[ :max_series]
end

Record_Grouping_Indent.new_with_flush( method( :put_record ), method( :put_indent ), $cmdln_option_G[ :min_group_size ] ) do |rgi_O|

    ARGF.each_line do |input_record|

        input_record_H = JSON.parse( input_record )
        if ( $cmdln_option_G[ :r ] and $. > $cmdln_option_G[ :r ] ) then 
            break
        end

        p "input_record_H:",  input_record_H if ( $DEBUG )
        rgi_O.add_record( input_record_H )

    end

end
