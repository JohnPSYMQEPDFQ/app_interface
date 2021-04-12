require 'Date'
require 'json'
require 'pp'
require 'optparse'

require 'class.ArchivesSpace.rb'

output_record_H = {}

#   Text; date
#   1     2
#               Date must be yyyy[-mm[-dd]] format (Aspace format)
#               If two dates, use '>' to separate (eg yyyy>yyyy)
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
        break if ( idx > 1 )
        a1.push( "" )
        idx += 1
    end

    date_A = [ ]
    if ( not ( a1[ 1 ] ==  "" ) ) then
        date_A = a1[ 1 ].split( '>' ).map( &:to_s ).map( &:strip )
        date_A.each_with_index do |current_date, idx|
            if ( current_date.length > 10 ) then
                SE.puts "#{SE.lineno}: bad date: #{idx}: " +
                        "#{input_record} -> #{current_date} -> Too long: #{current_date.length}"
                raise
            end
            if ( current_date.length < 4 ) then
                SE.puts "#{SE.lineno}: bad date: #{idx}: " +
                        "#{input_record} -> #{current_date} -> Too short: #{current_date.length}"
                raise
            end
            if ( current_date =~ /^[12][0-9]{3}$/ ) then
                current_date += "-01-01"
            elsif ( current_date =~ /^[12][0-9]{3}-[0-9]{2}$/ ) then
                current_date += "-01"
            elsif ( current_date =~ /^[12][0-9]{3}-[0-9]{2}-[0-9]{2}/ ) then
            else
                SE.puts "#{SE.lineno}: bad date: #{idx}: " +
                        "#{input_record} -> #{current_date} -> Bad format"
                raise
            end
            begin
                date_type=Date.parse( current_date )
                if ( date_type.year < 0 ) then
                    SE.puts "#{SE.lineno}: bad date: #{idx}: " +
                            "#{input_record} -> #{current_date} -> Failed conversion"
                    raise
                end
            rescue
                SE.puts "#{SE.lineno}: bad date: #{idx}: " +
                        "#{input_record} -> #{current_date} -> Failed conversion"
                raise
            end
        end
        if ( date_A.maxindex > 1 ) then
            SE.puts "#{SE.lineno}: bad date: #{a1[ 1 ]} -> #{input_date_string} -> #{date_A} -> more than 2 dates"
            raise
        end
        if ( date_A.maxindex == 1 ) then
            if ( date_A[1] < date_A[0] ) then
                SE.puts "#{SE.lineno}: bad date: #{a1[ 1 ]} -> #{input_date_string} -> #{date_A} -> " +
                        "date_A[1] < date_A[0]"
                raise
            end
        end 
        
    end
    
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = K.file 
    output_record_H[ K.fmtr_record ][ K.title ] = a1[ 0 ]

    if ( date_A.maxindex >= 0 ) then
        output_record_H[ K.fmtr_record ][ K.dates ] = [ ]
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
            SE.puts "#{SE.lineno}: Didn't expect date_A.maxindex to be > 1, the value is: #{date_A.maxindex}"
            SE.pp "#{SE.lineno}: date_A=", date_A
            raise
        end
    end
    puts output_record_H.to_json
end
