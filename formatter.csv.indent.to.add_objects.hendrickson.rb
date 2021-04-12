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
require 'module.ArchivesSpace.Konstants.rb'
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
    output_record_H = {}
    stack_record__values = stack_record_H[ K.fmtr_record_values ]
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = K.file
    output_record_H[ K.fmtr_record ][ K.title ] = stack_record__values[ 0 ]
    output_record_H[ K.fmtr_record ][ K.fmtr_container ] = stack_record__values[ 1 ]
    puts output_record_H.to_json
end

BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option = { "last-record-num" => nil }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [--last-record-num n ]"
    option.on( "--last-record-num n", OptionParser::DecimalInteger, "Stop after record N" ) do |opt_arg|
        cmdln_option[ 'last-record-num' ] = opt_arg
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
last_record_num = cmdln_option[ 'last-record-num' ]

indent_keys = [ ]
box_folder_cnt__H = { }
Record_Grouping_Indent.new_with_flush( method( :put_record ), method( :put_indent ), 1 ) do |rgi_O|
    ARGF.each_line do |input_record|
        if ( ! last_record_num.nil? and $. >= last_record_num ) then 
            break
        end
    
        input_record.chomp!
        p "input_record:",  input_record if ( $DEBUG )
        if ( input_record.match?( /^\s*$/ ) ) then
            next
        end
    
        input_record__H = {}
        a1 = input_record.split( ';' ).map( &:to_s ).map( &:strip )
        if ( a1[0].downcase == "series" ) then
            a1.shift(1)
            indent_keys = []
            indent_keys.push( a1[0] ) 
            next
        end
        if (indent_keys.empty?) then
            SE.puts "#{SE.lineno}: #{$.}:#{input_record}"
            SE.puts "indent_keys.empty"
            raise
        end
        input_record__H[ K.fmtr_record_indent_keys ] =  indent_keys 
        box_num = a1[1]
        if ( ! box_folder_cnt__H.has_key? (box_num) ) then
            box_folder_cnt__H[ box_num ] = 0
        end
        cnt = box_folder_cnt__H[ box_num ] + 1
        box_folder_cnt__H[ box_num ] += a1[2].to_i

        if ( cnt == box_folder_cnt__H[ box_num ] ) then
            stringer = "#{cnt}"
        else
            stringer = "#{cnt} - #{box_folder_cnt__H[ box_num ]}"
        end
        fmtr_container_H = { K.fmtr_tc_type => K.box ,
                             K.fmtr_tc_indicator => box_num ,
                             K.fmtr_sc_type => K.folder ,
                             K.fmtr_sc_indicator => stringer  }
        input_record__H[ K.fmtr_record_values ] = [ a1[0], fmtr_container_H ]
        input_record__H[ K.fmtr_record_num ] = "#{$.}"
        input_record__H[ K.fmtr_record_original ] = "#{input_record}"
        rgi_O.add_record( input_record__H )
    end
end
