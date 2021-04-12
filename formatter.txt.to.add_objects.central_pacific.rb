require 'Date'
require 'json'
require 'pp'
require 'optparse'

require 'class.ArchivesSpace.rb'

=begin        output_record_H
{
              K.fmtr_record =>
                {
                  K.level => ''                     # the AO level (eg. 'file', 'series', 'recordgrp', ...) -OR- a value of K.fmtr_new_parent.
                  K.title => '',                    # the AO title field.
-optional-        K.dates => [ ],                   # An array of AO date hashes, single or inclusive.
-optional-        K.notes => [ ],                   # An array of AO note hashes, singlepart or miltipart.
-optional-        K.fmtr_container =>               # References to TC of "type => indicator", creates the TC if needed.
                    {
                      K.fmtr_tc_type      => 'VALUE'     # eg. 'box'
                      K.fmtr_tc_indicator => 'n'         # Box number (must be a number)
                      K.fmtr_sc_type      => 'VALUE'     # eg. 'folder'
                      K.fmtr_sc_indicator => 'STRING'    # Anything identifing the folder
                    }
                }
            }
=end


=begin          post manually edited input_record format:

Series 1: Financial Records
Abstract of disbursements, [Volume] Jan. 1910 - Dec. 1911 [Item 965, Box 299, Shelf I2.200.J6]

>: Abstract of earnings and operating expenses
[Volume] 1864 - 1870 [Box 6, Shelf I2.300.H10]
[Volume] 1876 - 1879 [Item 252, Shelf I2.200.C10]
[Volume] 1880 - 1882 [Item 253, Shelf I2.200.C10]
[Volume] 1883 - 1885 [Item 254, Shelf I2.200.C10]
<:

Abstracts of cash disbursements, Sacramento Division, [Volume] Apr. - May 1912 [Item 653, Box 208, Shelf I2.200.C7]
Abstract of disbursements, [Volume] 1910-1912 [Shelf I2.308.Q4]
Abstract of earnings and operating expenses, [Volume] 1876 - 1879
Accounts payable, 1, [Volume] Jul. 1900 - Apr. 1906 [Item 312, Box 121, Shelf I2.200.B2]
Accounts payable journal, [Volume] May 1906 - Jun. 1959 [Item 109, Box 49, Shelf I2.200.A6]

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
        SE.puts option
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
    
#   SE.p input_record
    
    output_record_H = {}
    output_record_H[ K.fmtr_record ] = {}
    
    regexp = %r/^(indent|\>):\s*/i
    if ( input_record =~ regexp ) then
        indent_A << input_record
        input_record.sub!( regexp, "" )
        output_record_H[ K.fmtr_record ][ K.level ] = K.recordgrp
        output_record_H[ K.fmtr_record ][ K.title ] = input_record
        if ( ! cmdln_option[ 's' ] ) then
            puts output_record_H.to_json
        end     
        output_record_H = { K.fmtr_indent => [ K.fmtr_right, input_record ] }
        puts output_record_H.to_json
        next
    end
    if ( input_record =~ /^(outdent|\<):/i ) then
        indent_A.pop
        output_record_H = { K.fmtr_indent => [ K.fmtr_left, input_record ] }
        puts output_record_H.to_json
        next
    end
  
    if ( input_record =~ /^(series|subseries) [0-9]+: /i ) then
        if ( indent_A.length > 0 ) then
            SE.puts "#{SE.lineno}: Hit series/subseries record but indent_A not empty"
            SE.pp indent_A
            SE.puts input_record
            raise
        end
        output_record_H[ K.fmtr_record ][ K.level ] = K.fmtr_new_parent
        output_record_H[ K.fmtr_record ][ K.title ] = input_record
        puts output_record_H.to_json
        next
    end   
    
    if ( cmdln_option[ 's' ] ) then
        next
    end

    output_record_H[ K.fmtr_record ][ K.level ] = K.file 
    output_record_H[ K.fmtr_record ][ K.notes ] = [ ] 
    
    if ( location_string = input_record.scan( /\[.*?\]/ ).grep( /(box|folder|item|shelf) /i )[0] ) then
    
 #      SE.pp "location_string='#{location_string}' location_string.length=#{location_string.maxindex}"
        
        input_record[ location_string ] = ""
        location_item_A = location_string[ 1..location_string.maxindex - 1 ].split( "," ).map( &:to_s ).map( &:strip )
        fmtr_container_H = { K.fmtr_tc_type => K.undefined ,
                             K.fmtr_tc_indicator => K.undefined ,
                             K.fmtr_sc_type => "" ,
                             K.fmtr_sc_indicator => "" 
                           }
        location_item_A.each do |location_item|
            k, v, extra = location_item.split.map( &:to_s ).map( &:strip )
#           SE.puts "#{SE.lineno}: k=#{k}, v=#{v}, extra='#{extra}'"
            if ( extra ) then
                SE.puts "#{SE.lineno}: extra at '#{location_item}', k=#{k}, v=#{v}, extra='#{extra}'"
                SE.puts input_record
                raise
            end
            case k.downcase
            when 'box'
                if ( not v.integer? ) then
                    SE.puts "#{SE.lineno}: non-numeric Box number '#{v}'" 
                    SE.puts input_record
                    raise
                end
                fmtr_container_H[ K.fmtr_tc_type ] = K.box
                fmtr_container_H[ K.fmtr_tc_indicator ] = v
            when 'folder' 
                if ( not v.integer? ) then
                    SE.puts "#{SE.lineno}: non-numeric Item number '#{v}'"
                    SE.puts input_record
                    raise
                end   
                if ( fmtr_container_H[ K.fmtr_sc_type ] != "" ) then           
                    SE.puts "#{SE.lineno}: fmtr_container_H[ K.fmtr_sc_type ] = '#{fmtr_container_H[ K.fmtr_sc_type ]}', should be blank." 
                    SE.puts input_record
                    raise                   
                end
                fmtr_container_H[ K.fmtr_sc_type ] = K.folder
                fmtr_container_H[ K.fmtr_sc_indicator ] = v
            when 'item' 
                if ( not v.integer? ) then
                    SE.puts "#{SE.lineno}: non-numeric Item number '#{v}'"
                    SE.puts input_record
                    raise
                end
                if ( fmtr_container_H[ K.fmtr_sc_type ] != "" ) then
                    SE.puts "#{SE.lineno}: fmtr_container_H[ K.fmtr_sc_type ] = '#{fmtr_container_H[ K.fmtr_sc_type ]}', should be blank." 
                    SE.puts input_record
                    raise                   
                end                
                fmtr_container_H[ K.fmtr_sc_type ] = K.object   # 'Item'
                fmtr_container_H[ K.fmtr_sc_indicator ] = v
            when 'shelf'
                next
            else
                SE.puts "#{SE.lineno}: Unknown location type=#{k}"
            end
        end
        if ( fmtr_container_H[ K.fmtr_tc_type ] == K.box ) then    
            output_record_H[ K.fmtr_record][ K.fmtr_container ] = fmtr_container_H
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
            output_record_H[ K.fmtr_record ][ K.notes ] << note_singlepart_O.record_H
        end
    end
   
    output_record_H[ K.fmtr_record ][ K.title ] = input_record
    puts output_record_H.to_json
end

if ( indent_A.length > 0 ) then
    SE.puts "#{SE.lineno}: Hit end-of-file but indent_A not empty"
    SE.pp indent_A
    raise
end
