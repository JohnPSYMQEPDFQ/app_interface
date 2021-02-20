require 'Date'
require 'json'
require 'pp'
require 'optparse'

require 'class.ArchivesSpace.rb'

=begin        output_record_H
{
              K.record =>
                {
                  K.level => ''                     # the AO level (eg. 'file', 'series', 'recordgrp', ...) -OR- a value of K.new_parent.
                  K.title => '',                    # the AO title field.
-optional-        K.ao_date_array => [ ],           # An array of AO date hashes, single or inclusive.
-optional-        K.ao_note_array => [ ],           # An array of AO note hashes, singlepart or miltipart.
-optional-        K.container_format_1 =>           # References to TC of "type => indicator", creates the TC if needed.
                    {
                      K.tc_type      => 'VALUE'     # eg. 'box'
                      K.tc_indicator => 'n'         # Box number (must be a number)
                      K.sc_type      => 'VALUE'     # eg. 'folder'
                      K.sc_indicator => 'STRING'    # Anything identifing the folder
                    }
                }
            }
=end


=begin          input_record format:

Series 1: Financial Records
Abstract of disbursements, [Volume] Jan. 1910 - Dec. 1911 [Item 965, Box 299, Shelf I2.200.J6]

=end

BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option = { "r" => nil  ,
                 "s" => nil  }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [-r n] [-s] [file]"
    option.on( "-r n", OptionParser::DecimalInteger, "Input records to processes (includes blank records)." ) do |opt_arg|
        cmdln_option[ 'r' ] = opt_arg
    end
    option.on( "-s", "Output Series/Subseries records only (good for testing if they are present quickly)." ) do |opt_arg|
        cmdln_option[ 's' ] = opt_arg
    end
    option.on( "-h","--help" ) do
        Se.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV

indent_A = []
ARGF.each_line do |input_record|


    if ( cmdln_option[ 'r' ] and $. > cmdln_option[ 'r' ] ) then 
        break
    end
    input_record.chomp!
    if ( input_record.match?( /^\s*$/ ) ) then
        next
    end
    
#   Se.p input_record
    
    output_record_H = {}
    output_record_H[ K.record ] = {}
    
    regexp = %r/^(indent|\>):\s*/i
    if ( input_record =~ regexp ) then
        indent_A << input_record
        input_record.sub!( regexp, "" )
        output_record_H[ K.record ][ K.level ] = K.recordgrp
        output_record_H[ K.record ][ K.title ] = input_record
        if ( ! cmdln_option[ 's' ] ) then
            puts output_record_H.to_json
        end     
        output_record_H = { K.indent => [ K.right, input_record ] }
        puts output_record_H.to_json
        next
    end
    if ( input_record =~ /^(outdent|\<):/i ) then
        indent_A.pop
        output_record_H = { K.indent => [ K.left, input_record ] }
        puts output_record_H.to_json
        next
    end
  
    if ( input_record =~ /^(series|subseries) [0-9]+: /i ) then
        if ( indent_A.length > 0 ) then
            Se.puts "#{Se.lineno}: Hit series/subseries record but indent_A not empty"
            Se.pp indent_A
            Se.puts input_record
            raise
        end
        output_record_H[ K.record ][ K.level ] = K.new_parent
        output_record_H[ K.record ][ K.title ] = input_record
        puts output_record_H.to_json
        next
    end   
    
    if ( cmdln_option[ 's' ] ) then
        next
    end

    output_record_H[ K.record ][ K.level ] = K.file 
    output_record_H[ K.record ][ K.ao_note_array ] = [ ] 
    
    if ( location_string = input_record.scan( /\[.*?\]/ ).grep( /(box|folder|item|shelf) /i )[0] ) then
    
 #      Se.pp "location_string='#{location_string}' location_string.length=#{location_string.maxindex}"
        
        input_record[ location_string ] = ""
        location_item_A = location_string[ 1..location_string.maxindex - 1 ].split( "," ).map( &:to_s ).map( &:strip )
        container_format_1 = { K.tc_type => K.undefined ,
                               K.tc_indicator => K.undefined ,
                               K.sc_type => "" ,
                               K.sc_indicator => "" 
                             }
        location_item_A.each do |location_item|
            k, v, extra = location_item.split.map( &:to_s ).map( &:strip )
#           Se.puts "#{Se.lineno}: k=#{k}, v=#{v}, extra='#{extra}'"
            if ( extra ) then
                Se.puts "#{Se.lineno}: extra at '#{location_item}', k=#{k}, v=#{v}, extra='#{extra}'"
                Se.puts input_record
                raise
            end
            case k.downcase
            when 'box'
                if ( not v.integer? ) then
                    Se.puts "#{Se.lineno}: non-numeric Box number '#{v}'" 
                    Se.puts input_record
                    raise
                end
                container_format_1[ K.tc_type ] = K.box
                container_format_1[ K.tc_indicator ] = v
            when 'folder' 
                if ( not v.integer? ) then
                    Se.puts "#{Se.lineno}: non-numeric Item number '#{v}'"
                    Se.puts input_record
                    raise
                end   
                if ( container_format_1[ K.sc_type ] != "" ) then           
                    Se.puts "#{Se.lineno}: container_format_1[ K.sc_type ] = '#{container_format_1[ K.sc_type ]}', should be blank." 
                    Se.puts input_record
                    raise                   
                end
                container_format_1[ K.sc_type ] = K.folder
                container_format_1[ K.sc_indicator ] = v
            when 'item' 
                if ( not v.integer? ) then
                    Se.puts "#{Se.lineno}: non-numeric Item number '#{v}'"
                    Se.puts input_record
                    raise
                end
                if ( container_format_1[ K.sc_type ] != "" ) then
                    Se.puts "#{Se.lineno}: container_format_1[ K.sc_type ] = '#{container_format_1[ K.sc_type ]}', should be blank." 
                    Se.puts input_record
                    raise                   
                end                
                container_format_1[ K.sc_type ] = K.object   # 'Item'
                container_format_1[ K.sc_indicator ] = v
            when 'shelf'
                next
            else
                Se.puts "#{Se.lineno}: Unknown location type=#{k}"
            end
        end
        if ( container_format_1[ K.tc_type ] == K.box ) then    
            output_record_H[ K.record][ K.container_format_1 ] = container_format_1
            location_item_A = location_item_A.grep_v( /^(box|folder|item) /i )  # leave the 'shelf' in there.
        end
        if ( location_item_A.maxindex >= 0 ) then
            note_singlepart_O = Record_Format.new( :note_singlepart )
            note_singlepart_O.record_H = {
                                                K.type => K.physloc,    
                                                K.publish =>  true,
                                                K.content => [ location_item_A.join(", ") ],
                                                K.label => 'Statewide Museum Collections Center',
                                            }
            output_record_H[ K.record ][ K.ao_note_array ] << note_singlepart_O.record_H
        end
    end
   
    output_record_H[ K.record ][ K.title ] = input_record
    puts output_record_H.to_json
end

if ( indent_A.length > 0 ) then
    Se.puts "#{Se.lineno}: Hit end-of-file but indent_A not empty"
    Se.pp indent_A
    raise
end
