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
                                            :date_string_composition => :dates_in_text,
                                            :yyyy_min_value => '1800'
                                         }.merge( cmdln_option_H[ :find_dates_option_H ] ) )


min_date = ""
max_date = ""
note_cnt = 0
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
  
    saved_input_record = input_record + ""      # + "" <<< gotta change it or it's just a reference.
    
    note_A = [ ]
    a1 = input_record.split( /\s+(NOTE|note|NOTES|notes):\s*/ ).map( &:to_s ).map( &:strip )
    if ( a1.maxindex > 0) then
        note_cnt += 1
        input_record = a1.shift( 1 )[ 0 ]   # input_record with the NOTE removed.
        a1.shift( 1 )   # When using () in the pattern, what's between the () is returned too.
        a1.each do | note |
            note_A << note
        end
    end
     
    from_thru_date_A_A = [ ]
    input_record = find_dates_O.do_find( input_record )
    find_dates_O.good__date_clump_S__A.each do | date_clump_S |
        from_thru_date_A = [ ]
        from_thru_date_A << date_clump_S.from_date
        if ( min_date == "" or min_date > date_clump_S.from_date ) then
            min_date = date_clump_S.from_date
        end
        if ( max_date == "" or max_date < date_clump_S.from_date ) then
            max_date = date_clump_S.from_date
        end
        if ( date_clump_S.thru_date != "") then
            from_thru_date_A << date_clump_S.thru_date 
            if ( min_date == "" or min_date > date_clump_S.thru_date ) then
                min_date = date_clump_S.thru_date
            end
            if ( max_date == "" or max_date < date_clump_S.thru_date ) then
                max_date = date_clump_S.thru_date
            end
        end
        from_thru_date_A_A << from_thru_date_A
    end

    a1 = input_record.split( '.' ).map( &:to_s ).map( &:strip ).map{ | e | e.gsub(/^,$/, '') }.reject(&:empty?).map{ | e | e.sub( /./,&:upcase )}

#       What's left of the input record (now in a1) is used as the sort keys at the front
#       of the record (and the dates) so the 'sort' command doesn't get confused!   
    output_record_H[ K.fmtr_record_sort_keys ] = a1.join( " " ) + " " + from_thru_date_A_A.join( " " )

    a2 = [ ]
    loop do
        break if ( a1.maxindex < 1 )
        dot_delimited_word = a1.pop( 1 )[ 0 ]   # pop returns an array, [0] says return the 1st element
        a2.unshift( dot_delimited_word )
        break if ( a1.maxindex < cmdln_option_H[ :max_levels ] ) 
    end
    
    record_values_A = [ ]   
    record_values_A[ K.fmtr_record_values__text_idx ] = a2.join(' ')
    record_values_A[ K.fmtr_record_values__dates_idx ] = from_thru_date_A_A 
    record_values_A[ K.fmtr_record_values__notes_idx ] = note_A
    
    indent_keys_A = [ ] 
    loop do
        break if ( a1.maxindex < 0 )
        dot_delimited_word = a1.pop( 1 )[ 0 ]
        indent_keys_A.unshift( dot_delimited_word )
    end
    
    output_record_H[ K.fmtr_record_indent_keys ] = indent_keys_A
    output_record_H[ K.fmtr_record_values ]      = record_values_A
    output_record_H[ K.level ]                   = K.file
    output_record_H[ K.fmtr_record_num ]         = "#{$.}"
    output_record_H[ K.fmtr_record_original ]    = saved_input_record
    puts output_record_H.to_json
end
SE.puts "Minimum date:  '#{min_date}'"
SE.puts "Maxmimum date: '#{max_date}'"
SE.puts "Notes created: '#{note_cnt}'"
SE.puts "Count of date patterns found:"
SE.puts find_dates_O.pattern_cnt_H.ai
SE.puts ""
SE.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
SE.puts "The output from '#{myself_name}' SHOULD BE SORTED (sort -f) for the indenter program!"
SE.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#p stack_of_recs