=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                TC = top container
                IT = instance type
                AS = ArchivesSpace
                _H = Hash
                _A = Array
                _I = Index (of Array)
                _O = Object
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
    output_record_H[ K.record ] = {}
    case level_number_A.maxindex 
    when -1
        Se.puts "#{Se.lineno}: =============================="
        Se.puts "Wasn't expecting param1 level_number_A to be empty"
        raise
    when 0
        output_record_H[ K.record ][ K.level ] = K.series
        output_record_H[ K.record ][ K.title ] = "Series #{level_number_A.join( "." )}: #{level_title_A.join( ". " )}" 
    when 1
        output_record_H[ K.record ][ K.level ] = K.subseries
        output_record_H[ K.record ][ K.title ] = "Subseries #{level_number_A.join( "." )}: #{level_title_A.join( ". " )}" 
    else     
        output_record_H[ K.record ][ K.level ] = K.recordgrp
        output_record_H[ K.record ][ K.title ] = "#{level_title_A.join( ". " )}" 
    end
    puts output_record_H.to_json
end

def put_record( stack_record_H )

    stack_record__indent_keys_A = stack_record_H[ K.record_indent_keys ]
    stack_record__values_A = stack_record_H[ K.record_values ]
    date_A = stack_record__values_A.pop( 1 )[ 0 ]

    output_record_H={}
    output_record_H[ K.record ] = {}
    output_record_H[ K.record ][ K.level ] = stack_record_H[ K.level ]
    stringer = stack_record__indent_keys_A[ 0..( stack_record__indent_keys_A.maxindex ) ].join( ". " ) +
               ". " +
               stack_record__values_A[ 0..( stack_record__values_A.maxindex - 1 ) ].join( " " )
    output_record_H[ K.record ][ K.title ] = stringer.strip.gsub( /\.$/,'' )
    output_record_H[ K.record ][ K.ao_note_array ] = [ ]
    output_record_H[ K.record ][ K.ao_date_array ] = [ ]

    if ( date_A.maxindex >= 0 ) then
        note_multipart_O = Record_Format.new( :note_multipart )
        note_multipart_O.record_H = { K.type  => K.processinfo }
        note_text_O = Record_Format.new( :note_text )
        note_text_O.record_H = { K.content => "Dates converted." } 
        note_multipart_O.record_H = { K.subnotes => [ note_text_O.record_H ] }
        output_record_H[ K.record ][ K.ao_note_array ].push( note_multipart_O.record_H )

        note_multipart_O = Record_Format.new( :note_multipart )
        note_multipart_O.record_H = {  K.type  => K.processinfo }
        note_text_O = Record_Format.new( :note_text )
        note_text_O.record_H = { K.content =>  "Original record num: #{stack_record_H[ K.record_num ]}, " +
                                               "Original record text: '#{stack_record_H[ K.record_original ]}'" }
        note_multipart_O.record_H = {  K.subnotes => [ note_text_O.record_H ] }
        output_record_H[ K.record ][ K.ao_note_array ].push( note_multipart_O.record_H )

        if ( date_A.maxindex == 0 ) then
            single_date_O = Record_Format.new( :single_date )
            single_date_O.record_H = { K.label => K.existence }
            single_date_O.record_H = { K.begin => date_A[ 0 ] }
            output_record_H[ K.record ][ K.ao_date_array ].push( single_date_O.record_H )
        end
        if ( date_A.maxindex == 1 ) then
            inclusive_dates_O = Record_Format.new( :inclusive_dates )
            inclusive_dates_O.record_H[ K.label ] = K.existence 
            inclusive_dates_O.record_H[ K.begin ] = date_A[ 0 ]
            inclusive_dates_O.record_H[ K.end ] = date_A[ 1 ]
            output_record_H[ K.record ][ K.ao_date_array ].push( inclusive_dates_O.record_H )
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
            output_record_H[ K.record ][ K.ao_note_array ].push( note_multipart_O.record_H )

            note_multipart_O = Record_Format.new( :note_multipart )
            note_multipart_O.record_H = { K.type => K.processinfo }
            note_text_O = Record_Format.new( :note_text )
            note_text_O.record_H = { K.content =>  "Original record num: #{stack_record_H[ 'record_num' ]}, " +
                                                   "Original record text: '#{stack_record_H[ 'original_input_record' ]}'"}
            note_multipart_O.record_H = { K.subnotes => [  note_text_O.record_H ]}
            output_record_H[ K.record ][ K.ao_note_array ].push( note_multipart_O.record_H )
        end
    end
    puts output_record_H.to_json
end

BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option = { "stack-size" => 2, "last-record-num" => nil }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ --stack-size n ] [--last-record-num n ]"
    option.on( "--stack-size n", OptionParser::DecimalInteger, "Zero relative stack size ( default = 2 )" ) do |opt_arg|
        cmdln_option[ 'stack-size' ] = opt_arg
    end
    option.on( "--last-record-num n", OptionParser::DecimalInteger, "Stop after record N" ) do |opt_arg|
        cmdln_option[ 'last-record-num' ] = opt_arg
    end
    option.on( "-h","--help" ) do
        warn option
        exit
    end
end.parse!  # Bang because ARGV is altered
last_record_num = cmdln_option[ 'last-record-num' ]

Record_Grouping_Indent.new_with_flush( method( :put_record ), method( :put_indent ), cmdln_option[ 'stack-size' ] ) do |rgi_O|

    ARGF.each_line do |input_record|

        input_record_H = JSON.parse( input_record )
        if ( ! last_record_num.nil? and $. > last_record_num ) then 
            break
        end

        p "input_record_H:",  input_record_H if ( $DEBUG )
        rgi_O.add_record( input_record_H )

    end

end
