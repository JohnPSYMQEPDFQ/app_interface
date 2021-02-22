require 'Date'
require 'json'
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'module.Se.rb'
require 'module.ArchivesSpace.Konstants.rb'

myself_name = File.basename( $0 )

$cmdln_option_G = { :max_levels => 5,
                    :r => nil }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"
    option.on( "-l n", "--max-levels n", OptionParser::DecimalInteger, "Max number of level to group on (default 5)" ) do |opt_arg|
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
$cmdln_option_G[ :max_levels ] -= 1                   # :max_levels is zero relative.
$cmdln_option_G[ :max_levels ] = 1 if ( $cmdln_option_G[ :max_levels ] < 1 )

output_record_H = {}

#   Record ID;Subject Heading;General Heading Note;Title;Number;Date;Geographic Location;-Corporate Name;Personal Name
#   0         1               2                    3     4      5    6                   7               8
ARGF.each_line do |input_record|

    if ( $cmdln_option_G[ :r ] and $. > $cmdln_option_G[ :r ] ) then 
        break
    end

    input_record.chomp!
    if ( input_record.match?( /^\s*$/ ) ) then
        next
    end
  
    a1 = input_record.split( ';' ).map( &:to_s ).map( &:strip )
    idx=a1.maxindex; loop do
        break if ( idx > 8 )
        a1.push( "" )
        idx += 1
    end

    input_date_A = [ ]
    if ( ! ( a1[ 5 ].downcase.in?( [ 'not dated', "" ] ) ) ) then
        input_date_string="#{a1[ 5 ]}"
        if ( a1[ 5 ] =~ /^[12][0-9]{3}\-[12][0-9]{3}$/ ) then
            input_date_string.gsub!( /\-/, ">" ) 
        end
        input_date_string.split( /[;\>\/]/ ).each_with_index do |current_date, idx|
            if ( current_date.length > 14 ) then
                Se.puts "#{Se.lineno}: bad date: #{idx}: #{a1[ 5 ]} -> " +
                            "#{input_date_string} -> #{current_date} -> Too long: #{current_date.length}"
                next
            end
            if ( current_date =~ /^[12][0-9]{3}$/ ) then
                input_date_A.push( current_date )
#               Se.puts "#{Se.lineno}: good date: #{idx}: #{a1[ 5 ]} -> #{input_date_string} -> #{current_date} -> year-only"
                next
            end
            if ( current_date.length < 5 ) then
                Se.puts "#{Se.lineno}: bad date: #{idx}: #{a1[ 5 ]} -> #{input_date_string} -> " +
                            "#{current_date} -> Too short: #{current_date.length}"
                next
            end
            if ( current_date =~ /-/ and current_date =~ /,/) then
                Se.puts "#{Se.lineno}: bad date: #{idx}: #{a1[ 5 ]} -> #{input_date_string} -> " +
                            "#{current_date} -> mix of '-' & ','"
                next
            end
            if ( current_date =~ /^(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)-[0-9]{2}$/i ) then
                Se.puts "#{Se.lineno}: MOD date: #{idx}: #{a1[ 5 ]} -> #{input_date_string} -> " +
                            "#{current_date} -> appended '01-'"
                current_date = "01-" + current_date
            end
            begin
                date_type=Date.parse( current_date )
                if ( date_type.year < 0 ) then
                    Se.puts "#{Se.lineno}: bad date: #{idx}: #{a1[ 5 ]} -> #{input_date_string} -> " +
                                "#{current_date} -> #{date_type}"
                else
                    if ( date_type.year >= 2000 ) then
                        date_type = Date.new( date_type.year - 100, date_type.mon, date_type.mday )
#                       Se.puts "#{Se.lineno}: MOD date: #{idx}: #{a1[ 5 ]} -> #{input_date_string} -> " +
#                                   "#{current_date} -> changed year to 1900"
                    end
                    input_date_A.push( date_type )
#                   Se.puts "#{Se.lineno}: good date: #{idx}: #{a1[ 5 ]} -> #{input_date_string} -> " +
#                               "#{current_date} -> #{date_type}"
                    next
                end
            rescue
                Se.puts "#{Se.lineno}: bad date: #{idx}: #{a1[ 5 ]} -> #{input_date_string} -> #{current_date}"
            end
        end
        if ( input_date_A.maxindex > 1 ) then
            Se.puts "#{Se.lineno}: bad date: #{a1[ 5 ]} -> #{input_date_string} -> #{input_date_A} -> more than 2 dates"
            input_date_A = [ ]
        end
        if ( input_date_A.maxindex == 1 ) then
            if ( input_date_A[1] < input_date_A[0] ) then
                Se.puts "#{Se.lineno}: bad date: #{a1[ 5 ]} -> #{input_date_string} -> #{input_date_A} -> " +
                            "input_date_A[1] < input_date_A[0]"
                input_date_A = [ ]
            end
        end 
        
    end
    
    a2 = [ ]
    a2.push( a1[ 7 ] )                      # 0
    a2.push( a1[ 1 ] )                      # 1
    a2.push( a1[ 2 ] )                      # 2
    if ( a1[ 6 ] == "" or a1[ 1 ].downcase == "locations" ) then
        a2.push( a1[ 6 ] )                  # 3
    else 
        a2.push( "Locations. #{a1[ 6 ]}" )  # 3 
    end
    a2.push( a1[ 3 ] )                      # 4
    a2.push( a1[ 4 ] )                      # 5
    if ( input_date_A.maxindex >= 0 ) then
        a2.push( "" )                       # 6
    else
        if ( a1[ 5 ].downcase.in?( [ "", "not dated" ] ) ) then
            a2.push( a1[ 5 ] )              # 6
        else
            a2.push( "Dates: #{a1[ 5 ]}" )  # 6
        end
    end
    if ( a1[ 8 ] == "" ) then
        a2.push( a1[ 8 ] )                  # 7
    else
        a2.push( "Person #{a1[ 8 ]}" )      # 7
    end
    a2.push( a1[ 0 ] )                      # 8
    a2.push( input_date_A )                 # 9

    record_values = [ ]
    got_record=false
    loop do
        break if ( a2.maxindex < 1 )
        stringer=a2.pop( 1 )[ 0 ]
        got_record = ( got_record or stringer != "" )
        record_values.unshift( stringer )
        break if ( got_record and a2.maxindex < $cmdln_option_G[ :max_levels ] ) 
    end

    indent_keys = [ ] 
    loop do
        break if ( a2.maxindex < 0 )
        stringer=a2.pop( 1 )[ 0 ]
        if ( stringer.match?( /\./ ) ) then
            a3 = stringer.split( /\./ ).map( &:to_s ).map( &:strip )
            loop do
                break if ( a3.maxindex < 0 )
                stringer=a3.shift( 1 )[ 0 ]
                if ( stringer.length <= 3 and a3.maxindex >= 0 ) then
                    a3[ 0 ] = "#{stringer} #{a3[ 0 ]}"
                    next
                end
                a2.push( stringer )
            end
            stringer=a2.pop( 1 )[ 0 ]
        end
        if ( stringer != "" ) then
           indent_keys.unshift( stringer )
        end
    end
    
    output_record_H[ K.fmtr_record_indent_keys ] = indent_keys
    output_record_H[ K.fmtr_record_values ] = record_values
    output_record_H[ K.level ] = K.file
    output_record_H[ K.fmtr_record_num ] = "#{$.}"
    output_record_H[ K.fmtr_record_original ] = "#{input_record}"
    puts output_record_H.to_json
end
Se.puts "#{Se.lineno}: The output from #{myself_name} SHOULD BE SORTED for the indenter program!"
#p stack_of_recs
