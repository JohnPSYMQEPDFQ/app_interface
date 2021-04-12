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
require 'module.SE.rb'

require 'class.ArchivesSpace.rb'
require 'class.formatter.Record_Grouping_Indent.rb'

def put_indent( level_number_A, level_title_A )
    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    case level_number_A.maxindex 
    when -1
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "Wasn't expecting param1 level_number_A to be empty"
        raise
    when 0
        output_record_H[ K.fmtr_record ][ K.level ] = K.series
        output_record_H[ K.fmtr_record ][ K.title ] = "Series #{level_number_A.join( "." )}: #{level_title_A.join( ". " )}" 
    when 1
        output_record_H[ K.fmtr_record ][ K.level ] = K.subseries
        output_record_H[ K.fmtr_record ][ K.title ] = "Subseries #{level_number_A.join( "." )}: #{level_title_A.join( ". " )}" 
    else     
        output_record_H[ K.fmtr_record ][ K.level ] = K.recordgrp
        output_record_H[ K.fmtr_record ][ K.title ] = "#{level_title_A.join( ". " )}" 
    end
    puts output_record_H.to_json
end

def put_record( stack_record_H )

    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = stack_record_H[ K.level ]

#   stack_record__indent_keys_A = stack_record_H[ K.fmtr_record_indent_keys ]
    stack_record__values_A = stack_record_H[ K.fmtr_record_values ]
    output_record_H[ K.fmtr_record ][ K.fmtr_container ] = stack_record__values_A.shift( 1 )[ 0 ]

    stringer = stack_record__values_A[ 0.. stack_record__values_A.maxindex ].join( " " )
    output_record_H[ K.fmtr_record ][ K.title ] = stringer.strip.gsub( /\.$/,'' )

    output_record_H[ K.fmtr_record ][ K.notes ] = [ ]
    note_multipart_O = Record_Format.new( :note_multipart )
    note_multipart_O.record_H = { K.type => K.processinfo }
    note_text_O = Record_Format.new( :note_text )
    note_text_O.record_H = { K.content =>  "Original record text: '#{stack_record_H[ K.fmtr_record_original ]}'"}
    note_multipart_O.record_H = { K.subnotes => [  note_text_O.record_H ]}
    output_record_H[ K.fmtr_record ][ K.notes ].push( note_multipart_O.record_H )
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
