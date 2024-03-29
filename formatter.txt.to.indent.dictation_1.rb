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
prepend_A = []

ARGF.each_line do |input_record|

    if ( cmdln_option_H[ :r ] and $. > cmdln_option_H[ :r ] ) then 
        break
    end

    input_record.chomp!
    if ( input_record.match?( /^\s*$/ ) ) then
        next
    end
    saved_input_record = input_record + ""      # + "" <<< gotta change it or it's just a reference.
    input_record.gsub!( '...', '…' )   # Trailing period are removed so this gets around that if the periods are at the end of the line.
    
    
#   The prepend/drop records have the following format/pattern:
#       prepend[.:] word(s) (. word(s)[.])*  
#           Each period-delimited-phrase is pushed onto the stack and then inserted in front of the following records
#
#       drop[.:] (word(s) (. word(s)[.])*)*
#           If more than one phrase, they've got to be the last phrases in the stack in the SAME order.
#           If there is no phrase on the drop record, the last entry in the stack is popped off.
#
    
    a1 = input_record.split( /^\s*(prepend|drop)[\.:]?\s*/i ).map( &:to_s ).map( &:strip )
    if ( a1.maxindex > 0 ) then
        a1.shift                     # a1[0] == "" for the prepend & drop records
        if ( a1.maxindex > 1 ) then
            SE.puts "#{SE.lineno}: Got an odd 'prepend' or 'drop' record:"
            SE.q { 'input_record' }
            raise
        end
        case a1.shift.downcase      # shift-off the prepend or drop "command".   
        when 'prepend' 
            if ( a1.length == 0 ) then
                SE.puts "#{SE.lineno}: Got a 'prepend' record without a phrase:"
                SE.q { 'input_record' }
                raise
            end
            a2 = a1.first.split( '.' ).map( &:to_s ).map( &:strip ).
                                       map{ | e | e.sub( /./,&:upcase )}.
                                       map{ | e | e.gsub( /\s+/, ' ') }
            prepend_A += a2
            next
        when 'drop'
            if ( a1.length == 0 ) then
                if ( prepend_A.length > 0 ) then
                    prepend_A.pop
                    next
                end
                SE.puts "#{SE.lineno}: Got a blank 'drop' record but there are no entries in prepend_A."
                SE.q { 'input_record' }
                raise
            end
            a2 = a1.first.split( '.' ).map( &:to_s ).map( &:strip ).
                                       map{ | e | e.sub( /./,&:upcase )}.
                                       map{ | e | e.gsub( /\s+/, ' ') }
            if ( a2.length > prepend_A.length ) then
                SE.puts "#{SE.lineno}: Got a 'drop' record with #{a2.length} period-delmited-phrase(s), but"
                SE.puts "#{SE.lineno}: prepend_A only has #{prepend_A.length} period-delmited-phrase(s)."
                SE.q { 'input_record' }
                SE.q { 'a2' }
                SE.q { 'prepend_A' }
                SE.puts "NOTE TO FUTURE SELF: If I took the time to type period-delmited-phrase(s) it's because the periods matter."
                raise
            end
            prepend_idx = prepend_A.maxindex
            a2.maxindex.downto( 0 ).each do | a2_idx |
                # SE.q "print a string", [ "or an", "array"], "on a separate line"
                # SE.q { ['prepend_idx', 'a2_idx'] } # Print both variables on one line
                if ( prepend_A[ prepend_idx ].downcase != a2[ a2_idx ].downcase ) then
                    SE.puts "#{SE.lineno}: Got a 'drop' record with #{a2.length} period-delmited-phrase(s), but"
                    SE.puts "#{SE.lineno}: no matching - in order - period-delmited-phrase(s) in prepend_A."
                    SE.q { 'input_record' }
                    SE.q { 'a2' }
                    SE.q { 'prepend_A' }
                    SE.puts "NOTE TO FUTURE SELF: If I took the time to type period-delmited-phrase(s) it's because the periods matter."
                    raise
                end   
                prepend_idx -= 1
            end   
            prepend_A.pop( a2.length )
            next
        end
    end

    note_A = [ ]
    a1 = input_record.split( /\s+(note|notes):\s*/i ).map( &:to_s ).map( &:strip )
    if ( a1.maxindex > 0) then
        input_record = a1.shift( 1 )[ 0 ]   # input_record with the NOTES removed.
        a1.each do | note |
            next if ( note =~ /(note|notes)/i ) 
            note_cnt += 1
            note_A << note.gsub( /\s+/, ' ')
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

    a1 = prepend_A + input_record.split( '.' ).map( &:to_s ).
                                               map{ | e | e.gsub( /\s*,\s*$/, '') }.  # Multiple dates leave extra commas.
                                               map{ | e | e.gsub( /\s*,\s*,/, '') }.
                                               map{ | e | e.sub( /./,&:upcase )}.
                                               map{ | e | e.gsub( /\s+/, ' ') }.
                                               map( &:strip ).reject(&:empty?)

#       What's left of the input record (now in a1) is used as the sort keys at the front
#       of the record (and the dates) so the 'sort' command doesn't get confused!   
    output_record_H[ K.fmtr_record_sort_keys ] = a1.join( " " ) + " " + from_thru_date_A_A.sort.join( " " )

    a2 = [ ]
    loop do
        break if ( a1.maxindex < 1 )
        break if ( a1.maxindex < cmdln_option_H[ :max_levels ] ) 
        dot_delimited_phrase = a1.pop( 1 )[ 0 ]   # pop with an argument returns an array, [0] says return the 1st element
        a2.unshift( dot_delimited_phrase )
    end
    
    record_values_A = [ ]   
    record_values_A[ K.fmtr_record_values__text_idx ] = a2.join('. ')
    record_values_A[ K.fmtr_record_values__dates_idx ] = from_thru_date_A_A 
    record_values_A[ K.fmtr_record_values__notes_idx ] = note_A
    
    indent_keys_A = [ ] 
    loop do
        break if ( a1.maxindex < 0 )
        dot_delimited_phrase = a1.pop( 1 )[ 0 ]
        indent_keys_A.unshift( dot_delimited_phrase )
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
if ( prepend_A.length > 0 ) then
    SE.puts ""
    SE.puts "ERROR!"
    SE.puts "ERROR! prepend_A not empty.  Missing drop record."
    SE.q { 'prepend_A' }
    SE.puts ""
    raise
end
#p stack_of_recs
