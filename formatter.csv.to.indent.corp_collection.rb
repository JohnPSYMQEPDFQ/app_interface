require 'Date'
require 'json'
require 'pp'
require 'awesome_print'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'class.Find_Dates_in_String.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'

myself_name = File.basename( $0 )

cmdln_option_H = { :max_levels => 5,
                   :r => nil,
                   :find_dates_option_H => { },
                 }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"
    option.on( "-l n", "--max-levels n", OptionParser::DecimalInteger, "Max number of group levels (default 5)" ) do |opt_arg|
        cmdln_option_H[ :max_levels ] = opt_arg
    end
    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        cmdln_option_H[ :r ] = opt_arg
    end
    option.on( "--find_dates_option_H x", "Option Hash passed to the Find_Dates_in_String class." ) do |opt_arg|
        begin
            cmdln_option_H[ :find_dates_option_H ] = eval( opt_arg )
        rescue Exception => msg
            SE.puts ""
            SE.puts msg
            SE.ap "Find_Dates_in_String default options:"
            SE.ap Find_Dates_in_String.new( ).option_H
            exit
        end
    end
    option.on( "-h", "--help" ) do
        SE.puts option
        SE.puts ""
        SE.puts "Find_Dates_in_String default options:".ai
        SE.puts Find_Dates_in_String.new( ).option_H.ai
        SE.puts ""
        SE.puts "Note that:  The --file_dates_option_H numeric values have to be quoted (no integers), eg."
        SE.puts "            #{myself_name} -find_date_option_H '{ :default_century => \"20\" }' file"
        exit
    end
end.parse!  # Bang because ARGV is altered
cmdln_option_H[ :max_levels ] -= 1                   # :max_levels is zero relative.
cmdln_option_H[ :max_levels ] = 1 if ( cmdln_option_H[ :max_levels ] < 1 )

find_dates_O = Find_Dates_in_String.new( {  :morality_replace_option => { :good  => :remove },
                                            :pattern_name_RES => '.',
                                            :date_string_composition => :only_dates,
                                            :yyyy_min_value => '1800'
                                         }.merge( cmdln_option_H[ :find_dates_option_H ] ) )



output_record_H = {}

#   Record ID;Subject Heading;General Heading Note;Title;Number;Date;Geographic Location;-Corporate Name;Personal Name
#   0         1               2                    3     4      5    6                   7               8
ARGF.each_line do |input_record|

    if ( cmdln_option_H[ :r ] and $. > cmdln_option_H[ :r ] ) then 
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

    from_thru_date_A_A = [ ]
    if ( ! ( a1[ 5 ].downcase.in?( [ 'not dated', "" ] ) ) ) then
        find_dates_O.do_find( a1[ 5 ] )
        find_dates_O.good__date_clump_S__A.each do | date_clump_S |
            from_thru_date_A = [ ]
            from_thru_date_A << date_clump_S.from_date
            from_thru_date_A << date_clump_S.thru_date if ( date_clump_S.thru_date != "")
            from_thru_date_A_A << from_thru_date_A
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
    if ( from_thru_date_A_A.maxindex >= 0 ) then
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
    a2.push( from_thru_date_A_A )           # 9

    record_values = [ ]
    got_record=false
    loop do
        break if ( a2.maxindex < 1 )
        column=a2.pop( 1 )[ 0 ]
        got_record = ( got_record or column != "" )         # NOTE:  Column isn't just strings, there's arrays too!
        record_values.unshift( column )
        break if ( got_record and a2.maxindex < cmdln_option_H[ :max_levels ] ) 
    end

    indent_keys = [ ] 
    loop do
        break if ( a2.maxindex < 0 )
        column=a2.pop( 1 )[ 0 ]
        if ( column.match?( /\./ ) ) then
            a3 = column.split( /\./ ).map( &:to_s ).map( &:strip )
            loop do
                break if ( a3.maxindex < 0 )
                column=a3.shift( 1 )[ 0 ]
                if ( column.length <= 3 and a3.maxindex >= 0 ) then
                    a3[ 0 ] = "#{column} #{a3[ 0 ]}"
                    next
                end
                a2.push( column )
            end
            column=a2.pop( 1 )[ 0 ]
        end
        if ( column != "" ) then
           indent_keys.unshift( column )
        end
    end
    
    output_record_H[ K.fmtr_record_indent_keys ] = indent_keys
    output_record_H[ K.fmtr_record_values ]      = record_values
    output_record_H[ K.level ]                   = K.file
    output_record_H[ K.fmtr_record_num ]         = "#{$.}"
    output_record_H[ K.fmtr_record_original ]    = "#{input_record}"
    puts output_record_H.to_json
end
SE.puts "Count of date patterns found:"
SE.puts find_dates_O.pattern_cnt_H.ai
SE.puts ""
SE.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
SE.puts "The output from #{myself_name} SHOULD BE SORTED for the indenter program!"
SE.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#p stack_of_recs
