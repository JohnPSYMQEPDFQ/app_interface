require 'json'
require 'optparse'

require 'class.Hash.extend.rb'
require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'class.Find_Dates_in_String.rb'
require 'tempfile'

=begin 
      For the InMagic to ArchivesSpace Resource Record conversion the following inforation is known
      as-of 10/14/2024

          InMagic Column            -> ArchivesSpace equivalent

          Historical Information    -> Biography/Historical  (Not just Biography)
          Series Summary            -> Arrangement
          Additional Access         ->
          Provenance                -> Immediate Source of Acquisition
          Sco                       -> Scope and Content
          Extent                    -> Series Date (but the box nos. will have to be removed)

=end



myself_name = File.basename( $0 )

def column_use_H_F
    if ( @cmdln_option_H.has_no_key?( :column_use_H ) ) then
        SE.puts "Can find '@cmdln_option_H[ :column_use_H ]"
        SE.q {[ @cmdln_option_H ]} 
        raise
    end
    return @cmdln_option_H[ :column_use_H ]
end
def column_name_exists?( column_name )
    return column_use_H_F.has_key?( column_name)
end
def series_column_name_F()
    column_use_H_F.each_pair do | c, v | 
        if ( v == K.fmtr_inmagic_series ) then
            return c
        end
    end
    SE.puts "#{SE.lineno}: Can't find the series column_name in 'column_use_H_F'"
    SE.q {[ 'column_use_H_F' ]}
    raise
end
def series_pos_F( on_nil = :fail )
    pos = column_pos_by_use_F( K.fmtr_inmagic_series, on_nil )
    return pos
end
def seriesdate_pos_F( on_nil = :fail)
    pos = column_pos_by_use_F( K.fmtr_inmagic_seriesdate, on_nil )
    return pos
end
def seriesnote_pos_F( on_nil = :fail )
    pos = column_pos_by_use_F( K.fmtr_inmagic_seriesnote, on_nil )
    return pos
end
def column_pos_by_use_F( use, on_nil = :fail )
    pos = column_use_H_F.keys.index( use )
    if ( on_nil == :fail and pos.nil? ) then
        SE.puts "#{SE.lineno}: Can't find the '#{use}' column in 'column_use_H_F'"
        SE.q {[ 'column_use_H_F' ]}
        raise
    end  
    return pos if ( on_nil == :nil_ok )
    SE.puts "#{SE.lineno}: Invalid value of 'on_nil' parameter, expected :fail or :nil_ok, got '#{on_nil}'"
    raise
end
def use_for_output?( column_name )
    column_use = column_use_H_F[ column_name ]
    use = @valid_column_uses_H[ column_use ][ :use_for_output ]
    if ( use.nil? ) then
        SE.puts "@valid_column_uses_H[ column_use_H_F[ column_name ] ][ :use_for_output ] returns nil"
        SE.q {[ 'column_name', 'column_use_H_F' ]}
        SE.q {[ '@valid_column_uses_H' ]}
        raise
    end
    return use
end
def split_on_bars?( column_name )
    column_use = column_use_H_F[ column_name ]
    use = @valid_column_uses_H[ column_use ][ :split_on_bars ]
    if ( use.nil? ) then
        SE.puts "@valid_column_uses_H[ column_use_H_F[ column_name ] ][ :split_on_bars ] returns nil"
        SE.q {[ 'column_name', 'column_use_H_F' ]}
        SE.q {[ '@valid_column_uses_H' ]}
        raise
    end
    return use
end

@valid_column_uses_H = { K.fmtr_inmagic_detail       => { :use_for_output => true , :split_on_bars => true,  } ,
                         K.fmtr_inmagic_series       => { :use_for_output => true , :split_on_bars => false, } ,
                         K.fmtr_inmagic_seriesdate   => { :use_for_output => false, :split_on_bars => false, } ,
                         K.fmtr_inmagic_seriesnote   => { :use_for_output => false, :split_on_bars => true, } ,
                       }

@cmdln_option_H = { :r => 999999999,
                 :d => false,
                 :sort => false,
                 :default_century => '',
                 :max_title_size => 150,
                 :column_use_H => {},
               }

OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"

    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        @cmdln_option_H[ :r ] = opt_arg
    end
    
    option.on( "--sort", "Sort the detail records." ) do
        @cmdln_option_H[ :sort ] = true
    end  

    option.on( "--default_century n", OptionParser::DecimalInteger, "Default century for 2-digit years." ) do
        @cmdln_option_H[ :default_century ] = opt_arg
    end  
    
    option.on( "--columns=NAME[:use][,NAME:use]...", "Order and use of the columns") do |opt_arg|
        a1 = opt_arg.split( ',' ).map( &:to_s ).map( &:strip )
        a1.each do | stringer |
            a2 = stringer.split( ':' ).map( &:to_s ).map( &:strip )
            if ( a2.maxindex > 1 ) then
                SE.puts "--columns option has wrong formatting, there should only be a max of two pieces not #{a2.length}"
                SE.q {[ 'a2', 'a1' ]}
                raise
            end
            if ( column_use_H_F.has_key?( a2[ 0 ] ) ) then
                SE.puts "Duplicate column_name '#{a2[ 0 ] }' found in --columns option"
                SE.q {[ 'opt_arg', 'a1', 'column_use_H_F' ]}
                raise
            end
            if ( a2[ 1 ] ) then
                if ( @valid_column_uses_H.has_no_key?( a2[ 1 ] ) ) then
                    SE.puts "#{SE.lineno}: Unknown column use '#{a2[ 1 ]}' on column '#{a2[ 0 ]}'"
                    SE.q {[ '@cmdln_option_H' ]}
                    raise
                end
                if ( a2[ 1 ].in?( @valid_column_uses_H.values ) ) then
                    SE.puts "#{SE.lineno}: column use '#{a2[ 1 ]}' on column '#{a2[ 0 ]}' already exists."
                    SE.q {[ '@cmdln_option_H' ]}
                    raise
                end
                @cmdln_option_H[ :column_use_H ][ a2[ 0 ] ] = a2[ 1 ].downcase
            else
                @cmdln_option_H[ :column_use_H ][ a2[ 0 ] ] = K.fmtr_inmagic_detail
            end
        end
    end
    
    option.on( "--max-title-size n", OptionParser::DecimalInteger, "Warn if title-size over n" ) do |opt_arg|
        @cmdln_option_H[ :max_title_size ] = opt_arg
    end

    option.on( "-d", "Turn on $DEBUG switch" ) do
        $DEBUG = true
    end

    option.on( "-h", "--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
SE.q {[ '@cmdln_option_H' ]}

@find_dates_with_4digit_years_O = Find_Dates_in_String.new( { :morality_replace_option => { :good  => :remove },
                                                              :pattern_name_RES => '.',
                                                              :date_string_composition => :dates_in_text,
                                                              :yyyy_min_value => '1800',
                                                            } )

@find_dates_with_2digit_years_O = Find_Dates_in_String.new( { :morality_replace_option => { :good  => :keep },
                                                              :pattern_name_RES => '.',
                                                              :date_string_composition => :dates_in_text,
                                                              :default_century => '1900',
                                                            } ) if ( @cmdln_option_H[ :default_century ].empty? )

def rearrange( sub_column_value )
    rearranged = sub_column_value + ''
    inmagic_quote_storage_A = []
    if ( rearranged.sub!( K.box_and_folder_RE, '') ) then
        inmagic_quote_storage_A.push( $& )
    end   
    if ( rearranged.match( /((\A|\s*)box(:\s*|\s+)|\s+folder(:\s*|\s+))/i ) ) then
        SE.p "#{SE.lineno}: WARNING: Undiscovered box and folder literals in sub_column '#{sub_column_value}'"
    end
    
    regexp = %r{#{K.fmtr_inmagic_quote}.+?#{K.fmtr_inmagic_quote}}    # .+? The '?' makes it 'non-greedy
    while true
        break if ( ! rearranged.sub!( regexp, '' ) )
        inmagic_quote_storage_A.push( $& )
    end
    from_thru_date_A= []
    rearranged = @find_dates_with_4digit_years_O.do_find( rearranged )
    @find_dates_with_4digit_years_O.good__date_clump_S__A.each do | date_clump_S |
        from_thru_date= date_clump_S.from_date
        if ( date_clump_S.thru_date != "") then
            from_thru_date += ' - ' + date_clump_S.thru_date 
        end
        from_thru_date_A << from_thru_date
    end
    if ( @cmdln_option_H[ :default_century ].empty? ) then
        @find_dates_with_2digit_years_O.do_find( rearranged )
        @find_dates_with_2digit_years_O.good__date_clump_S__A.each do | date_clump_S |  
            len = @find_dates_with_2digit_years_O.good__date_clump_S__A.length
            from_thru_date= date_clump_S.from_date
            if ( date_clump_S.thru_date != "") then
                from_thru_date += ' - ' + date_clump_S.thru_date 
            end
            SE.puts "#{SE.lineno}: WARNING: #{len} date(s) with 2-digit-years(#{from_thru_date}) found in record:'#{sub_column_value}'"
            break
        end
    end
    
    rearranged += " #{from_thru_date_A.sort.join( ',' )} #{inmagic_quote_storage_A.join( ' ' )}"
    rearranged.gsub!( /  /, ' ' )
    rearranged.strip!
end

def put_column( column_H_A, column_idx = 0, title_length = 0 )
    SE.q { [ 'column_H_A[ column_idx]' ]}  if ( $DEBUG )  
    column_H     = column_H_A[ column_idx ]
    column_name  = column_H[ 'column_name' ]
    column_value = column_H[ 'column_value' ]
    SE.q { [ 'column_idx', 'column_name', 'column_value', 'column_H' ]} if ( $DEBUG ) 
    
    if ( matchdata = column_value.match( /^"(.*)"$/ ) ) then
        column_value = matchdata[ 1 ]
    end

    if ( split_on_bars?( column_name )) then
        sub_column_value_A = column_value.split( '|' ).map( &:to_s ).map( &:strip )         
        sub_column_value_A = sub_column_value_A.each.map { | sub_column_value | rearrange( sub_column_value) } 
        sub_column_value_A = sub_column_value_A.sort_by { | k | k.downcase.strip.gsub(/[^[a-z0-9 ]]/,'') } if ( @cmdln_option_H[ :sort ] )
    else
        if ( column_value.include?( '|' )) then
            SE.puts "#{SE.lineno}: non-bar column has a '|'"
            SE.q {[ 'column_idx', 'column_H_A' ]}
            raise
        end
        sub_column_value_A = [ column_value ]
    end

    SE.q { 'sub_column_value_A' } if ( $DEBUG )
    sub_column_value_A.each do | sub_column_value |
        sub_column_without_inmagic_quoted_stuff = sub_column_value + ''
        sub_column_without_inmagic_quoted_stuff.gsub!( /\s+#{K.fmtr_inmagic_quote}.*?#{K.fmtr_inmagic_quote}/, '' )  # .+? The '?' makes it 'non-greedy
        if ( column_idx < column_H_A.maxindex ) then
            puts sub_column_value 
            @output_record_cnt += 1
            puts "#{K.fmtr_indent}: #{K.fmtr_right}" 
            @output_record_cnt += 1
            put_column( column_H_A, column_idx + 1, title_length + sub_column_without_inmagic_quoted_stuff.length )
            puts "#{K.fmtr_indent}: #{K.fmtr_left}"
            @output_record_cnt += 1
        else
            puts sub_column_value
            @output_record_cnt += 1
            if ( sub_column_value.count( '"' ) % 2 != 0 ) then
                SE.puts ""
                SE.puts "WARNING: Odd number of double-quotes found at #{@output_record_cnt}:'#{sub_column_value}'"
            end
            if ( ( sub_column_value.count( ')' ) + sub_column_value.count( '(' ) ) % 2 != 0 ) then
                SE.puts ""
                SE.puts "WARNING: Odd number of parentheses found at #{@output_record_cnt}:'#{sub_column_value}'"
            end
            if ( ( sub_column_value.count( ']' ) + sub_column_value.count( '[' ) ) % 2 != 0 ) then
                SE.puts ""
                SE.puts "WARNING: Odd number of square-brackets found at #{@output_record_cnt}:'#{sub_column_value}'"
            end
            if ( ( title_length + sub_column_without_inmagic_quoted_stuff.length ) > @cmdln_option_H[ :max_title_size ] ) then
                SE.puts ""
                SE.puts "WARNING: Max title size is greater than #{@cmdln_option_H[ :max_title_size ]} at #{@output_record_cnt}:'#{sub_column_value}'"
            end
        end
    end
end

tmp1_F = Tempfile.new( "#{myself_name}.tmp1_F." )
#SE.puts "#{SE.lineno}: tmp1_F.path=#{tmp1_F.path}"

ARGF.each do | csv_from_pwsh_as_one_big_A_J |
    csv_from_pwsh_as_one_big_A_J.chomp
    csv_from_pwsh_as_one_big_A = JSON.parse( csv_from_pwsh_as_one_big_A_J )
    csv_from_pwsh_as_one_big_A.each do | input_column_H |
        tmp1_F.puts input_column_H.to_json
    end
end
tmp1_F.close

tmp1_F.open
tmp2_F = Tempfile.new( "#{myself_name}.tmp2_F." )
column_has_data_H = {}
original_file_header_A = []
tmp1_F.each_line do | input_column_J |
    if ( $. > @cmdln_option_H[ :r ] ) then 
        SE.puts ""
        SE.puts "#{SE.lineno}: Stopped after #{@cmdln_option_H[ :r ]} records."
        SE.puts ""
        break
    end
    input_column_H = JSON.parse( input_column_J )
    output_column_H = {}
    SE.puts "#{SE.lineno}: #{input_column_H}"  if ( $DEBUG )
    
    if ( $. == 1 ) then
        original_file_header_A = input_column_H.keys
        if ( original_file_header_A.detect{ | e | original_file_header_A.count( e ) > 1 } ) then
            SE.puts "#{SE.lineno}: Found dup column header name."
            SE.q {[ 'original_file_header_A' ]} 
            raise
        end
    end
    if ( input_column_H.keys - original_file_header_A != [] ) then
        SE.puts "#{SE.lineno}: Hash keys different."
        SE.q {[ 'input_column_H.keys', 'original_file_header_A' ]}
        raise
    end
   
    original_file_header_A.each do | column_header |
        column_value = input_column_H[ column_header ]
        next if ( column_value.nil? ) 
        column_value.gsub!(/[^[:print:]]/,' ')
        column_value.gsub!( '""', '"' )
        column_value.strip!
        output_column_H[ column_header ] = column_value
       
        if ( column_value > "" and column_has_data_H.has_no_key?( column_header ) ) then
            stringer = (column_value.include?( '|' ) ) ? '*|*' : '   '
            column_has_data_H[ column_header ] = "#{stringer} Line=#{$.} '#{column_header}' #{column_value}"
        end
    end
    tmp2_F.puts output_column_H.to_json
end
tmp1_F.close( true )
tmp2_F.close

tmp2_F.open
tmp3_F = Tempfile.new( "#{myself_name}.tmp3_F." )

SE.q {['column_has_data_H']}
used_column_header_A = []
tmp2_F.each_line do | input_column_J |    # Select the columns wanted based on the --columns option
    input_column_J.chomp!
    input_column_H = JSON.parse( input_column_J )
    output_column_H={}
    
    input_column_H.keys.each do | column_name |
        if ( column_has_data_H[ column_name ].nil? ) then
            next
        end
        output_column_H[ column_name] = input_column_H[ column_name ]  
    end

    if ( $. == 1 ) then
        used_column_header_A = output_column_H.keys
        if (@cmdln_option_H[ :column_use_H ] == {} ) then
            used_column_header_A.each do | column_name | 
                @cmdln_option_H[ :column_use_H ][ column_name ] = "" 
            end
        else
            a1 = column_use_H_F.keys - used_column_header_A           
            if ( a1 != [] ) then
                SE.puts ""
                SE.puts ""
                SE.puts "#{SE.lineno}: Unknown column '#{a1.join(', ')}' in --columns option"
                SE.puts ""
                SE.q {[ '@cmdln_option_H[ :column_order_A ]', 'used_column_header_A' ]}
                raise
            end
            a1 = used_column_header_A - column_use_H_F.keys
            if ( a1 != [] ) then
                SE.puts "The following columns are being skipped:"
                SE.puts "#{a1.join(', ')}"
            end
            used_column_header_A = column_use_H_F.keys
        end
        SE.puts ""
        SE.puts "CSV column headers      : #{original_file_header_A.join( ', ')}"
        SE.puts "Input columns being used: #{used_column_header_A.join( ', ' )}"
        if ( column_use_H_F.values.all?( &:empty? ) ) then
            SE.puts ""
            SE.puts ""
            SE.puts ""
            SE.puts "Provide the --columns option to get past this point."
            SE.puts ""
            exit
        end
#       SE.puts "#{SE.lineno}:   in the following order: #{column_use_H_F.keys.join( ', ' )}"
        SE.puts "#{SE.lineno}:    for the following use: #{column_use_H_F.values.join( ', ' )}"
        if ( column_use_H_F.keys.uniq.size == 1 ) then
            SE.puts ""
            SE.puts ""
            SE.puts ""
            SE.puts "#{SE.lineno}: All the column uses are the same!"
            SE.puts ""
            exit
        end
        
        if ( seriesnote_pos_F( :nil_ok ) and seriesnote_pos_F < series_pos_F ) then
            SE.puts "#{SE.lineno}: The '#{K.fmtr_inmagic_seriesnote}' column must be after the '#{K.fmtr_inmagic_series}' column"
            SE.q {[ 'seriesnote_pos_F', 'series_pos_F', 'column_use_H_F ' ]}
            raise
        end
        if ( seriesdate_pos_F( :nil_ok ) and seriesdate_pos_F < series_pos_F ) then
            SE.puts "#{SE.lineno}: The '#{K.fmtr_inmagic_seriesdate}' column must be after the '#{K.fmtr_inmagic_series}' column."
            SE.q {[ 'seriesdate_pos_F', 'series_pos_F', 'column_use_H_F ' ]}
            raise
        end
        if ( seriesdate_pos_F( :nil_ok ) and seriesnote_pos_F( :nil_ok ) and seriesdate_pos_F > seriesnote_pos_F ) then
            SE.puts "#{SE.lineno}: The '#{K.fmtr_inmagic_seriesdate}' column must be before the '#{K.fmtr_inmagic_seriesnote}' column,"
            SE.puts "#{SE.lineno}: this is so the dates get put in-front-of the note."
            SE.q {[ 'seriesdate_pos_F', 'seriesnote_pos_F', 'column_use_H_F ' ]}
            raise
        end
        SE.puts ""   
    end
    
    a1 = output_column_H.keys.select{ | k | column_name_exists?( k ) and use_for_output?( k )}.map{ | k | output_column_H[ k ] }
    next if ( a1.all?( &:empty? ) )
    tmp3_F.puts output_column_H.to_json
end
tmp2_F.close( true )

tmp3_F.close
tmp3_F.open

#   Below here, the TEMPFILES only have the "used columns". 

tmp4_F = Tempfile.new( "#{myself_name}.tmp4_F." )
tmp3_F.each_line do | input_column_J |
    input_column_J.chomp!
    input_column_H = JSON.parse( input_column_J )
    output_column_H = {}
    column_use_H_F.each_pair do | column_name, column_use |       
        if ( used_column_header_A.index( column_name ).nil? ) then
            SE.puts "#{SE.lineno}: Couldn't find '#{column_name}' in 'used_column_header_A'"
            SE.q {[ 'used_column_header_A' ]}
            raise
        end
        
        case column_use
        when K.fmtr_inmagic_seriesdate
            if ( input_column_H[ column_name ].not_empty? ) then
                output_column_H[ series_column_name_F ] += " #{K.fmtr_inmagic_quote}#{input_column_H[ column_name ]}#{K.fmtr_inmagic_quote}"
            end

        when K.fmtr_inmagic_seriesnote
            if ( input_column_H[ column_name ].not_empty? and split_on_bars?( column_name ) ) then
                note_A = input_column_H[ column_name ].split( '|' ).map( &:to_s ).map( &:strip ) 
                note_A.each do | note |
                    output_column_H[ series_column_name_F ] += " #{K.fmtr_inmagic_quote}Note: #{note}#{K.fmtr_inmagic_quote}"
                end
            end
            
        when K.fmtr_inmagic_series
            input_column_H[ column_name ].sub!( /\A([0-9])+[.]?\s+/, '' )
            if ( $~.nil? ) then
                SE.puts "#{SE.lineno}: Used column '#{column_name}' is supposed to be a '#{K.fmtr_inmagic_series}' but there's no series number"
                SE.puts "#{SE.lineno}: at the begining of the column."
                SE.q {[ 'input_column_H' ]}
                raise
            end
            output_column_H[ column_name ] = "#{input_column_H[ column_name ]} #{K.fmtr_inmagic_quote}#{K.series} #{$~[ 1 ]}#{K.fmtr_inmagic_quote}"
            
        when K.fmtr_inmagic_detail    
            output_column_H[ column_name ] = input_column_H[ column_name ]
        
        else
            SE.puts "Unknown column_use '#{column_use}'"
            SE.q {[ column_use_H_F ] }
            raise
        end
    end         
    if ( output_column_H.keys.maxindex != used_column_header_A.select{ | e | e if (use_for_output?( e ))}.maxindex ) then
        SE.puts "#{SE.lineno}: output_column_H.keys.maxindex != used_column_header_A.select{ | e | e if (use_for_output?( e ))}.maxindex."
        SE.q {[ 'output_column_H.keys', 'used_column_header_A.select{ | e | e if (use_for_output?( e ))}' ]}
        raise
    end

    output_column_A = output_column_H.keys.each.map{ | k | { 'column_name' => k, 'column_value' => output_column_H[ k ] } }
    tmp4_F.puts output_column_A.to_json
end
tmp3_F.close( true )

tmp4_F.close
tmp4_F.open

@output_record_cnt = 0
tmp4_F.each_line do | input_column_J |
    input_column_J.chomp!
    column_H_A = JSON.parse( input_column_J )
    SE.puts "#{SE.lineno}: #{input_column}" if ( $DEBUG )

    put_column( column_H_A )
end
tmp4_F.close( true )

SE.puts ""
SE.puts "Count of 4-digit-year date patterns found:"
SE.q {[ '@find_dates_with_4digit_years_O.pattern_cnt_H' ]}

if ( @cmdln_option_H[ :default_century ].empty? ) then
    SE.puts ""
    SE.puts "Count of 2-digit-year date patterns found, but not converted to YYYY-mm-dd:"
    SE.q {[ '@find_dates_with_2digit_years_O.pattern_cnt_H' ]}
end




