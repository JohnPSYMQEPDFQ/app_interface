require 'json'
require 'optparse'

require 'class.Hash.extend.rb'
require 'class.Array.extend.rb'
require 'class.Object.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'
#require 'class.Find_Dates_in_String.rb'
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

module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :valid_column_uses_H, :cmdln_option_H, :current_box_folder, 
                      :output_detail_F, :output_detail_cnt, :detail_column_H_A
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

myself_name = File.basename( $0 )

def column_use_H
    if ( self.cmdln_option_H.has_no_key?( :column_use_H ) ) then
        SE.puts "Can find 'self.cmdln_option_H[ :column_use_H ]"
        SE.q {[ self.cmdln_option_H ]} 
        raise
    end
    return self.cmdln_option_H[ :column_use_H ]
end
def column_name_exists?( column_name )
    return column_use_H.has_key?( column_name )
end
def series_column_name()
    column_use_H.each_pair do | c, v | 
        if ( v == K.fmtr_inmagic_series ) then
            return c
        end
    end
    return nil
end
def series_pos( on_nil = :fail )
    pos = column_pos_for_use( K.fmtr_inmagic_series, on_nil )
    return pos
end
def seriesdate_pos( on_nil = :fail)
    pos = column_pos_for_use( K.fmtr_inmagic_seriesdate, on_nil )
    return pos
end
def seriesnote_pos( on_nil = :fail )
    pos = column_pos_for_use( K.fmtr_inmagic_seriesnote, on_nil )
    return pos
end
def column_pos_for_use( use, on_nil = :fail )
    pos = column_use_H.keys.index( use )
    if ( on_nil == :fail and pos.nil? ) then
        SE.puts "#{SE.lineno}: Can't find the '#{use}' column in 'column_use_H'"
        SE.q {[ 'column_use_H' ]}
        raise
    end  
    return pos if ( on_nil == :nil_ok )
    SE.puts "#{SE.lineno}: Invalid value of 'on_nil' parameter, expected :fail or :nil_ok, got '#{on_nil}'"
    raise
end
def used_for_detail?( column_name )
    column_use = column_use_H[ column_name ]
    use = self.valid_column_uses_H[ column_use ][ :used_for_detail ]
    if ( use.nil? ) then
        SE.puts "self.valid_column_uses_H[ column_use_H[ column_name ] ][ :used_for_detail ] returns nil"
        SE.q {[ 'column_name', 'column_use_H' ]}
        SE.q {[ 'self.valid_column_uses_H' ]}
        raise
    end
    return use
end
def has_subcolumns?( column_name )
    column_use = column_use_H[ column_name ]
    use = self.valid_column_uses_H[ column_use ][ :has_subcolumns ]
    if ( use.nil? ) then
        SE.puts "self.valid_column_uses_H[ column_use_H[ column_name ] ][ :has_subcolumns ] returns nil"
        SE.q {[ 'column_name', 'column_use_H' ]}
        SE.q {[ 'self.valid_column_uses_H' ]}
        raise
    end
    return use
end

def output_detail_F_puts( *argv )
    self.output_detail_F.puts argv.join( ' ' )
    self.output_detail_cnt += 1
end

def put_column( indent_spaces, column_idx = 0, title_length = 0 )
    SE.q { [ 'self.detail_column_H_A[ column_idx]' ]}  if ( $DEBUG )  
    column_H     = self.detail_column_H_A[ column_idx ]
    column_name  = column_H[ 'column_name' ]
    column_value = column_H[ 'column_value' ]
    SE.q { [ 'column_idx', 'column_name', 'column_value', 'column_H' ]} if ( $DEBUG ) 
    
    if ( matchdata = column_value.match( /^"(.*)"$/ ) ) then
        column_value = matchdata[ 1 ]
    end

    if ( has_subcolumns?( column_name )) then
        sub_column_value_A = column_value.split( '|' ).map( &:to_s )# .map( &:strip )    
        sub_column_value_A = sub_column_value_A.sort_by { | k | k.downcase.strip.gsub(/[^[a-z0-9 ]]/,'') } if ( self.cmdln_option_H[ :sort ] )
    else
        if ( column_value.include?( '|' )) then
            SE.puts "#{SE.lineno}: column has a '|' but doesn't have a use of :subcolumns."
            SE.q {[ 'column_idx', 'column_name' ] }
            SE.q {[ 'column_value' ]}
            raise
        end
        sub_column_value_A = [ column_value ]
    end

    SE.q { 'sub_column_value_A' } if ( $DEBUG )
    first_sub_column_entry_is_a_subseries = false
    sub_column_value_A.each_with_index do | sub_column_value, sub_column_idx |
        next if ( sub_column_value.blank? )
        sub_column_without_notes = sub_column_value + ''
        sub_column_without_notes.gsub!( /\s+Note:.*/i, '' )  
        if ( column_idx < self.detail_column_H_A.maxindex ) then
            output_detail_F_puts indent_spaces + sub_column_value 
            if ( sub_column_value.match( /^series /i ) ) then
                #  The Series records are their own "indent_right".
            else
                output_detail_F_puts indent_spaces + "#{K.fmtr_indent}: #{K.fmtr_right}" 
            end

            self.current_box_folder.gsub!( /#{K.fmtr_end_group}/, '' )
            
            put_column( indent_spaces + '    ', column_idx + 1, title_length + sub_column_without_notes.length )   # <<<<<<<<<<<<<<<<

            self.current_box_folder += " #{K.fmtr_end_group}"

            if ( sub_column_value.match( /^series /i ) ) then
                output_detail_F_puts indent_spaces + K.fmtr_end_group
            else
                output_detail_F_puts indent_spaces + "#{K.fmtr_indent}: #{K.fmtr_left}"
            end

        else   
            note = ''
            if ( sub_column_value.sub!( /(\(.*?\))\s*$/, '' ) ) then
                note = $&
                note.gsub!( /[()]/, '' )
                note.strip!
                note.sub!( /./,&:upcase )
                note.sub!( /\.$/, '' )      # The note is put back AFTER the date logic
            end
            
            stringer = sub_column_value.sub( K.box_and_folder_RE, '' )
            if ( $&.not_nil? ) then
                box_folder = $&
                prematch=$`
                if ( stringer.blank? ) then                             # If true: the sub_column is ONLY the Box/folder data.
                    box_folder.strip!
                    next if ( box_folder.upcase == self.current_box_folder.upcase )
                    self.current_box_folder = box_folder.upcase
                    next
                else
                    if ( prematch.blank? ) then                         # If true: the Box is the 1st thing in the sub-column
                        self.current_box_folder = ''                          # which we'll guess to mean to reset the current_box_folder
                    end
                end
            end
            
            sub_column_value += " Note: #{note}." if ( note.not_blank? )

            if ( sub_column_value.match( /^(subseries|sub-series) /i ) ) then
                if ( sub_column_idx == 0 ) then
                    first_sub_column_entry_is_a_subseries = true
                else
                    self.current_box_folder += " #{K.fmtr_end_group}"
                    indent_spaces.sub!( /^    /, '' )
                    output_detail_F_puts indent_spaces + K.fmtr_end_group + ' End-Begin'
                end
                output_detail_F_puts indent_spaces + sub_column_value
                indent_spaces += '    '
                SE.puts "WARNING: Series or Sub-series at ln:#{self.output_detail_cnt}: '#{sub_column_value}'"
                SE.puts ""
            else
                if ( sub_column_value.gsub( '_', '' ).not_blank? ) then
                    stringer = ''
                    stringer += indent_spaces
                    stringer += "%-20s  " % self.current_box_folder if ( self.current_box_folder.not_blank? and not sub_column_value.index( self.current_box_folder ) )
                    stringer += sub_column_value                            
                    output_detail_F_puts stringer
                    if ( stringer.match( /box.*(oversized?|folder|slides?)?.*box.*(oversized?|folder|slides?)?/i ) ) then
                        SE.puts "WARNING: Multiple repeats of box, folder, oversize, or slide found at ln:#{self.output_detail_cnt}: #{stringer}"
                        SE.puts ""
                    end     
                end
            end
            if ( first_sub_column_entry_is_a_subseries and sub_column_idx == sub_column_value_A.maxindex ) then
                self.current_box_folder += " #{K.fmtr_end_group}"
                indent_spaces.sub!( /^    /, '' )
                output_detail_F_puts indent_spaces + K.fmtr_end_group + ' Last Record'
            end
            if ( sub_column_value.count( '"' ) % 2 != 0 ) then
                SE.puts "WARNING: Odd number of double-quotes found at ln:#{self.output_detail_cnt}:'#{sub_column_value}'"
                SE.puts ""
            end
            if ( ( sub_column_value.count( ')' ) + sub_column_value.count( '(' ) ) % 2 != 0 ) then
                SE.puts "WARNING: Odd number of parentheses found at ln:#{self.output_detail_cnt}:'#{sub_column_value}'"
                SE.puts ""
            end
            if ( ( sub_column_value.count( ']' ) + sub_column_value.count( '[' ) ) % 2 != 0 ) then
                SE.puts "WARNING: Odd number of square-brackets found at ln:#{self.output_detail_cnt}:'#{sub_column_value}'"
                SE.puts ""
            end
            if ( ( title_length + sub_column_without_notes.length ) > self.cmdln_option_H[ :max_title_size ] ) then
                SE.puts "WARNING: Max title size is greater than #{self.cmdln_option_H[ :max_title_size ]} at ln:#{self.output_detail_cnt}:'#{sub_column_value}'"
                SE.puts ""
            end
        end
    end

end


self.valid_column_uses_H = { K.fmtr_inmagic_detail       => { :used_for_detail => true , :has_subcolumns => true,  } ,
                             K.fmtr_inmagic_series       => { :used_for_detail => true , :has_subcolumns => false, } ,
                             K.fmtr_inmagic_seriesdate   => { :used_for_detail => false, :has_subcolumns => false, } ,
                             K.fmtr_inmagic_seriesnote   => { :used_for_detail => false, :has_subcolumns => false, } ,
                           }

self.cmdln_option_H = { :r => 999999999,
                        :output_file_prefix => '',
                        :d => false,
                        :sort => false,
                        :default_century_pivot_ccyymmdd => '',
                        :max_title_size => 150,
                        :column_use_H => {},
                       }

OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"

    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        self.cmdln_option_H[ :r ] = opt_arg
    end
    
    option.on( "--sort", "Sort the detail records." ) do
        self.cmdln_option_H[ :sort ] = true
    end  
    
    option.on( "--output-file-prefix=x", "File prefix for the two output files." ) do |opt_arg|
        self.cmdln_option_H[ :output_file_prefix ] = opt_arg
    end

    option.on( "--default-century n", OptionParser::DecimalInteger, "Default century pivot date for 2-digit years." ) do
        self.cmdln_option_H[ :default_century_pivot_ccyymmdd ] = opt_arg
    end  
    
    option.on( "--columns=NAME[:use][,NAME:use]...", "Order and use of the columns") do |opt_arg|
        arr1 = opt_arg.split( ',' ).map( &:to_s ).map( &:strip )
        arr1.each do | stringer |
            a2 = stringer.split( ':' ).map( &:to_s ).map( &:strip )
            if ( a2.maxindex > 1 ) then
                SE.puts "--columns option has wrong formatting, there should only be a max of two pieces not #{a2.length}"
                SE.q {[ 'a2', 'arr1' ]}
                raise
            end
            if ( column_use_H.has_key?( a2[ 0 ] ) ) then
                SE.puts "Duplicate column_name '#{a2[ 0 ] }' found in --columns option"
                SE.q {[ 'opt_arg', 'arr1', 'column_use_H' ]}
                raise
            end
            if ( a2[ 1 ] ) then
                if ( self.valid_column_uses_H.has_no_key?( a2[ 1 ] ) ) then
                    SE.puts "#{SE.lineno}: Unknown column use '#{a2[ 1 ]}' on column '#{a2[ 0 ]}'"
                    SE.q {[ 'self.cmdln_option_H' ]}
                    raise
                end
                if ( a2[ 1 ].in?( self.valid_column_uses_H.values ) ) then
                    SE.puts "#{SE.lineno}: column use '#{a2[ 1 ]}' on column '#{a2[ 0 ]}' already exists."
                    SE.q {[ 'self.cmdln_option_H' ]}
                    raise
                end
                self.cmdln_option_H[ :column_use_H ][ a2[ 0 ] ] = a2[ 1 ].downcase
            else
                self.cmdln_option_H[ :column_use_H ][ a2[ 0 ] ] = K.fmtr_inmagic_detail
            end
        end
    end
    
    option.on( "--max-title-size n", OptionParser::DecimalInteger, "Warn if title-size over n" ) do |opt_arg|
        self.cmdln_option_H[ :max_title_size ] = opt_arg
    end

    option.on( "-d", "Turn on $DEBUG switch" ) do
        $DEBUG = true
    end

    option.on( "-h", "--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
SE.q {[ 'self.cmdln_option_H' ]}

tmp1_F = Tempfile.new( "#{myself_name}.tmp1_F." )
#SE.puts "#{SE.lineno}: tmp1_F.path=#{tmp1_F.path}"

ARGF.each do | csv_from_pwsh_as_one_big_J |
    csv_from_pwsh_as_one_big_J.chomp
    csv_from_pwsh_as_one_big_THING = JSON.parse( csv_from_pwsh_as_one_big_J )
    case true
    when csv_from_pwsh_as_one_big_THING.is_a?( Hash )
        tmp1_F.puts csv_from_pwsh_as_one_big_THING.to_json
    when csv_from_pwsh_as_one_big_THING.is_a?( Array )
        csv_from_pwsh_as_one_big_THING.each do | input_column_H |
            tmp1_F.puts input_column_H.to_json
        end
    else
        SE.puts "#{SE.lineno}: I can't figure out what the data format in the 'csv_from_pwsh_as_one_big_THING' is."
        SE.q { [ 'csv_from_pwsh_as_one_big_THING' ] }
        raise
    end
end
tmp1_F.close

tmp2_F = Tempfile.new( "#{myself_name}.tmp2_F." )
column_with_data_H = {}
original_file_header_A = []
tmp1_F.open
tmp1_F.each_line do | input_column_J |
    if ( $. > self.cmdln_option_H[ :r ] ) then 
        SE.puts ""
        SE.puts "#{SE.lineno}: Stopped after #{self.cmdln_option_H[ :r ]} records."
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
        column_value.gsub!( "\n", '|' )
        column_value.gsub!( /[^[:print:]]/, ' ' )
        column_value.gsub!( '""', '"' )
#       column_value.strip!
        output_column_H[ column_header ] = column_value
       
        if ( column_value.not_blank? and column_with_data_H.has_no_key?( column_header ) ) then
            stringer = (column_value.include?( '|' ) ) ? '*|*' : '   '
            column_with_data_H[ column_header ] = "#{stringer} Line=#{$.}: #{column_value}"
        end
    end
    tmp2_F.puts output_column_H.to_json
end
tmp1_F.close( true )
tmp2_F.close

tmp3_F = Tempfile.new( "#{myself_name}.tmp3_F." )
SE.q {['column_with_data_H']}
used_column_header_A = []
tmp2_F.open
tmp2_F.each_line do | input_column_J |    
    input_column_J.chomp!
    input_column_H = JSON.parse( input_column_J )
    output_column_H={}
    
    input_column_H.keys.each do | column_name |
        if ( column_with_data_H[ column_name ].nil? ) then
            next
        end
        output_column_H[ column_name] = input_column_H[ column_name ]  
    end

    if ( $. == 1 ) then
        used_column_header_A = output_column_H.keys
        if (self.cmdln_option_H[ :column_use_H ].empty? ) then
            used_column_header_A.each do | column_name | 
                self.cmdln_option_H[ :column_use_H ][ column_name ] = :none_assigned 
            end
        else
            arr1 = column_use_H.keys - used_column_header_A           
            if ( arr1.not_empty? ) then
                SE.puts ""
                SE.puts ""
                SE.puts "#{SE.lineno}: Unknown column '#{arr1.join(', ')}' in --columns option"
                SE.puts ""
                SE.q {[ 'column_use_H.keys' ]}
                SE.q {[ 'used_column_header_A' ]}
                raise
            end
            arr1 = used_column_header_A - column_use_H.keys
            if ( arr1.not_empty? ) then
                SE.puts "The following columns are being skipped:"
                SE.puts "#{arr1.join(', ')}"
            end
            used_column_header_A = column_use_H.keys
        end
        SE.puts ""
        SE.puts "CSV column headers      : #{original_file_header_A.join( ', ')}"
        SE.puts "Input columns being used: #{used_column_header_A.join( ', ' )}"
        SE.puts "   for the following use: #{column_use_H.values.join( ', ' )}"
        if ( column_use_H.keys.length > 1 and column_use_H.values.select{ | e | e if ( e != :none_assigned ) }.uniq.size == 1 ) then
            SE.puts ""
            SE.puts ""
            SE.puts ""
            SE.puts "#{SE.lineno}: All the column uses are the same!"
            SE.puts ""
            exit
        end
        
        if ( seriesnote_pos( :nil_ok ) and seriesnote_pos < series_pos ) then
            SE.puts "#{SE.lineno}: The '#{K.fmtr_inmagic_seriesnote}' column must be after the '#{K.fmtr_inmagic_series}' column"
            SE.q {[ 'seriesnote_pos', 'series_pos', 'column_use_H ' ]}
            raise
        end
        if ( seriesdate_pos( :nil_ok ) and seriesdate_pos < series_pos ) then
            SE.puts "#{SE.lineno}: The '#{K.fmtr_inmagic_seriesdate}' column must be after the '#{K.fmtr_inmagic_series}' column."
            SE.q {[ 'seriesdate_pos', 'series_pos', 'column_use_H ' ]}
            raise
        end
        if ( seriesdate_pos( :nil_ok ) and seriesnote_pos( :nil_ok ) and seriesdate_pos > seriesnote_pos ) then
            SE.puts "#{SE.lineno}: The '#{K.fmtr_inmagic_seriesdate}' column must be before the '#{K.fmtr_inmagic_seriesnote}' column,"
            SE.puts "#{SE.lineno}: this is so the dates get put in-front-of the note."
            SE.q {[ 'seriesdate_pos', 'seriesnote_pos', 'column_use_H ' ]}
            raise
        end
        SE.puts ""   
    end
    tmp3_F.puts output_column_H.to_json
end
tmp2_F.close( true )
tmp3_F.close

# SE.q {[ 'column_use_H' ]}

resource_data_H = {}
tmp3_F.open
tmp3_F.each_line do | input_column_J |
    input_column_J.chomp!
    input_column_H = JSON.parse( input_column_J )
    input_column_H.each_pair do | column_name, column_value |
        if ( column_value.blank? ) then
#           SE.puts "#{SE.lineno}: column_name:#{column_name} value blank"
            next
        end
        if ( column_use_H.has_key?( column_name ) and column_use_H[ column_name ] != :none_assigned ) then
            if ( column_use_H[ column_name ] == K.fmtr_inmagic_seriesdate ) then
                if ( not ( series_column_name.nil? or input_column_H[ series_column_name ].blank? ) ) then
#                   SE.puts "#{SE.lineno}: NOT ( series_column_name.nil? or input_column_H[ '#{series_column_name}' ].blank? )"
#                   SE.q {[ 'column_name', 'column_value', 'series_column_name' ]}
                    next
                end
            else
#               SE.puts "#{SE.lineno}: column_use_H[#{column_name}]: NOT #{column_use_H[ column_name ]} == #{K.fmtr_inmagic_seriesdate}"
                next
            end
        end
        
        column_value.strip!
        if ( resource_data_H.has_no_key?( column_name ) ) then
            resource_data_H[ column_name ] = ''
        end
        case column_name.downcase
        when 'Filing Location'.downcase
            stringer = (( resource_data_H[ column_name ].blank? ) ? '' : ', ' ) + column_value.sub( /\s*Statewide Museum Collections Center\s*/i, '' )
            resource_data_H[ column_name ] += stringer.gsub( /\s\s+/, ' ' )
        else    
            if ( resource_data_H[ column_name ] != column_value ) then
                stringer = (( resource_data_H[ column_name ].blank? ) ? '' : ' +++++ ' ) + column_value
                resource_data_H[ column_name ] += stringer
            end
        end
    end
end
tmp3_F.close

output_resource_filename = self.cmdln_option_H[ :output_file_prefix ] + ".RESOURCE_DATA.txt"
SE.puts "Output RESOURCE_DATA file '#{output_resource_filename}'"
output_resource_F = File::open( output_resource_filename, mode='w' )
resource_data_H.each_pair do | column_name, column_value |
    column_value.gsub!( '|', '   ' )
    h = { column_name => column_value }
    output_resource_F.puts h.to_json
end
output_resource_F.close

if ( column_use_H.values.all?( :none_assigned ) ) then
    SE.puts ""
    SE.puts ""
    SE.puts ""
    SE.puts "Provide the --columns option to get past this point."
    SE.puts ""
    exit
end
if ( self.cmdln_option_H[ :output_file_prefix ].blank? ) then
    SE.puts ""
    SE.puts ""
    SE.puts ""
    SE.puts "Provide the --output-file-prefix option to get past this point."
    SE.puts ""
    exit
end

tmp4_F = Tempfile.new( "#{myself_name}.tmp4_F." )
tmp3_F.open
tmp3_F.each_line do | input_column_J |
    input_column_J.chomp!
    input_column_H = JSON.parse( input_column_J )
    arr1 = input_column_H.keys.select{ | k | column_name_exists?( k ) and used_for_detail?( k )}.map{ | k | input_column_H[ k ] }
    next if ( arr1.all?( &:empty? ) )
    
    output_column_H = {}
    column_use_H.each_pair do | column_name, column_use |       
        if ( used_column_header_A.index( column_name ).nil? ) then
            SE.puts "#{SE.lineno}: Couldn't find '#{column_name}' in 'used_column_header_A'"
            SE.q {[ 'used_column_header_A' ]}
            raise
        end
        
        case column_use
        when K.fmtr_inmagic_seriesdate
            if ( series_column_name.nil? ) then
                SE.puts "#{SE.lineno}: Couldn't find the 'series_column_name' for column-use: #{column_use}, for column: #{column_name}"
                SE.puts "#{SE.lineno}: Note: this is probably the 'extent' column.  If there are NO series records, it's the Resource date"
                SE.q {[ 'used_column_header_A' ]}
                raise
            end
            if ( input_column_H[ column_name ].not_blank?  ) then
                output_column_H[ series_column_name ] += " #{input_column_H[ column_name ]}"
            end

        when K.fmtr_inmagic_seriesnote
            if ( input_column_H[ column_name ].not_blank? ) then
                note_A = input_column_H[ column_name ].split( '|' ).map( &:to_s ).map( &:strip ) 
                note_A.each do | note |
                    next if ( note.blank? )
                    note.sub!( /./,&:upcase )
                    note.sub!( /\.$/, '' )
                    output_column_H[ series_column_name ] += " Note: #{note}."
                end
            end
            
        when K.fmtr_inmagic_series
            input_column_H[ column_name ].sub!( /\A\s*Series\s*/, '' )
            input_column_H[ column_name ].sub!( /\A([0-9]+)[.]?\s+/, '' )
            if ( $~.nil? ) then
                SE.puts "#{SE.lineno}: Column '#{column_name}' is supposed to be a '#{K.fmtr_inmagic_series}' but there's no series number"
                SE.puts "#{SE.lineno}: at the begining of the column."
                SE.q {[ 'input_column_H' ]}
                raise
            end
            series_num=$1
            output_column_H[ column_name ] = ''
            arr1 = input_column_H[ column_name ].split( '|' ).map( &:to_s ).map( &:strip ) 
            series_name = ''
            arr1.each_with_index do | e, idx |
                if ( idx == 0 ) then
                    output_column_H[ column_name ] += "Series #{series_num}: #{e}"
                    series_name = e
                end
                next if ( e.blank? )
                next if ( e.downcase == series_name.downcase )
                e.sub!( /./,&:upcase )
                e.sub!( /\.$/, '' )
                output_column_H[ column_name ] += " Note: #{e}."
            end
         
        when K.fmtr_inmagic_detail    
            output_column_H[ column_name ] = input_column_H[ column_name ]
        
        else
            SE.puts "Unknown column_use '#{column_use}'"
            SE.q {[ column_use_H ] }
            raise
        end
    end         
    if ( output_column_H.keys.maxindex != used_column_header_A.select{ | e | e if (used_for_detail?( e ))}.maxindex ) then
        SE.puts "#{SE.lineno}: output_column_H.keys.maxindex != used_column_header_A.select{ | e | e if (used_for_detail?( e ))}.maxindex."
        SE.q {[ 'output_column_H.keys', 'used_column_header_A.select{ | e | e if (used_for_detail?( e ))}' ]}
        raise
    end

    output_column_A = output_column_H.keys.each.map{ | k | { 'column_name' => k, 'column_value' => output_column_H[ k ] } }
    tmp4_F.puts output_column_A.to_json
end
tmp3_F.close( true )
tmp4_F.close

self.output_detail_cnt = 0
self.current_box_folder = ''

output_detail_filename = self.cmdln_option_H[ :output_file_prefix ] + ".DETAIL.txt"
SE.puts "Output DETAIL file '#{output_detail_filename}'"
SE.puts ''
SE.puts ''

self.output_detail_F = File::open( output_detail_filename, mode='w' )
tmp4_F.open
tmp4_F.each_line do | input_column_J |
    input_column_J.chomp!
    self.detail_column_H_A = JSON.parse( input_column_J )
    SE.puts "#{SE.lineno}: #{input_column}" if ( $DEBUG )
    put_column( '' )
end
tmp4_F.close( true )
self.output_detail_F.close




