require 'Date'
require 'json'
require 'pp'
require 'awesome_print'
require 'optparse'

require 'class.ArchivesSpace.rb'
require 'class.Find_Dates_in_String.rb'
require 'class.formatter.Shelf_ID_for_Boxes.rb'


module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :cmdln_option_H, :output_fd3_F, :aspace_O,
                      :states_A, :states_RES, :states_RE, :prepend_A,
                      :find_dates_with_4digit_years_O, :find_dates_with_2digit_years_O,
                      :min_date, :max_date, :note_cnt, :box_cnt, :auto_group_H, :pending_output_record_H
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

def scrape_off_container( input_record, shelf_id_O, from_thru_date_H_A)
    output_record = ''
    container_H_A = [ ]
    child_types_without_indicators_A = []
    loop do
        container_and_child_types_matchdata_O = input_record.match( K.container_and_child_types_RE )
        break if ( container_and_child_types_matchdata_O.nil? )    
        
        SE.q {['input_record','container_and_child_types_matchdata_O']}  if ( $DEBUG )
        
        container_H = K.fmtr_empty_container_H
        input_record.sub!( K.container_and_child_types_RE, ' ' )
        container_num = container_and_child_types_matchdata_O[ :container_num ]
        container_A = container_num.split( K.container_type_separators_RE )
        if ( container_A.length > 1) then
            if ( container_A.length != 3 ) then
                SE.puts "#{SE.lineno}: Got odd 'box' text, 'container_A.length != 3'"
                SE.q {'input_record'}
                SE.q {'container_and_child_types_matchdata_O'}
                SE.q {'container_A'}
                raise
            end
            if ( container_and_child_types_matchdata_O[ :container_type_modifier ].not_nil? or
                 container_and_child_types_matchdata_O[ :child_type ].not_nil? or
                 container_and_child_types_matchdata_O[ :grandchild_type ].not_nil? ) then
                SE.puts "#{SE.lineno}: Got odd 'box' text, 'container_A.length > 1' but one of the"
                SE.puts "#{SE.lineno}: :container_type_modifier, :child_type, :grandchild_type"
                SE.puts "#{SE.lineno}: is not nil. I can't handle the complexity of it all..."  
                SE.q {'input_record'}
                SE.q {'container_and_child_types_matchdata_O'}
                SE.q {'container_A'}
                raise
            end                
        end
        container_A.each_with_index do | indicator, idx |
            if ( idx == 1 ) then
                next if ( indicator.strip.in?( ',', 'and' ) )
                SE.puts "#{SE.lineno}:  I'm not programmed to handle a '#{indicator}'"
                SE.q {'input_record'}
                SE.q {'container_and_child_types_matchdata_O'}
                SE.q {'container_A'}
                raise                
            end
            container_H[ K.indicator ] = indicator.gsub( /box(s|es)?/, ' ' ).strip
            if ( container_H[ K.indicator ].not_integer? ) then
                SE.puts "#{SE.lineno}:  Got a non-integer indicator number."
                SE.q {'container_H[ K.indicator ]'}
                SE.q {'input_record'}
                SE.q {'container_and_child_types_matchdata_O'}
                SE.q {'container_A'}
                raise               
            end
            case true
            when container_and_child_types_matchdata_O[ :container_type ].match?( /^box(s|es)?/i )
                container_H[ K.type ]           = K.box
            when container_and_child_types_matchdata_O[ :container_type ].match?( /^ov/i )
                container_H[ K.type ]           = K.box
                container_H[ K.indicator ]     += ' OV'
            else
                SE.puts "#{SE.lineno}: Invalid container_type: '#{container_and_child_types_matchdata_O[ :container_type ]}'"
                SE.q {[ 'container_and_child_types_matchdata_O' ]}
                raise
            end 

            if ( container_and_child_types_matchdata_O[ :container_type_modifier ].not_nil? ) then       
                container_type_modifier = container_and_child_types_matchdata_O[ :container_type_modifier ]
                container_type_modifier.gsub!( /[\[\]]/, '' )
                case true
                when container_type_modifier.match?( /^ov/i )      # ^ov will match oversize
                    container_H[ K.indicator ] += ' OV'
                when container_type_modifier.match?( /^(sb|slide)/i )
                    container_H[ K.indicator ] += ' SB'
                when container_type_modifier.match?( /^(rc|record)/i )
                    container_H[ K.indicator ] += ' RC'
                else
                    container_H[ K.indicator ] += " #{container_type_modifier}"
                end
            end

            if ( container_and_child_types_matchdata_O[ :child_type ].not_nil? ) then
                child_type = container_and_child_types_matchdata_O[ :child_type ].downcase.sub( /([^s])s$/, '\1' )
                if ( container_and_child_types_matchdata_O[ :child_num ].nil? ) then                
#                   child_types_without_indicators_A << "[#{child_type.sub( /./,&:upcase )}]"
                    container_H[ K.type_2 ]      = child_type
                    if ( child_type.downcase == K.volume and from_thru_date_H_A.maxindex == 0 ) then
                        stringer = from_thru_date_H_A[ 0 ][ K.expression ]
                        from_thru_date_H_A.shift
                    else
                        stringer = 'NN'
                    end
                    container_H[ K.indicator_2 ] = stringer
                else
                    container_H[ K.type_2 ]      = child_type
                    container_H[ K.indicator_2 ] = container_and_child_types_matchdata_O[ :child_num ]
                end   
            end   
       
            if ( container_and_child_types_matchdata_O[ :grandchild_type ].not_nil? ) then
                grandchild_type = container_and_child_types_matchdata_O[ :grandchild_type ].downcase.sub( /([^s])s$/, '\1' )
                if ( container_and_child_types_matchdata_O[ :grandchild_num ].nil? ) then                
#                   child_types_without_indicators_A << "[#{grandchild_type.sub( /./,&:upcase )}]"
                    container_H[ K.type_3 ]      = grandchild_type
                    if ( grandchild_type.downcase == K.volume and from_thru_date_H_A.maxindex == 0 ) then
                        stringer = from_thru_date_H_A[ 0 ][ K.expression ]
                        from_thru_date_H_A.shift
                    else
                        stringer = 'NN'
                    end
                    container_H[ K.indicator_3 ] = stringer
                else
                    container_H[ K.type_3 ]      = grandchild_type
                    container_H[ K.indicator_3 ] = container_and_child_types_matchdata_O[ :grandchild_num ] 
                end   
            end  
        end
        SE.q {[ 'input_record' ]}  if ( $DEBUG )
        SE.q {[ 'container_H' ]}   if ( $DEBUG )
        container_H_A.push( container_H )
    end

    loop do
        container_bracketed_type_matchdata_O = input_record.match( K.container_bracketed_word_RE ) 
        break if ( container_bracketed_type_matchdata_O.nil? )
        input_record.sub!( K.container_bracketed_word_RE, ' ' )
        child_types_without_indicators_A << "[#{container_bracketed_type_matchdata_O[ :bracketed_word ].downcase.sub( /([^s])s$/, '\1' ).sub( /./,&:upcase )}]"
        SE.q {[ 'input_record' ]}  if ( $DEBUG )
        SE.q {[ 'child_types_without_indicators_A' ]}  if ( $DEBUG )
    end       

    if ( child_types_without_indicators_A.not_empty? ) then
        output_record = child_types_without_indicators_A.join( ' ' ) + ' ' + output_record
    end

    output_record += input_record
    return output_record, container_H_A
end

def scrape_off_notes( input_record )
    note_A = [ ]
    input_record_note_A = input_record.split( /\s+(note:|notes:)\s*/i ).map( &:to_s ).map( &:strip )
    if ( input_record_note_A.maxindex > 0) then
        input_record = input_record_note_A.shift( 1 )[ 0 ]   # input_record with the NOTES removed.
        input_record_note_A.each do | note |
            next if ( note.match?( /^(note:|notes:)\s*$/i ) ) 
            next if ( note.blank? )
            note.strip!
            note.gsub!( /\s\s+/, ' ')
            note.sub!( /./,&:upcase )
            self.note_cnt += 1
            note_A.push( note )
        end
    end
    return input_record, note_A
end

def scrape_off_dates( input_record )
    input_record.sub!( /\s*\.\s*$/, '' )
    from_thru_date_H_A = [ ]
    input_record = self.find_dates_with_4digit_years_O.do_find( input_record )
    self.find_dates_with_4digit_years_O.good__date_clump_S__A.each do | date_clump_S |
        from_thru_date_H = {}
        from_thru_date_H[ K.begin ] = date_clump_S.as_from_date
        if ( self.min_date == "" or self.min_date > date_clump_S.as_from_date ) then
            self.min_date = date_clump_S.as_from_date
        end
        if ( self.max_date == "" or self.max_date < date_clump_S.as_from_date ) then
            self.max_date = date_clump_S.as_from_date
        end
        if ( date_clump_S.as_thru_date.not_blank? ) then
            from_thru_date_H[ K.end ] = date_clump_S.as_thru_date 
            if ( self.min_date == "" or self.min_date > date_clump_S.as_thru_date ) then
                self.min_date = date_clump_S.as_thru_date
            end
            if ( self.max_date == "" or self.max_date < date_clump_S.as_thru_date ) then
                self.max_date = date_clump_S.as_thru_date
            end 
        else
            from_thru_date_H[ K.end ] = date_clump_S.as_from_date
        end
        from_thru_date_H[ K.bulk ]  = date_clump_S.bulk 
        from_thru_date_H[ K.circa ] = date_clump_S.circa 
        from_thru_date_H[ K.expression] = self.aspace_O.format_date_expression( from_thru_date_H[ K.begin ], 
                                                                                from_thru_date_H[ K.end], 
                                                                                ( from_thru_date_H[ K.circa ] ) == true ? K.circa : '' )
        from_thru_date_H_A << from_thru_date_H
    end
    if ( self.cmdln_option_H[ :default_century_pivot_ccyymmdd ].empty? and self.cmdln_option_H[ :do_2digit_year_test ] ) then
        self.find_dates_with_2digit_years_O.do_find( input_record )
        self.find_dates_with_2digit_years_O.good__date_clump_S__A.each do | date_clump_S |  
            len = self.find_dates_with_2digit_years_O.good__date_clump_S__A.length
            from_thru_date= date_clump_S.as_from_date
            if ( date_clump_S.as_thru_date.not_blank? ) then
                from_thru_date += ' - ' + date_clump_S.as_thru_date 
            end
            SE.puts "#{SE.lineno}: WARNING: #{len} date(s) with 2-digit-years(#{from_thru_date}) found in record:'#{input_record}'"
            SE.puts ''
            break
        end
    end
    input_record.strip!
    input_record.gsub!( /\s*,\s*,/, '')     # Multiple dates 
    input_record.gsub!( /\s*,\s*$/, '')     # leave extra commas.
    input_record.gsub!( /\s\s+/, ' ' )   
    input_record.strip!
    return input_record, from_thru_date_H_A
end

def write_pending_record_H( next_pending_output_record_H )
    if ( next_pending_output_record_H.not_empty? ) then
        arr1 =  next_pending_output_record_H[ K.fmtr_record_indent_keys ] + []
        arr1.push( next_pending_output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__text_idx ] )
        if ( next_pending_output_record_H[ K.level ] == K.file ) then
            arr1.push( next_pending_output_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__container_idx ].empty? ? ', No containers' : '' )
        end            
        if ( next_pending_output_record_H[ K.level ] == K.fmtr_auto_group ) then
            arr1.push( ' (Auto-Group record)' )
        end 
        self.output_fd3_F.puts arr1.join( ' ' ) 
    end
    
    if ( self.pending_output_record_H.not_empty? ) then
        output_record_J = self.pending_output_record_H.to_json
        if ( output_record_J.match( /~~/ )) then
            SE.puts "#{SE.lineno}: Found '~~' in output_record_J, '~~' are used for program logic so probably shouldn't be here!"
            SE.q {[ 'output_record_J' ]}
            raise
        end
        puts output_record_J
    end
    self.pending_output_record_H = next_pending_output_record_H.merge( {} )
end

def set_text_for_auto_group_F( param1 )
#   SE.puts "#{SE.lineno}: #{SE.my_caller}: #{param1}"
    if ( self.auto_group_H[ :cnt ] == 0 and self.auto_group_H[ :text ].not_blank? ) then
        SE.puts "#{SE.lineno}: Warning: Auto-group text '#{self.auto_group_H[ :text ]}' never used."
    end
    if ( self.auto_group_H[ :cnt ] == 1 ) then
        SE.puts "#{SE.lineno}: Warning: Auto-group text '#{self.auto_group_H[ :text ]}' only used once."
    end
    if ( param1.nil? ) then
        SE.puts "#{SE.lineno}: Param1 is nil."
        raise
    end
    self.auto_group_H[ :text ] = param1
    self.auto_group_H[ :cnt ] = 0    
end

def get_prepend_elements_for_indent_keys_F_A
    arr = []
    self.prepend_A.each do | e | 
        arr.push( e[ 0 ] ) if ( e[ 1 ] == :indent_keys ) 
    end
    return arr
end
def get_prepend_elements_for_sort_F_A
    return self.prepend_A.column( 0 )
end

#MAIN   
myself_name = File.basename( $0 )

self.cmdln_option_H = { :max_group_levels => 12,
                        :max_title_size => 40,
                        :default_century_pivot_ccyymmdd => '',
                        :r => nil,
                        :do_2digit_year_test => false,
                        :find_dates_option_H => { },
                        :phrase_split_chars => ':.'            # These go into a [] in a regexp so don't need to escaped (\).
                     }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"
    option.on( "-l", "--ml", "--max-group-levels N", OptionParser::DecimalInteger, "Max number of group levels N (default=#{self.cmdln_option_H[ :max_group_levels ]})" ) do |opt_arg|
        self.cmdln_option_H[ :max_group_levels ] = opt_arg
    end
    option.on( "--mts", "--max-title-size N", OptionParser::DecimalInteger, "Warn if title-size over N (default=#{self.cmdln_option_H[ :max_title_size ]})" ) do |opt_arg|
        self.cmdln_option_H[ :max_title_size ] = opt_arg
    end
    option.on( "--dc", "--default_century_pivot_ccyymmdd N", OptionParser::DecimalInteger, "Default century pivot date (N) for 2-digit years." ) do |opt_arg|
        self.cmdln_option_H[ :default_century_pivot_ccyymmdd ] = opt_arg
    end  
    option.on( "-r N", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        self.cmdln_option_H[ :r ] = opt_arg
    end
    option.on( "--do_2digit_year_test", "When the --default_century_pivot_ccyymmdd option is '', warn if 2digit years found." ) do |opt_arg|
        self.cmdln_option_H[ :do_2digit_year_test ] = true
    end
    option.on( "--find_dates_option_H X", "Option Hash (X) passed to the Find_Dates_in_String class." ) do |opt_arg|
        begin
            self.cmdln_option_H[ :find_dates_option_H ] = eval( opt_arg )
        rescue Exception => msg
            SE.puts ''
            SE.puts msg
            SE.ap "Find_Dates_in_String default options:"
            SE.ap Find_Dates_in_String.new( ).option_H
            raise
        end
    end
    option.on( '-s', '--sc', '--phrase_split_chars X', "Punctuation characters (X) used to split the records (default='#{self.cmdln_option_H[ :phrase_split_chars ]}')" ) do |opt_arg|
        opt_arg.each_char do | char |
            if ( not char.match?( /[[:punct:]]/ ) ) then
                SE.puts ''
                SE.puts "Char '#{char}' of --phrase_split_chars option value '#{opt_arg}' isn't [:punct]uation"
                SE.puts
                raise
            end
        end
        self.cmdln_option_H[ :phrase_split_chars ] = opt_arg            
    end
    option.on( '-h', '-?', '--help' ) do
        SE.puts option
        SE.puts ''
        SE.puts "Find_Dates_in_String default options:".ai
        SE.puts Find_Dates_in_String.new( ).option_H.ai
        SE.puts ''
        SE.puts "Note that:  The --find_dates_option_H numeric values have to be quoted (no integers), eg."
        SE.puts "            #{myself_name} --find_date_option_H '{ :default_century_pivot_ccyymmdd => \"20\" }' file"
        exit
    end
end.parse!  # Bang because ARGV is altered
self.cmdln_option_H[ :max_group_levels ] += -1                   # :max_group_levels is zero relative.
self.cmdln_option_H[ :max_group_levels ]  =  1 if ( self.cmdln_option_H[ :max_group_levels ] < 1 )
SE.q {'self.cmdln_option_H'}

self.output_fd3_F = File::open( '/dev/fd/3', mode='w' )
ObjectSpace.each_object(IO) { |f| SE.q { ['f.fileno','f'] } unless f.closed? }
self.aspace_O = ASpace.new
self.aspace_O.date_expression_format    = 'mmmddyyyy'
self.aspace_O.date_expression_separator = ' - '

self.states_A = [ 'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming', 'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick', 'Newfoundland and Labrador', 'Nova Scotia', 'Ontario', 'Prince Edward Island', 'Quebec', 'Saskatchewan', 'Northwest Territories', 'Nunavut', 'Yukon' ]       
stringer = self.states_A.join('|')
self.states_RES = "^\s*(#{stringer})( |[[:punct:]]|$)"
self.states_RE  = /#{self.states_RES}/

phrase_split_chars_A = self.cmdln_option_H[ :phrase_split_chars ].chars
phrase_split_chars_RE = /([#{self.cmdln_option_H[ :phrase_split_chars ]}])/

marker_of_begining_of_record_before_prepend = '~~BOR~~'
self.auto_group_H = { :text => '', :cnt => 0 }
shelf_id_O = nil 

self.find_dates_with_4digit_years_O = Find_Dates_in_String.new( { :morality_replace_option => { :good  => :remove_from_end },
                                                                  :pattern_name_RES => '.',
                                                                  :date_string_composition => :dates_in_text,
                                                                  :yyyymmdd_min_value => '1800',
                                                                }.merge( self.cmdln_option_H[ :find_dates_option_H ] ) )

self.find_dates_with_2digit_years_O = Find_Dates_in_String.new( { :morality_replace_option => { :good  => :keep },
                                                                  :pattern_name_RES => '.',
                                                                  :date_string_composition => :dates_in_text,
                                                                  :default_century_pivot_ccyymmdd => '1900',
                                                                }.merge( self.cmdln_option_H[ :find_dates_option_H ] ) )  \
                                                                if ( self.cmdln_option_H[ :default_century_pivot_ccyymmdd ].empty? )
                                                            
self.min_date = ''
self.max_date = ''
self.note_cnt = 0
self.box_cnt = 0
self.pending_output_record_H = {}
self.prepend_A = []
previous_prepend_A_pop_A = ''

ARGF.each_line do |input_record|
    begin
        if ( self.cmdln_option_H[ :r ] and $. > self.cmdln_option_H[ :r ] ) then 
            break
        end

        input_record.chomp!            
        if ( input_record.gsub( '_', '' ).blank? ) then  # A record with all '_' should be skipped.
            next
        end
        if ( input_record.sub( /#.*$/, '').blank? ) then
          # SE.puts "#{SE.lineno}: Warning: Comment record skipped '#{input_record}'"
            next
        end
        if ( input_record.match?( /~~/ ) ) then
            SE.puts "#{SE.lineno}: Found '~~' in input_record, '~~' are used for program logic."
            SE.q {[ 'input_record' ]}
            raise
        end
        if ( input_record.count( '"' ) % 2 != 0 ) then
            SE.puts "#{SE.lineno}: WARNING: Odd number of double-quotes found in '#{input_record}'"
        end
        if ( input_record.match?( /^#{K.fmtr_shelf_box}/i ) ) then
            shelf_id_O = Shelf_ID_for_boxes.new.setup( input_record )                                            
            next
        end
  
        original_input_record = input_record + ''     # + "" <<< gotta change it or it's just a reference.
        
        leading_space_cnt = original_input_record[/\A */].size
        if ( leading_space_cnt % 4 != 0 ) then
            SE.puts "#{SE.lineno}: Number of leading spaces not MOD 4"
            SE.q {'input_record'}
            raise
        end
        indent_level_based_on_text_indentation = leading_space_cnt / 4
 
        input_record.strip!
        input_record.gsub!( '...', '…' )     
        input_record.gsub!( '—', '-' )              # Those dashes are subtly different! Do:  echo '-—–' | od -ctx1
        input_record.gsub!( '–', '-' )              # This one is one-dot shorter than the one above.   
        input_record.tr!( '’“”', '\'""' )
        input_record.gsub!( /\s\s+/, ' ' )    
        input_record.gsub!( /\s*$/, '' )   
        input_record.strip!       
     
    #   The prepend/drop records have the following format/pattern:
    #       prepend[.:] string   
    #           The is pushed onto the stack and then inserted in front of the following records
    #
    #       drop[.:] [number]
    #           Where 'number' if present is checked against the current value of 'self.prepend_A.maxindex'
    # #
    #   The K.fmtr_indent records have the following format:
    #       K.fmtr_indent K.fmtr_right|K.fmtr_left
        
        command_line_split_on_RE = /(\s+|:|\.|,)/
        command_line_split_A = input_record.split( command_line_split_on_RE ).map( &:to_s ).reject( &:empty? )
        command_line_split_A.shift if ( command_line_split_A.first.blank? )
        command = command_line_split_A.shift
        loop do
            break if ( command_line_split_A.empty? )
            if ( command_line_split_A.first.match?( command_line_split_on_RE ) ) then
                command_line_split_A.shift
            else
                break
            end
        end
        case true
        when command.downcase.in?( K.fmtr_indent.downcase, K.fmtr_end_group.downcase )
            self.output_fd3_F.puts input_record.strip
            if ( self.pending_output_record_H.empty? ) then
                SE.puts "#{SE.lineno}: Got a '#{K.fmtr_indent}' record but self.pending_output_record_H is empty."
                SE.q { 'input_record' }
                raise
            end
            
            if ( command.downcase == K.fmtr_end_group.downcase ) then
                if ( self.prepend_A.empty? ) then
                    SE.puts "#{SE.lineno}: Got an __END_GROUP__ record but self.prepend_A is empty."
                    SE.q {[ 'input_record' ]}
                    SE.q {[ 'self.prepend_A' ]}
                    raise
                end
                indent_direction = K.fmtr_left
                previous_prepend_A_pop_A = self.prepend_A.pop
                if ( previous_prepend_A_pop_A[ 2 ] != :group ) then
                    SE.puts "#{SE.lineno}: Got a '#{command}' record but non-group record was popped '#{previous_prepend_A_pop_A}'"
                    SE.q {'self.prepend_A'}
                    SE.q { 'input_record' }
                    raise               
                end
                if ( indent_level_based_on_text_indentation != self.prepend_A.length ) then
                    SE.puts "#{SE.lineno}: Got a '#{command}' record but the text indentation doesn't match the prepend_A.length."
                    SE.q {'original_input_record'}
                    SE.q {'indent_level_based_on_text_indentation'}
                    SE.q {'self.prepend_A'}
                    raise
                end
                set_text_for_auto_group_F( '' )
            else
                if ( command_line_split_A.first.downcase.in?( K.fmtr_left.downcase, K.fmtr_right.downcase ) ) then
                    indent_direction = command_line_split_A.first                    
                else
                    SE.puts "#{SE.lineno}: Got a '#{K.fmtr_indent}' record with an invalid direction '#{command_line_split_A.first}'."
                    SE.q { 'input_record' }
                    raise    
                end
            end
            pending_forced_indent_A = self.pending_output_record_H[ K.fmtr_forced_indent ]
            if ( pending_forced_indent_A.is_a?( Array ) ) then 
                case true
                when ( pending_forced_indent_A.empty? or pending_forced_indent_A.first == indent_direction )  
                    self.pending_output_record_H[ K.fmtr_forced_indent ].push( indent_direction )
                    set_text_for_auto_group_F( '' )
                when ( indent_direction = K.fmtr_left and pending_forced_indent_A.first == K.fmtr_right )
                    self.pending_output_record_H[ K.fmtr_forced_indent ].pop
#                   SE.q {['self.pending_output_record_H[ K.fmtr_forced_indent ]']}
                    #   This handles a group record without detail.
                else
                    SE.puts "#{SE.lineno}: FALSE: pending_forced_indent_A.is_a?( Array ) and ( pending_forced_indent_A.empty? or pending_forced_indent_A.first.downcase == indent_direction.downcase )"
                    SE.q {[ 'indent_direction' ]}
                    SE.q {[ 'pending_forced_indent_A' ]}
                    SE.q {[ 'self.pending_output_record_H' ]}
                    raise
                end
            end

            SE.q {[ 'self.pending_output_record_H' ]}  if ( $DEBUG )
            next 
            
        when command.downcase.in?( K.fmtr_prepend.downcase, K.fmtr_prefix.downcase )
            self.output_fd3_F.puts input_record
            if ( command_line_split_A.length == 0 ) then
                SE.puts "#{SE.lineno}: Got a 'prepend/prefix' record without a phrase:"
                SE.q { 'input_record' }
                raise
            end
            if ( input_record.match?( / note:/i ) ) then
                SE.puts "#{SE.lineno}: Got a 'prepend/prefix' record with a note:"
                SE.q { 'input_record' }
                raise
            end
            stringer = command_line_split_A.join( '' ).strip
            stringer.sub!( /[,.:;]$/, '' )
            stringer += '.'
            
            if ( indent_level_based_on_text_indentation != self.prepend_A.length ) then
                SE.puts "#{SE.lineno}: Got a '#{command}' record but the text indentation doesn't match the prepend_A.length."
                SE.q {'original_input_record'}
                SE.q {'indent_level_based_on_text_indentation'}
                SE.q {'self.prepend_A'}
                raise
            end
            self.prepend_A.push( [ stringer, :indent_keys, :prefix, $., SE.lineno ] )
            if ( self.prepend_A.maxdepth != 2 ) then
                SE.puts "#{SE.lineno}: self.prepend_A has a maxdepth != 2"
                SE.q {[ 'input_record', 'self.prepend_A' ]}
                raise
            end 
            set_text_for_auto_group_F( '' )
            next
            
        when command.downcase == K.fmtr_drop.downcase
            self.output_fd3_F.puts input_record.strip
            if ( self.prepend_A.length == 0 ) then
                SE.puts "#{SE.lineno}: Got a 'drop' record but there are no entries in self.prepend_A."
                SE.q { 'input_record' }
                raise
            end
            arr = command_line_split_A.reject{ | e | e.match?( command_line_split_on_RE ) }
            if ( arr.maxindex == 0 and arr[ 0 ].integer? ) then
                drop_nbr = arr[ 0 ].to_i
                if ( self.prepend_A.maxindex != drop_nbr ) then
                    SE.puts "#{SE.lineno}: Got a 'drop' record with the number '#{drop_nbr}', " +
                            "but it's not equal to the self.prepend_A.maxindex value '#{self.prepend_A.maxindex}'"
                    SE.q {'self.prepend_A'}
                    SE.q { 'input_record' }
                    raise
                end
            elsif ( arr.not_empty? ) then
                SE.puts 'FALSE: arr.maxindex == 0 and arr[ 0 ].integer? '
                SE.q {'arr'}
                SE.q { 'input_record' }
                raise
            end
            previous_prepend_A_pop_A = self.prepend_A.pop            
            if ( previous_prepend_A_pop_A[ 2 ] == :group ) then
                SE.puts "#{SE.lineno}: Got a 'drop' record but a Group record was popped '#{previous_prepend_A_pop_A}'"
                SE.q {'self.prepend_A'}
                SE.q { 'input_record' }
                raise               
            end
            if ( indent_level_based_on_text_indentation != self.prepend_A.length ) then
                SE.puts "#{SE.lineno}: Got a '#{command}' record but the text indentation doesn't match the prepend_A.length."
                SE.q {'original_input_record'}
                SE.q {'indent_level_based_on_text_indentation'}
                SE.q {'self.prepend_A'}
                raise
            end
            set_text_for_auto_group_F( '' )
            next
        end

        if ( input_record.match?( /^\s*_/ ) ) then
            SE.puts "#{SE.lineno}: Found an input record that begins with a underscore. This is probably wrong."
            SE.q {[ 'input_record' ]}
            raise
        end

        if ( indent_level_based_on_text_indentation != self.prepend_A.length ) then
            SE.puts "#{SE.lineno}: The text indentation doesn't match the prepend_A.length."
            SE.q {'original_input_record'}
            SE.q {'indent_level_based_on_text_indentation'}
            SE.q {'self.prepend_A'}
            raise
        end
#                      prepend_A is needs here in case a 'Box' is prepended.  
        input_record = get_prepend_elements_for_indent_keys_F_A.join( ' ' ) + 
                 ' ' + marker_of_begining_of_record_before_prepend + 
                 ' ' + input_record      
     
        input_record, note_A = scrape_off_notes( input_record)    
         
#               THIS IS TOO DANGEROUS TO DO PROGRAMMATICALLY.  
#               They are only on the 'Record Group and Series Records anyway.
#       regexp = /\s+[0-9]+\s+(boxes |box |volume ).*/i
#       m_O = input_record.match( regexp ) 
#       if ( m_O.not_nil? ) then
#           input_record.sub!( regexp, '' )
#           input_record.strip!
#           note_A.push( "{#{K.dimensions}}: #{m_O[ 0 ].strip}" )
#       end
                        
        input_record, from_thru_date_H_A = scrape_off_dates( input_record )

        input_record, container_H_A = scrape_off_container( input_record, shelf_id_O, from_thru_date_H_A )  

        if ( matchdata_O = input_record.match( /(\A|\s+)(box|boxes|folders?|oversized?|volume\s+[0-9])(\s+|\Z)/i )) then
            SE.puts ''
            SE.puts "#{SE.lineno}:WARNING: Found some additional container words '#{matchdata_O}' in: '#{input_record}'"
            SE.puts ''
        end
        
        loop do
            stringer = input_record + ''
            break if ( not input_record.sub!( /^\s*(\[.*?\])/, '') )    # Remove brackets from the begining of the text
            input_record += ' ' + $&                                    # and move them to the end.
            input_record.strip!
            break if ( input_record == stringer )        
        end
            

        output_record_H = {}
        output_record_H[ K.fmtr_record_sort_keys ] = ''         # This is
        output_record_H[ K.fmtr_record_indent_keys ] = []       # to establish
        output_record_H[ K.fmtr_forced_indent ] = []            # the order        
        record_values_A = [ ]  # This goes inside the output_record_H
     
        regexp = /#{marker_of_begining_of_record_before_prepend}\s*#{K.any_fmtr_group_record_RES}[: ]/i
        group_match_O = input_record.match( regexp )

        if ( group_match_O ) then
            match_record_type = group_match_O[ 1 ].downcase
            output_record = ''
            case true
            when ( match_record_type == K.series )
                as_record_type = K.series
                output_record  += K.series.sub( /./,&:upcase ) + ' ' + group_match_O.post_match
            when ( match_record_type.in?( [ K.subseries, K.sub_series_text.downcase ] ) )
                as_record_type = K.subseries
                output_record  += K.sub_series_text + ' ' + group_match_O.post_match
            when ( match_record_type.in?( [ K.recordgrp, K.recordgrp_text.downcase ] ) )
                as_record_type = K.recordgrp    
                output_record  += K.recordgrp_text + ' ' + group_match_O.post_match           
            when ( match_record_type == K.group )
                as_record_type = K.otherlevel
                output_record  += group_match_O.post_match.strip
            else
                SE.puts "#{SE.lineno}: Unknown record_type '#{group_match_A[ 0 ].downcase}'"
                SE.q {[ 'input_record', 'self.prepend_A' ]}
                raise
            end
            
            # if  ( as_record_type.in?( [ K.series, K.recordgrp ] ) and self.prepend_A.not_empty? ) then
                # SE.puts "#{SE.lineno}: Got a '#{as_record_type}' record but self.prepend_A is not empty"
                # SE.q {[ 'input_record', 'self.prepend_A' ]}
                # raise
            # end
            if  ( as_record_type.in?( [ K.subseries ] ) and self.prepend_A.empty? ) then
                SE.puts "#{SE.lineno}: Got a '#{as_record_type}' record but self.prepend_A is empty"
                SE.q {[ 'input_record', 'self.prepend_A' ]}
                raise
            end
            if ( indent_level_based_on_text_indentation != self.prepend_A.length ) then
                SE.puts "#{SE.lineno}: Got a '#{command}' record but the text indentation doesn't match the prepend_A.length."
                SE.q {'original_input_record'}
                SE.q {'indent_level_based_on_text_indentation'}
                SE.q {'self.prepend_A'}
                raise
            end
            
            self.prepend_A.push( [ output_record, :sort, :group, $., SE.lineno ] )
            if ( self.prepend_A.maxdepth != 2 ) then
                SE.puts "#{SE.lineno}: self.prepend_A has a maxdepth != 2"
                SE.q {[ 'input_record', 'self.prepend_A' ]}
                raise
            end 
            set_text_for_auto_group_F( '' )            
            record_values_A[ K.fmtr_record_values__text_idx ] = output_record.strip            
            output_record_H[ K.level ] = as_record_type    
            output_record_H[ K.fmtr_record_sort_keys ] = get_prepend_elements_for_sort_F_A.join( '   ' ).downcase.gsub( /[^[a-z0-9,\- ]]/,'' )  + '   '
            output_record_H[ K.fmtr_record_indent_keys ] = get_prepend_elements_for_indent_keys_F_A
            output_record_H[ K.fmtr_forced_indent ].push( K.fmtr_right )
        else
            regexp = /^.*#{marker_of_begining_of_record_before_prepend}/
            input_record.sub!( regexp, '' )
            input_record.strip!
            # record_text_blank = false
            # if ( input_record.blank? ) then      
                # record_text_blank = true
                # # if ( from_thru_date_H_A.not_empty? ) then 
                    # # input_record += '[By date]'
                # # end
            # end         
            SE.q {['input_record']}   if ( $DEBUG )            
            phrase_A = [ ]
            previous_phrase_was_a_right_facing_word_magnet = nil
            current_phrase_is_a_left_facing_comma_magnet = nil
            arr1 = input_record.split( phrase_split_chars_RE ).map( &:to_s )  # The array will contain the BLANKS!!!
            arr1.each_with_index do | phrase, idx |
                SE.q {[ 'phrase' ]}   if ( $DEBUG )
                if ( phrase_A.not_empty? ) then
                    if ( phrase.in?( phrase_split_chars_A ) ) then
                        phrase_A[ -1 ] += phrase
                        next
                    end
                    
                    current_phrase_is_a_left_facing_comma_magnet = nil
                    if ( phrase_A[ -1 ].match?( /,\s*$/ ) ) then
                        m_O = phrase.match( /\s+(Jr|Inc)$/ )   
                        m_O = phrase.match( /^\s*([a-z])/ )                                 if ( m_O.nil? )  
                        m_O = phrase.match( self.states_RE )                                if ( m_O.nil? )
                        if ( m_O.nil? ) then 
                            arr1[ idx .. [ idx + 2, arr1.maxindex ].min ].each do | e |
                                m_O = e.match( /(Railroad|Railway)\s*$/ ) 
                                if ( m_O ) then
                                    current_phrase_is_a_left_facing_comma_magnet = m_O[ 0 ]
                                    break
                                end
                            end                   
                        else
                            current_phrase_is_a_left_facing_comma_magnet = m_O[ 0 ]
                        end
                    end
                    SE.q {[ 'previous_phrase_was_a_right_facing_word_magnet','current_phrase_is_a_left_facing_comma_magnet' ]}  if ( $DEBUG )

                    case true
                    when ( phrase_A[ -1 ].match?( /[0-9]\.$/ ) and phrase.match?( /^[0-9]/ ) ) 
                        phrase_A[ -1 ] += "#{phrase}"
                    when ( previous_phrase_was_a_right_facing_word_magnet.not_nil? ) 
                        phrase_A[ -1 ] += "#{phrase}"
                    when ( current_phrase_is_a_left_facing_comma_magnet.not_nil? )
                        phrase_A[ -1 ] += "#{phrase}"
                    else
                        phrase_A << phrase
                    end
                else
                    phrase_A << phrase
                end
                if ( phrase.length < K.min_length_for_indent_key ) then
                    previous_phrase_was_a_right_facing_word_magnet = "*** length check: #{phrase.length} < #{K.min_length_for_indent_key} ***"
                else
                    phrase.match( /(^|[[:punct:]]| )(dr|mr|mrs|ms|miss|no|num|nbr|nos|vs|al|st|co|ca|for)$/i ) 
                    phrase.match( /(^|[[:punct:]]| )(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)$/i ) if ( $~.nil? )
                    phrase.match( /(^|[[:punct:]]| )([A-Z]|[0-9]+)$/ )                                     if ( $~.nil? )
                    phrase.match( /(^|[[:punct:]])"/ )                                                     if ( $~.nil? )
                    previous_phrase_was_a_right_facing_word_magnet = $&
                end
                SE.q {[ 'phrase_A' ]}   if ( $DEBUG )
            end

            if ( phrase_A.maxdepth > 1 ) then
                SE.puts "#{SE.lineno}: phrase_A has a maxdepth > 1"
                SE.q {[ 'original_input_record', 'phrase_A' ]}
                raise
            end   
 
            # if  ( phrase_A.not_empty? and phrase_A.last == '[By date]' ) then
            if ( input_record.blank? ) then
                if ( self.auto_group_H[ :text ].not_blank? ) then
                    phrase_A.unshift( self.auto_group_H[ :text ] )
                    self.auto_group_H[ :cnt ] += 1
                end
            end

            indent_keys_A = [ ] 
            loop do
                break if ( phrase_A.empty? )
                break if ( indent_keys_A.maxindex >= self.cmdln_option_H[ :max_group_levels ] )
                phrase = phrase_A[ 0 ].strip
                break if ( phrase[ 0 ] == '[' )
                indent_keys_A.push( phrase )
                phrase_A.shift( 1 )
            end     
            output_record_H[ K.fmtr_record_indent_keys ] = get_prepend_elements_for_indent_keys_F_A + indent_keys_A  
            
            arr1_A = [ ]
            loop do
                break if ( phrase_A.empty? )
                phrase = phrase_A.shift( 1 )[ 0 ].strip   # pop/shift with an argument returns an array, [0] says return the 1st element
                arr1_A.push( phrase )
            end
            title = arr1_A.join( ' ' )
            record_values_A[ K.fmtr_record_values__text_idx ] = title                                                   
            if ( title.length > self.cmdln_option_H[ :max_title_size ] ) then
                SE.puts "#{SE.lineno}: Warning: Title size #{title.length} '#{title}'"
                SE.puts ''
            end

            output_record_H[ K.level ] = K.file                  
#           If the input_record has text AND there are no notes, container, or dates, assume this is an "auto-group" 
#           record; and IF any following records have NO text use this record's text.
            if ( note_A.empty? and from_thru_date_H_A.empty? and container_H_A.empty? and indent_keys_A.not_empty? ) then   
                 set_text_for_auto_group_F( indent_keys_A.last )
                 output_record_H[ K.level ] = K.fmtr_auto_group
            else
                if ( input_record.not_blank? ) then
                    set_text_for_auto_group_F( '' )
                end
            end
            
        #       The sort keys are at the front of the record so the Unix 'sort' command works.   

            output_record_H[ K.fmtr_record_sort_keys ] = (   get_prepend_elements_for_sort_F_A + 
                                                             indent_keys_A +
                                                             [ title ] +
                                                             from_thru_date_H_A.map{ | e | e[ K.begin ]}  
                                                           ).join( '   ' ).downcase.gsub( /[^[a-z0-9,\- ]]/,'' )  + '   '
        end
        
        record_values_A[ K.fmtr_record_values__dates_idx ] = from_thru_date_H_A     
        record_values_A[ K.fmtr_record_values__notes_idx ] = note_A                 
        record_values_A[ K.fmtr_record_values__container_idx ] = container_H_A
        self.box_cnt += container_H_A.length
          
        output_record_H[ K.fmtr_record_values ]      = record_values_A
        output_record_H[ K.fmtr_record_num ]         = "#{$.}"
        output_record_H[ K.fmtr_record_original ]    = original_input_record

        SE.q {[ 'output_record_H' ]}  if ( $DEBUG )
        write_pending_record_H( output_record_H )   
    rescue
        SE.puts ''
        SE.puts 'rescue ==================================================================='
        SE.puts "#{SE.lineno}: Original input_record:  '#{original_input_record}'"
        SE.puts "#{SE.lineno}: As currently modified:  '#{input_record}'"
      # SE.puts "#{SE.lineno}: previous_prepend_A_pop_A: '#{previous_prepend_A_pop_A}'"
      # SE.q {['self.prepend_A']}
        SE.puts 'rescue ==================================================================='
        SE.puts ''
        raise
    end
end
write_pending_record_H( {} )
if ( self.prepend_A.length > 0 ) then
    SE.puts ''
    SE.puts ''
    SE.puts "#{SE.lineno}: ERROR! self.prepend_A not empty.  Missing drop record."
    SE.q { 'self.prepend_A' }
    SE.puts ''
    raise
end

SE.puts '======================================================================='
SE.puts "Minimum date:  #{self.min_date}"
SE.puts "Maxmimum date: #{self.max_date}"
SE.puts "Notes created: #{self.note_cnt}"
SE.puts "Boxes:         #{self.box_cnt}"
SE.puts 'Count of date patterns found:'
SE.puts self.find_dates_with_4digit_years_O.pattern_cnt_H.ai
SE.puts ''




#p stack_of_recs
