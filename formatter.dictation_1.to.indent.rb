require 'Date'
require 'json'
require 'pp'
require 'awesome_print'
require 'optparse'

require 'class.Hash.extend.rb'
require 'class.Array.extend.rb'
require 'class.Object.extend.rb'
require 'class.String.extend.rb'
require 'class.Find_Dates_in_String.rb'
require 'class.formatter.Shelf_ID_for_Boxes.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'

module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :cmdln_option_H, :find_dates_with_4digit_years_O, :find_dates_with_2digit_years_O,
                      :min_date, :max_date, :note_cnt, :pending_output_record_H
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

myself_name = File.basename( $0 )

self.cmdln_option_H = { :max_levels => 5,
                        :r => nil,
                        :find_dates_option_H => { },
                        :default_century => '',
                        :do_2digit_year_test => false,
                        :max_title_size => 250
                     }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"
    option.on( "-l n", "--max-levels n", OptionParser::DecimalInteger, "Max number of group levels (default 5)" ) do |opt_arg|
        self.cmdln_option_H[ :max_levels ] = opt_arg
    end
    option.on( "--max-title-size n", OptionParser::DecimalInteger, "Warn if title-size over n" ) do |opt_arg|
        self.cmdln_option_H[ :max_title_size ] = opt_arg
    end
    option.on( "--default_century n", OptionParser::DecimalInteger, "Default century for 2-digit years." ) do |opt_arg|
        self.cmdln_option_H[ :default_century ] = opt_arg
    end  
    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        self.cmdln_option_H[ :r ] = opt_arg
    end
    option.on( "--do_2digit_year_test", "When the --default_century option is '', warn if 2digit years found." ) do |opt_arg|
        self.cmdln_option_H[ :do_2digit_year_test ] = true
    end
    option.on( "--find_dates_option_H x", "Option Hash passed to the Find_Dates_in_String class." ) do |opt_arg|
        begin
            self.cmdln_option_H[ :find_dates_option_H ] = eval( opt_arg )
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
        SE.puts "Note that:  The --find_dates_option_H numeric values have to be quoted (no integers), eg."
        SE.puts "            #{myself_name} --find_date_option_H '{ :default_century => \"20\" }' file"
        exit
    end
end.parse!  # Bang because ARGV is altered
self.cmdln_option_H[ :max_levels ] -= 1                   # :max_levels is zero relative.
self.cmdln_option_H[ :max_levels ] = 1 if ( self.cmdln_option_H[ :max_levels ] < 1 )


self.find_dates_with_4digit_years_O = Find_Dates_in_String.new( { :morality_replace_option => { :good  => :remove_from_end },
                                                                  :pattern_name_RES => '.',
                                                                  :date_string_composition => :dates_in_text,
                                                                  :yyyy_min_value => '1800',
                                                                }.merge( self.cmdln_option_H[ :find_dates_option_H ] ) )

self.find_dates_with_2digit_years_O = Find_Dates_in_String.new( { :morality_replace_option => { :good  => :keep },
                                                                  :pattern_name_RES => '.',
                                                                  :date_string_composition => :dates_in_text,
                                                                  :default_century => '1900',
                                                                }.merge( self.cmdln_option_H[ :find_dates_option_H ] ) )  \
                                                                if ( self.cmdln_option_H[ :default_century ].empty? )
                                                            
self.min_date = ""
self.max_date = ""
self.note_cnt = 0
self.pending_output_record_H = {}
prepend_A = []
group_sort_text_A = []      # This is for the series, subseries, and recordgrp stuff.

def scrape_off_container!( input_record, shelf_id )
    container_H = K.fmtr_empty_container_H
    regexp = K.box_and_folder_RE
    if ( instance_matchdata_O = input_record.match( regexp ) ) then
        input_record.sub!( regexp, '' )
        box_num = instance_matchdata_O[ :box_num ]
        box_num = box_num.gsub( 'and', ',' ).gsub( /box(s|es)?/, ' ' ).gsub( /\s+and\s+/i, ',').gsub( /,,+/, ',' ).gsub( /\s+,/, ',').sub( /[,.]$/, '' ).strip
        container_H[ K.shelf ]          = shelf_id.of_box( box_num ) if ( shelf_id ) 
        container_H[ K.type ]           = K.box
        container_H[ K.indicator ]      = box_num
        if ( instance_matchdata_O[ :box_type ].not_nil? ) then           
            case true
            when instance_matchdata_O[ :box_type ].match( /over/i ).not_nil?      # .match doesn't return true/false !!!
                container_H[ K.indicator ] += ' OV'
            when instance_matchdata_O[ :box_type ].match( /slide/i ).not_nil?
                container_H[ K.indicator ] += ' SB'
            when instance_matchdata_O[ :box_type ].match( /record/i ).not_nil?
                container_H[ K.indicator ] += ' RC'
            else
                container_H[ K.indicator ] += " #{instance_matchdata_O[ :box_type ]}"
            end
        end
        if ( instance_matchdata_O[ :folder_num ].not_nil? ) then
            folder_num = instance_matchdata_O[ :folder_num ]
            folder_num = folder_num.gsub( 'and', ',' ).gsub( /folders?/, ' ' ).gsub( /\s+and\s+/i, ',').gsub( /,,+/, ',' ).gsub( /\s+,/, ',').sub( /[,.]$/, '' ).strip
            container_H[ K.type_2 ]      = K.folder
            container_H[ K.indicator_2 ] = folder_num
        end            
        SE.q {[ 'saved_input_record' ]}  if ( $DEBUG )
        SE.q {[ 'container_H' ]}  if ( $DEBUG )
    end
    if ( matchdata_O = input_record.match( /(\A|\s+)(box|folder|oversided?|slides?)(\s+|\Z)/i )) then
        SE.puts ""
        SE.puts "#{SE.lineno}:WARNING: Found some additional 'box', 'folder', 'oversize', 'slide' words: '#{input_record}'"
        SE.puts "#{matchdata_O}"
        SE.puts ""
    end
    return container_H
end

def scrape_off_notes( input_record )
    note_A = [ ]
    input_record_note_A = input_record.split( /\s+(note:|notes:)\s*/i ).map( &:to_s ).map( &:strip )
    if ( input_record_note_A.maxindex > 0) then
        input_record = input_record_note_A.shift( 1 )[ 0 ]   # input_record with the NOTES removed.
        input_record_note_A.each do | note |
            next if ( note =~ /\A(note:|notes:)\s*\Z/i ) 
            next if ( note =~ /\A\s*\Z/i ) 
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
    from_thru_date_A_A = [ ]
    input_record = self.find_dates_with_4digit_years_O.do_find( input_record )
    self.find_dates_with_4digit_years_O.good__date_clump_S__A.each do | date_clump_S |
        from_thru_date_A = [ ]
        from_thru_date_A << date_clump_S.from_date
        if ( self.min_date == "" or self.min_date > date_clump_S.from_date ) then
            self.min_date = date_clump_S.from_date
        end
        if ( self.max_date == "" or self.max_date < date_clump_S.from_date ) then
            self.max_date = date_clump_S.from_date
        end
        if ( date_clump_S.thru_date.not_blank? ) then
            from_thru_date_A << date_clump_S.thru_date 
            if ( self.min_date == "" or self.min_date > date_clump_S.thru_date ) then
                self.min_date = date_clump_S.thru_date
            end
            if ( self.max_date == "" or self.max_date < date_clump_S.thru_date ) then
                self.max_date = date_clump_S.thru_date
            end
        end
        from_thru_date_A_A << from_thru_date_A
    end
    if ( self.cmdln_option_H[ :default_century ].empty? and self.cmdln_option_H[ :do_2digit_year_test ] ) then
        self.find_dates_with_2digit_years_O.do_find( input_record )
        self.find_dates_with_2digit_years_O.good__date_clump_S__A.each do | date_clump_S |  
            len = self.find_dates_with_2digit_years_O.good__date_clump_S__A.length
            from_thru_date= date_clump_S.from_date
            if ( date_clump_S.thru_date.not_blank? ) then
                from_thru_date += ' - ' + date_clump_S.thru_date 
            end
            SE.puts "#{SE.lineno}: WARNING: #{len} date(s) with 2-digit-years(#{from_thru_date}) found in record:'#{input_record}'"
            SE.puts ""
            break
        end
    end
    return input_record, from_thru_date_A_A
end

def write_pending_record_H( next_output_record_H )
    if ( self.pending_output_record_H.not_empty? ) then
        output_record_J = self.pending_output_record_H.to_json
        if ( output_record_J.match( /~~/ )) then
            SE.puts "#{SE.lineno}: Found '~~' in output_record_J, '~~' are used for program logic so probably shouldn't be here!"
            SE.q {[ 'output_record_J' ]}
            raise
        end
        puts output_record_J
    end
    self.pending_output_record_H = next_output_record_H.merge( {} )
end

def change__SpecificThing_period__to__tildy_SpecificThing_tildy( stringer )
        # Periods are used for indentation logic, 
        # so change all single capital letter dot patterns, as following:  R.R.  Mr. Bozo T. Clown to
        # ~~R~~~~R~~  ~~Mr~~ Bozo ~~T~~ Clown, so the initials don't count for grouping.

    while true
        changed = false
        changed = true  if ( stringer.sub!( /(\A|\s+|~~|")([A-Z])\.([A-Z]\.|"|\s+|\Z)/, '\1~~\2~~\3' ) ) 
        changed = true  if ( stringer.sub!( /(\A|\s+|~~|")(Dr|Mr|Mrs|Ms|Miss|No)\.("|\s+|\Z)/i, '\1~~\2~~\3' ) )         
        break if ( not changed )
    end
    return stringer
end
def change__tildy_SpecificThing_tildy__to__SpecificThing_period( stringer )
    while true
        break if ( not stringer.sub!( /~~(.+?)~~/, '\1.' ) )
    end
    return stringer
end

shelf_id = nil 
ARGF.each_line do |input_record|

    if ( self.cmdln_option_H[ :r ] and $. > self.cmdln_option_H[ :r ] ) then 
        break
    end

    input_record.chomp!
    if ( input_record.match?( /^\s*$/ ) ) then
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
        shelf_id = Shelf_ID_for_boxes.new.setup( input_record )                                            
        next
    end
      
    saved_input_record = input_record + ''     # + "" <<< gotta change it or it's just a reference.
   
#   The prepend/drop records have the following format/pattern:
#       prepend[.:] set-of-word(s)   
#           Each set of word is pushed onto the stack and then inserted in front of the following records
#
#       drop[.:] 
# #
#   The K.fmtr_indent records have the following format:
#       K.fmtr_indent K.fmtr_right|K.fmtr_left
    
    input_record_word_A = input_record.split( /\s+|:/ ).map( &:to_s ).map( &:strip ).reject( &:blank? )
    command = input_record_word_A.shift.sub( /[\.:]\s*\Z/, '' )

    case true
    when command.downcase.in?( K.fmtr_indent.downcase, K.fmtr_end_group.downcase )
        if ( self.pending_output_record_H.empty? ) then
            SE.puts "#{SE.lineno}: Got a '#{K.fmtr_indent}' record but self.pending_output_record_H is empty."
            SE.q { 'input_record' }
            raise
        end

        case command.downcase
        when K.fmtr_end_group.downcase 
            if ( group_sort_text_A.empty? ) then
                SE.puts "#{SE.lineno}: Got an __END_GROUP__ record but group_sort_text_A is empty."
                SE.q {[ 'input_record' ]}
                SE.q {[ 'group_sort_text_A' ]}
                raise
            end
            indent_direction = K.fmtr_left
            group_sort_text_A.pop
        else
            if ( input_record_word_A.first.downcase.in?( K.fmtr_left.downcase, K.fmtr_right.downcase ) ) then
                indent_direction = input_record_word_A.first                    
            else
                SE.puts "#{SE.lineno}: Got a '#{K.fmtr_indent}' record an invalid direction '#{input_record_word_A.first}'."
                SE.q { 'input_record' }
                raise    
            end
        end
        arr1_A = self.pending_output_record_H[ K.fmtr_forced_indent ]
        if ( arr1_A.is_a?( Array ) and ( arr1_A.empty? or arr1_A.first.downcase == indent_direction.downcase ) ) then
            self.pending_output_record_H[ K.fmtr_forced_indent ].push( indent_direction )
        else
            SE.puts "#{SE.lineno}: NOT: arr1_A.is_a?( Array ) and ( arr1_A.empty? or arr1_A.first == input_record_word_A[ 0 ] )"
            SE.q { [ 'input_record_word_A[ 0 ]', 'arr1_A' ] }
            raise
        end

        SE.q {[ 'self.pending_output_record_H' ]}  if ( $DEBUG )
        next 
        
    when command.downcase.in?( K.fmtr_prepend.downcase, K.fmtr_prefix.downcase )
        if ( input_record_word_A.length == 0 ) then
            SE.puts "#{SE.lineno}: Got a 'prepend/prefix' record without a phrase:"
            SE.q { 'input_record' }
            raise
        end
        stringer = input_record_word_A.join( ' ' )
        stringer.sub!( /\s*[:.,]\s*$/, '')
        prepend_A.push( stringer + '.' )
        next
        
    when command.downcase == K.fmtr_drop.downcase
        if ( prepend_A.length == 0 ) then
            SE.puts "#{SE.lineno}: Got a 'drop' record but there are no entries in prepend_A."
            SE.q { 'input_record' }
            raise
        end
        prepend_A.pop
        next
    end

    if ( input_record.match?( /^\s*_/ ) ) then
        SE.puts "#{SE.lineno}: Found an input record that begins with a underscore. This is probably wrong."
        SE.q {[ 'input_record' ]}
        raise
    end
    
    input_record.gsub!( '...', '…' )       
    input_record.gsub!( /\s\s+/, ' ' )    
    
    input_record = prepend_A.join( '. ' ) + ' ' + input_record      # Prepend_A should be empty for group-records (see below)
                                                                    # but needs to here in case a 'Box' is prepended.  
    
    input_record, note_A = scrape_off_notes( input_record)
    container_H = scrape_off_container!( input_record, shelf_id )   
    input_record, from_thru_date_A_A = scrape_off_dates( input_record )
        
    input_record.gsub!( /\s*,\s*,/, '')     # Multiple dates 
    input_record.gsub!( /\s*,\s*$/, '')     # leave extra commas.
    input_record.sub!( /\s*\.\Z/, '' )
    input_record.gsub!( /\s\s+/, ' ' )      
    input_record.strip!
       
    output_record_H = {}
    output_record_H[ K.fmtr_record_sort_keys ] = ''         # This is
    output_record_H[ K.fmtr_record_indent_keys ] = ''       # to establish
    output_record_H[ K.fmtr_forced_indent ] = []            # the order
    
    record_values_A = [ ]  # This goes inside the output_record_H

    
    if ( input_record.match( /^\s*(#{K.series}|#{K.subseries}|#{K.sub_series_text}|#{K.recordgrp})/i ) ) then
        record_type = $&.downcase
        if ( prepend_A.not_empty? ) then
            SE.puts "#{SE.lineno}: On a series, subseries, or recordgrp record but the prepend_A isn't empty"
            SE.q {[ 'input_record' ]}
            SE.q {[ 'prepend_A' ]}
            raise
        end
        if  ( record_type == K.series and group_sort_text_A.not_empty? ) then
            SE.puts "#{SE.lineno}: Got a 'series' record but group_sort_text_A is not empty"
            SE.q {[ 'input_record', 'group_sort_text_A' ]}
            raise
        end
        if  ( ( record_type == K.subseries or record_type == K.sub_series_text.downcase ) and group_sort_text_A.empty? ) then
            SE.puts "#{SE.lineno}: Got a 'sub-series' record but group_sort_text_A is empty"
            SE.q {[ 'input_record', 'group_sort_text_A' ]}
            raise
        end
        group_sort_text_A.push( input_record.downcase.strip.gsub( /[^[a-z0-9 ]]/,'' ).gsub( /\s\s+/, ' ' ) )
        if ( group_sort_text_A.maxdepth > 1 ) then
            SE.puts "#{SE.lineno}: group_sort_text_A has a maxdepth > 1"
            SE.q {[ 'input_record', 'group_sort_text_A' ]}
            raise
        end   
        
        case true
        when ( record_type.downcase == K.subseries.downcase )
                input_record.sub!( /^\s*#{K.subseries}/, K.sub_series_text )
        when ( record_type.downcase == K.sub_series_text.downcase )
                record_type = K.subseries
        when ( record_type.downcase == K.recordgrp )                
                input_record.sub!( /^\s*#{K.recordgrp}[^:]*:\s*/i, '' ) 
        end
        record_values_A[ K.fmtr_record_values__text_idx ] = input_record
        
        output_record_H[ K.level ] = record_type.downcase     
        output_record_H[ K.fmtr_record_sort_keys ] = group_sort_text_A.join( ' ' )
        output_record_H[ K.fmtr_record_indent_keys ] = []
        output_record_H[ K.fmtr_forced_indent ].push( K.fmtr_right )
    else
        output_record_H[ K.level ] = K.file        

        input_record = change__SpecificThing_period__to__tildy_SpecificThing_tildy( input_record )
        sentence_A = input_record.split( '.' ).map( &:to_s ).map( &:strip ).reject( &:blank? )\
                                 .map{ | e | change__tildy_SpecificThing_tildy__to__SpecificThing_period( e ) }\
                                 .map{ | e | e.sub( /./,&:upcase ) }                            
        if ( sentence_A.maxdepth > 1 ) then
            SE.puts "#{SE.lineno}: sentence_A has a maxdepth > 1"
            SE.q {[ 'input_record', 'sentence_A' ]}
            raise
        end         
        if ( sentence_A.empty? ) then
            SE.puts "#{SE.lineno}: sentence_A is empty."
            SE.q {[ 'input_record', 'sentence_A' ]}
            raise
        end
        
        arr1_A = [ ]
        loop do
            sentence = sentence_A.pop( 1 )[ 0 ]   # pop with an argument returns an array, [0] says return the 1st element
            arr1_A.unshift( sentence )
            break if ( sentence_A.empty? )
            break if ( sentence_A.maxindex < self.cmdln_option_H[ :max_levels ] )   # At least 1 sentence should in the record text field,
                                                                                # which is why this 'if' is at the END of the loop.
        end
        record_values_A[ K.fmtr_record_values__text_idx ] = arr1_A.join( '. ' )
        
    #       The sort keys are at the front of the record so the Unix 'sort' command works.   

        output_record_H[ K.fmtr_record_sort_keys ] = (   group_sort_text_A + 
                                                         sentence_A +
                                                         arr1_A +
                                                         from_thru_date_A_A.sort  ).join( ', ' ).downcase.gsub( /[^[a-z0-9,\- ]]/,'' )
              
        indent_keys_A = [ ] 
        loop do
            break if ( sentence_A.empty? )
            sentence = sentence_A.pop( 1 )[ 0 ]
            indent_keys_A.unshift( sentence )
        end     
        output_record_H[ K.fmtr_record_indent_keys ] = indent_keys_A       
        
        title = output_record_H[ K.fmtr_record_indent_keys ].join('. ') + ' ' + record_values_A[ K.fmtr_record_values__text_idx ]
        if ( title.length > self.cmdln_option_H[ :max_title_size ] ) then
            SE.puts "#{SE.lineno}: Warning: Title size #{title.length} '#{title}'"
            SE.puts ""
        end
    end
    
    record_values_A[ K.fmtr_record_values__dates_idx ] = from_thru_date_A_A     
    record_values_A[ K.fmtr_record_values__notes_idx ] = note_A                 
    record_values_A[ K.fmtr_record_values__container_idx ] = ( container_H == K.fmtr_empty_container_H ) ? {} : container_H 
      
    output_record_H[ K.fmtr_record_values ]      = record_values_A
    output_record_H[ K.fmtr_record_num ]         = "#{$.}"
    output_record_H[ K.fmtr_record_original ]    = saved_input_record

    SE.q {[ 'output_record_H' ]}  if ( $DEBUG )
    write_pending_record_H( output_record_H )    
end
write_pending_record_H( {} )

SE.puts "======================================================================="
SE.puts "Minimum date:  '#{self.min_date}'"
SE.puts "Maxmimum date: '#{self.max_date}'"
SE.puts "Notes created: '#{self.note_cnt}'"
SE.puts "Count of date patterns found:"
SE.puts self.find_dates_with_4digit_years_O.pattern_cnt_H.ai
SE.puts ""

if ( prepend_A.length > 0 ) then
    SE.puts ""
    SE.puts ""
    SE.puts "#{SE.lineno}: ERROR! prepend_A not empty.  Missing drop record."
    SE.q { 'prepend_A' }
    SE.puts ""
    raise
end
if ( group_sort_text_A.length > 0 ) then
    SE.puts ""
    SE.puts ""
    SE.puts "#{SE.lineno}: ERROR! group_sort_text_A not empty.  Missing __END_GROUP__ record."
    SE.q { 'group_sort_text_A' }
    SE.puts ""
    raise
end


#p stack_of_recs
