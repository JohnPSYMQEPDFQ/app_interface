require 'Date'
require 'json'
require 'pp'
require 'awesome_print'
require 'optparse'

require 'class.Hash.extend.rb'
require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'class.Find_Dates_in_String.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'

myself_name = File.basename( $0 )

@cmdln_option_H = { :max_levels => 5,
                    :r => nil,
                    :find_dates_option_H => { },
                    :default_century => '',
                    :inmagic_processing => false,
                    :max_title_size => 150
                 }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"
    option.on( "-l n", "--max-levels n", OptionParser::DecimalInteger, "Max number of group levels (default 5)" ) do |opt_arg|
        @cmdln_option_H[ :max_levels ] = opt_arg
    end
    option.on( "--max-title-size n", OptionParser::DecimalInteger, "Warn if title-size over n" ) do |opt_arg|
        @cmdln_option_H[ :max_title_size ] = opt_arg
    end
    option.on( "--default_century n", OptionParser::DecimalInteger, "Default century for 2-digit years." ) do
        @cmdln_option_H[ :default_century ] = opt_arg
    end  
    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        @cmdln_option_H[ :r ] = opt_arg
    end
    option.on( "--find_dates_option_H x", "Option Hash passed to the Find_Dates_in_String class." ) do |opt_arg|
        begin
            @cmdln_option_H[ :find_dates_option_H ] = eval( opt_arg )
        rescue Exception => msg
            SE.puts ""
            SE.puts msg
            SE.ap "Find_Dates_in_String default options:"
            SE.ap Find_Dates_in_String.new( ).option_H
            exit
        end
    end
    option.on( "--inmagic", "Process InMagic to txt formated file.") do | opt_arg |
        @cmdln_option_H[ :inmagic_processing ] = true
    end
    option.on( "-h", "--help" ) do
        SE.puts option
        SE.puts ""
        SE.puts "Find_Dates_in_String default options:".ai
        SE.puts Find_Dates_in_String.new( ).option_H.ai
        SE.puts ""
        SE.puts "Note that:  The --find_dates_option_H numeric values have to be quoted (no integers), eg."
        SE.puts "            #{myself_name} --find_date_option_H '{ :default_century => \"20\" }' file"
        exit
    end
end.parse!  # Bang because ARGV is altered
@cmdln_option_H[ :max_levels ] -= 1                   # :max_levels is zero relative.
@cmdln_option_H[ :max_levels ] = 1 if ( @cmdln_option_H[ :max_levels ] < 1 )


find_dates_with_4digit_years_O = Find_Dates_in_String.new( { :morality_replace_option => { :good  => :remove },
                                                             :pattern_name_RES => '.',
                                                             :date_string_composition => :dates_in_text,
                                                             :yyyy_min_value => '1800',
                                                           }.merge( @cmdln_option_H[ :find_dates_option_H ] ) )

find_dates_with_2digit_years_O = Find_Dates_in_String.new( { :morality_replace_option => { :good  => :keep },
                                                             :pattern_name_RES => '.',
                                                             :date_string_composition => :dates_in_text,
                                                             :default_century => '1900',
                                                           }.merge( @cmdln_option_H[ :find_dates_option_H ] ) )  \
                                                           if ( @cmdln_option_H[ :default_century ].empty? )
                                                            
min_date = ""
max_date = ""
note_cnt = 0
output_record_H = {}
prepend_A = []
processed_forced_indent_A_STACK = []
@pending_output_record_H = {}

def write_pending_record_H( next_output_record_H, processed_forced_indent_A_STACK )
   
    if ( @pending_output_record_H == {} ) then
        @pending_output_record_H = next_output_record_H.merge( {} )
        return
    end
    output_record_H = @pending_output_record_H
    if ( @cmdln_option_H[ :inmagic_processing ] ) then  
        SE.q {[ 'processed_forced_indent_A_STACK',  ]}   if ( $DEBUG )
        if ( output_record_H.has_no_key?( K.fmtr_record_values ) ) then
            SE.puts "#{SE.lineno}: Couldn't find key 'K.fmtr_indent' in output_record_H"
            SE.q { 'output_record_H' }
            raise
        end
        if ( output_record_H[ K.fmtr_record_values ].nil? ) then
            SE.puts "#{SE.lineno}: 'output_record_H[ K.fmtr_record_values ] == nil' in 'output_record_H'"
            SE.q { 'output_record_H' }
            raise
        end
        if ( output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ].nil? ) then
            SE.puts "#{SE.lineno}: 'output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ] == nil' in 'output_record_H'"
            SE.q { 'output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ]' }
            raise
        end
        if ( output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ].has_no_key?( K.fmtr_indent ) ) then
            SE.puts "#{SE.lineno}: Couldn't find key 'K.fmtr_indent' in 'output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ]'"
            SE.q { 'output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ]' }
            raise
        end
        if ( output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ][ K.fmtr_indent ].nil? ) then
            hierarchy = output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ][ K.hierarchy ] 
            output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ][ K.fmtr_indent ] = 
                                                ( processed_forced_indent_A_STACK.length < hierarchy ) ? K.fmtr_left : nil
            SE.q {[ 'output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__special_processing_idx ]' ]}  if ( $DEBUG )
        end
    end  
    puts output_record_H.to_json
    @pending_output_record_H = next_output_record_H.merge( {} )
end

ARGF.each_line do |input_record|

    if ( @cmdln_option_H[ :r ] and $. > @cmdln_option_H[ :r ] ) then 
        break
    end

    input_record.chomp!
    if ( input_record.match?( /^\s*$/ ) ) then
        next
    end
    if ( input_record.count( '"' ) % 2 != 0 ) then
        SE.puts "#{SE.lineno}: WARNING: Odd number of double-quotes found in '#{input_record}'"
    end
    saved_input_record = input_record + ""      # + "" <<< gotta change it or it's just a reference.
    input_record.gsub!( '...', '…' )   # Period are removed so this gets around that if the periods are at the end of the line.
    input_record.gsub!( 'R.R.', 'Railroad.' )   # Period are removed so this gets around that.
    
#   The prepend/drop records have the following format/pattern:
#       prepend[.:] word(s) (. word(s)[.])*  
#           Each period-delimited-phrase is pushed onto the stack and then inserted in front of the following records
#
#       drop[.:] (word(s) (. word(s)[.])*)*
#           If more than one phrase, they've got to be the last phrases in the stack in the SAME order.
#           If there is no phrase on the drop record, the last entry in the stack is popped off.
#
#   The K.fmtr_indent records have the following format:
#       K.fmtr_indent K.fmtr_right|K.fmtr_left
    
    a1 = input_record.split( /^\s*(#{K.fmtr_indent}|prepend|drop)[\.:]?\s*/i ).map( &:to_s ).map( &:strip )
    if ( a1.maxindex > 0 ) then
        a1.shift                     # a1[0] == "" for the prepend & drop records
        if ( a1.maxindex > 1 ) then
            SE.puts "#{SE.lineno}: Got an odd '#{K.fmtr_indent}', 'prepend', or 'drop' record:"
            SE.q { ['input_record'] }
            SE.q {[ 'a1' ]}
            raise
        end
        command = a1.shift.downcase    # shift-off the indent, prepend, or drop "command". 
        case command
        when K.fmtr_indent.downcase
        SE.puts "======================================================================="
            if ( a1.length > 1 ) then
                SE.puts "#{SE.lineno}: Got a '#{K.fmtr_indent}' record with extra words."
                SE.q { 'input_record' }
                raise
            end
            case a1[ 0 ] 
            when K.fmtr_right
                processed_forced_indent_A_STACK.push( :pending )     #  false = INDENT_RIGHT hasn't been done yet.
            when K.fmtr_left
                processed_forced_indent_A_STACK.pop
            else
                SE.puts "#{SE.lineno}: Got a '#{K.fmtr_indent}' record an invalid direction '#{a1[ 0 ]}'."
                SE.q { 'input_record' }
                raise    
            end
            SE.q {[ 'processed_forced_indent_A_STACK' ]}  if ( $DEBUG )
            next
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

    special_processing_H = {}
    if ( @cmdln_option_H[ :inmagic_processing ] ) then     
        SE.q {[ 'processed_forced_indent_A_STACK',  ]}   if ( $DEBUG )
        if ( processed_forced_indent_A_STACK and processed_forced_indent_A_STACK[ -1 ] == :pending ) then
            special_processing_H[ K.fmtr_indent ] = K.fmtr_right 
            processed_forced_indent_A_STACK[ -1 ] = :done
        else
            special_processing_H[ K.fmtr_indent ] = nil
        end
        special_processing_H[ K.hierarchy ] = processed_forced_indent_A_STACK.length
        
        SE.q {[ 'special_processing_H' ]}  if ( $DEBUG )
        regexp = %r{#{K.fmtr_inmagic_quote}(#{K.series}|#{K.subseries})\s+([0-9]+)#{K.fmtr_inmagic_quote}}i
        if ( matchdata = input_record.match( regexp ) ) then
            input_record.sub!( regexp, '' )
            special_processing_H[ K.level ] = [ matchdata[ 1 ], matchdata[ 2 ] ]
        end
        regexp = %r{#{K.fmtr_inmagic_quote}(.+?)#{K.fmtr_inmagic_quote}}    # (.+?) The '?' is 'non-greedy 
        while true
            break if ( ! input_record.sub!( regexp, '\1' ) )
        end
        
    end

    note_A = [ ]
    a1 = input_record.split( /\s+(note:|notes:)\s*/i ).map( &:to_s ).map( &:strip )
    if ( a1.maxindex > 0) then
        input_record = a1.shift( 1 )[ 0 ]   # input_record with the NOTES removed.
        a1.each do | note |
            next if ( note =~ /\A(note:|notes:)\Z/i ) 
            next if ( note =~ /\A\s*\Z/i ) 
            note_cnt += 1
            note_A << note.gsub( /\s+/, ' ')
        end
    end

    container_H = K.fmtr_empty_container_H
    if ( input_record.match( /box.*folder.*box.*folder/i ) ) then
        SE.p "#{SE.lineno}: input_record has multiple repeats of box and folder!"
        SE.q {[ 'input_record' ]}
        raise "Aborting"
    end
    regexp = K.box_and_folder_RE
    if (match_vars = input_record.match( regexp )) then
        input_record.sub!( regexp, "")
        container_H[ K.fmtr_tc_type ] =  K.box
        container_H[ K.fmtr_tc_indicator ] =  match_vars[:box_num]
        container_H[ K.fmtr_sc_type ] =  K.folder
        container_H[ K.fmtr_sc_indicator ] =  match_vars[:folder_num]
#       SE.q {[ 'container_H' ]}
    end
    if ( input_record.match( /((\A|\s*)box(:\s*|\s+)|\s+folder(:\s*|\s+))/i )) then
        SE.p "#{SE.lineno}:WARNING: Found some 'box' and 'folder' words '#{input_record}'"
    end
     
    from_thru_date_A_A = [ ]
    input_record = find_dates_with_4digit_years_O.do_find( input_record )
    find_dates_with_4digit_years_O.good__date_clump_S__A.each do | date_clump_S |
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
    if ( @cmdln_option_H[ :default_century ].empty? ) then
        find_dates_with_2digit_years_O.do_find( input_record )
        find_dates_with_2digit_years_O.good__date_clump_S__A.each do | date_clump_S |  
            len = @find_dates_with_2digit_years_O.good__date_clump_S__A.length
            from_thru_date= date_clump_S.from_date
            if ( date_clump_S.thru_date != "") then
                from_thru_date += ' - ' + date_clump_S.thru_date 
            end
            SE.puts "#{SE.lineno}: WARNING: #{len} date(s) with 2-digit-years(#{from_thru_date}) found in record:'#{input_record}'"
            break
        end
    end

    a1 = prepend_A +
         input_record.split( '.' ).map( &:to_s ).
                      map{ | e | e.gsub( /\s*,\s*$/, '') }.  # Multiple dates leave extra commas.
                      map{ | e | e.gsub( /\s*,\s*,/, '') }.
                      map{ | e | e.sub( /./,&:upcase )}.
                      map{ | e | e.gsub( /\s+/, ' ') }.
                      map( &:strip ).reject( &:empty? )
    if ( a1.maxdepth > 1 ) then
        SE.puts "#{SE.lineno}: a1 has a maxdepth > 1"
        SE.q {[ 'a1', 'prepend_A' ]}
        raise "Aborting"
    end
#       What's left of the input record (now in a1) is used as the sort keys at the front
#       of the record (and the dates) so the 'sort' command doesn't get confused!   
    output_record_H[ K.fmtr_record_sort_keys ] = a1.join( ' ' ).downcase.gsub( /[^[a-z0-9 ]]/,'' ) + ' ' + from_thru_date_A_A.sort.join( ' ' )

    a2 = [ ]
    loop do
        break if ( a1.maxindex < 1 )
        break if ( a1.maxindex < @cmdln_option_H[ :max_levels ] ) 
        dot_delimited_phrase = a1.pop( 1 )[ 0 ]   # pop with an argument returns an array, [0] says return the 1st element
        a2.unshift( dot_delimited_phrase )
    end
    
    record_values_A = [ ]   
    record_values_A[ K.fmtr_record_values__text_idx ] = a2.join( '. ' )
    record_values_A[ K.fmtr_record_values__dates_idx ] = from_thru_date_A_A     
    record_values_A[ K.fmtr_record_values__notes_idx ] = note_A                 
    record_values_A[ K.fmtr_record_values__container_idx ] = ( container_H != K.fmtr_empty_container_H ) ? container_H : {}
    record_values_A[ K.fmtr_record_values__special_processing_idx ] = special_processing_H
    
    indent_keys_A = [ ] 
    loop do
        break if ( a1.maxindex < 0 )
        dot_delimited_phrase = a1.pop( 1 )[ 0 ]
        indent_keys_A.unshift( dot_delimited_phrase )
    end
    
    output_record_H[ K.fmtr_record_indent_keys ] = indent_keys_A
    output_record_H[ K.fmtr_record_values ]      = record_values_A
#   output_record_H[ K.level ]                   = K.file
    output_record_H[ K.fmtr_record_num ]         = "#{$.}"
    output_record_H[ K.fmtr_record_original ]    = saved_input_record

    write_pending_record_H( output_record_H, processed_forced_indent_A_STACK )
    
    title = output_record_H[ K.fmtr_record_indent_keys ].join('. ') + record_values_A[ K.fmtr_record_values__text_idx ]
    if ( title.length > @cmdln_option_H[ :max_title_size ] ) then
        SE.puts "#{SE.lineno}: Warning: Title size #{title.length} '#{title}'"
        SE.puts ""
    end
end
write_pending_record_H( {}, processed_forced_indent_A_STACK )

SE.puts "Minimum date:  '#{min_date}'"
SE.puts "Maxmimum date: '#{max_date}'"
SE.puts "Notes created: '#{note_cnt}'"
SE.puts "Count of date patterns found:"
SE.puts find_dates_with_4digit_years_O.pattern_cnt_H.ai
SE.puts ""

if ( prepend_A.length > 0 ) then
    SE.puts ""
    SE.puts "#{SE.lineno}: ERROR!"
    SE.puts "#{SE.lineno}: ERROR! prepend_A not empty.  Missing drop record."
    SE.q { 'prepend_A' }
    SE.puts ""
    raise
end
#p stack_of_recs
