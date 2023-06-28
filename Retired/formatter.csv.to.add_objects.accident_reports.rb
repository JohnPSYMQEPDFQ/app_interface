require 'Date'
require 'json'
require 'pp'
require 'optparse'

require 'class.ArchivesSpace.rb'

output_record_H = {}

#   Text; date
#   1     2
#               Dates must be 3-char-alpha-month. day, year   MMM. dd, yyyy
ARGF.each_line do |input_record|


#   if ( $. > 10 ) then 
#       break
#   end
    input_record.chomp!
    if ( input_record.match?( /^\s*$/ ) ) then
        next
    end
  
    a1 = input_record.split( ';' ).map( &:to_s ).map( &:strip )
    idx=a1.maxindex; loop do
        break if ( idx > 2 )
        a1.push( "" )
        idx += 1
    end

    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = K.file 
    output_record_H[ K.fmtr_record ][ K.title ] = a1[ 0 ] + " " + a1[ 1 ]
    
    if ( not ( a1[ 2 ] ==  "" ) ) then
        begin
            record_date = a1[ 2 ]
            date_type=Date.parse( record_date )
            if ( date_type.year < 0 ) then
                SE.puts "#{SE.lineno}: bad date: #{idx}: " +
                        "#{input_record} -> #{record_date} -> Failed conversion"
                raise
            end
        rescue
            SE.puts "#{SE.lineno}: bad date: #{idx}: " +
                    "#{input_record} -> #{record_date} -> Failed conversion"
            raise
        end
        output_record_H[ K.fmtr_record ][ K.dates ] = [ ]
        single_date_O = Record_Format.new( :single_date )
        single_date_O.record_H = { K.label => K.existence }
        single_date_O.record_H = { K.begin => date_type }
        output_record_H[ K.fmtr_record ][ K.dates ].push( single_date_O.record_H )
    end

    puts output_record_H.to_json
end
