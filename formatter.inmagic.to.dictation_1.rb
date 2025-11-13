require 'json'
require 'optparse'

require 'class.Hash.extend.rb'
require 'class.Array.extend.rb'
require 'class.Object.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'tempfile'


module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :valid_column_uses_H, :cmdln_option_H, 
                      :output_F, :pending_output_BUF, :output_cnt, :box_cnt, :box_line_only_cnt, :detail_column_A, :column_stack_A,
                      :used_column_header_A, :columns_to_skip_for_notes, :inmagic_column_to_as_note_type_xlat_H
        attr_accessor :container_for_following_records_A
        VALUE_IDX = 0     
        COUNT_IDX = 1
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

myself_name = File.basename( $0 )

def create_H_of_all_possible_notes( input_column_H )
    notes_H = {}
    input_column_H.each_pair do | column_name, column_value |
        next if ( column_value.blank? )
        next if ( column_name.in?( self.used_column_header_A ) )
        next if ( column_name.downcase.in?( self.columns_to_skip_for_notes ) )
        if ( self.inmagic_column_to_as_note_type_xlat_H.has_no_key?( column_name.downcase ) ) then
            SE.puts "#{SE.lineno}: Can't find column_name '#{column_name}' in inmagic_column_to_as_note_type_xlat_H"
            SE.q {'inmagic_column_to_as_note_type_xlat_H'}
            raise
        end
        stringer = "Note: {#{self.inmagic_column_to_as_note_type_xlat_H[ column_name.downcase ][ 0 ]}}: "
        if ( self.inmagic_column_to_as_note_type_xlat_H[ column_name.downcase ][ 1 ].not_blank? ) then
            stringer += self.inmagic_column_to_as_note_type_xlat_H[ column_name.downcase ][ 1 ] + ' '
        end
        stringer += column_value.gsub( '|', embedded_crlf )
        if ( notes_H.has_key?( column_name ) ) then
            SE.puts "#{SE.lineno}: Found duplicate column_name '#{column_name}' in notes_H"
            SE.q {'notes_H'}
            SE.q {'input_column_H'}
            raise
        end
        notes_H[ column_name ] = stringer
    end
    return notes_H
end

def embedded_crlf
    if ( self.cmdln_option_H.has_no_key?( :embedded_crlf ) ) then
        SE.puts "#{SE.lineno}: Can't find 'self.cmdln_option_H[ :embedded_crlf ]"
        SE.q {[ self.cmdln_option_H ]} 
        raise
    end
    return self.cmdln_option_H[ :embedded_crlf ]
end

def box_only_line_option
    if ( self.cmdln_option_H.has_no_key?( :box_only_line ) ) then
        SE.puts "#{SE.lineno}: Can't find 'self.cmdln_option_H[ :box_only_line ]"
        SE.q {[ self.cmdln_option_H ]} 
        raise
    end
    return self.cmdln_option_H[ :box_only_line ]
end

def column_use_H
    if ( self.cmdln_option_H.has_no_key?( :column_use_H ) ) then
        SE.puts "#{SE.lineno}: Can't find 'self.cmdln_option_H[ :column_use_H ]"
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
def recordgrp_column_name()
    column_use_H.each_pair do | c, v | 
        if ( v == K.fmtr_inmagic_recordgrp ) then
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
        SE.puts "#{SE.lineno}: self.valid_column_uses_H[ column_use_H[ column_name ] ][ :used_for_detail ] returns nil"
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
        SE.puts "#{SE.lineno}: self.valid_column_uses_H[ column_use_H[ column_name ] ][ :has_subcolumns ] returns nil"
        SE.q {[ 'column_name', 'column_use_H' ]}
        SE.q {[ 'self.valid_column_uses_H' ]}
        raise
    end
    return use
end
def container_for_following_records_reset
    if ( self.container_for_following_records_A.nil? ) then
        self.container_for_following_records_A = [ ] 
        return
    end
    return if ( self.container_for_following_records_A.empty? )
    if ( self.container_for_following_records_A[ COUNT_IDX ] == 0 ) then
        SE.puts "#{SE.lineno}: WARNING: Container '#{self.container_for_following_records_A[ VALUE_IDX ]} never used"    
    end
    self.container_for_following_records_A = [ ] 
end

def is_there_series_or_recordgrp_data?( input_column_H ) 
    its_true = nil
    its_true = ( series_column_name.not_nil?    and input_column_H[ series_column_name ].not_blank? )
    return true if ( its_true ) 
    its_true = ( recordgrp_column_name.not_nil? and input_column_H[ recordgrp_column_name ].not_blank? )
    return true if ( its_true )
    return false
end

def box_only_line_logic( sub_column_value, note )
    stringer = sub_column_value.sub( K.container_and_child_types_RE, '' )
    if ( $&.not_nil? ) then
        current_container = $&.strip
        prematch=$`
        if ( stringer.match?( /^\s*([.:])?\s*$/) and note.blank? ) then            # If true: the sub_column is ONLY the Box/child data.
            case box_only_line_option
            when :next  
                self.box_cnt += -1
                self.box_line_only_cnt += 1
                container_for_following_records_reset
                self.container_for_following_records_A = [ current_container.upcase, 0 ]
                return "# BOX_ONLY_LINE '#{current_container}' used to set the following record:"
            when :prior
                pending_BUF_group_record_match_O = self.pending_output_BUF.match( /^\s*#{K.any_fmtr_group_record_RES}/i )          
                if ( pending_BUF_group_record_match_O.not_nil? ) then
                    sub_column_value += ' CONFUSING BOX_ONLY_LINE: Previous line is a group.'
                    self.box_line_only_cnt += 1
                    return sub_column_value
                end
#   ADD!  Only move the box if the previous line ALSO has a date.  If not, just make a "confusing" line.
                pending_BUF_container_match_O = self.pending_output_BUF.match( /^\s*#{K.container_and_child_types_RES}/i )
                if ( pending_BUF_container_match_O.not_nil?) then
                    if ( pending_BUF_container_match_O[ 0 ].upcase == pending_BUF_container_match_O[ 0 ] ) then    # If true:  the Pending_BUF isn't a group record AND
                      # The container/child that was present was already upcased
                      # which means it came from here.
                        self.pending_output_BUF.prepend( current_container.upcase + ', ' )
                        self.box_line_only_cnt += 1
                        return "# BOX_ONLY_LINE '#{current_container}' moved to previous line (2+)."
                    else
                        sub_column_value += ' CONFUSING BOX_ONLY_LINE: Previous line already has a box.'
                        self.box_line_only_cnt += 1
                        return sub_column_value
                    end
                else
                    self.pending_output_BUF.prepend( current_container.upcase + ', ' )
                    self.box_line_only_cnt += 1
                    return "# BOX_ONLY_LINE '#{current_container}' moved to previous line"
                end
            else
                SE.puts "#{SE.lineno} Invalid 'box_only_line_option'"
                SE.q {'box_only_line_option'}
                raise
            end  
        else    # Not a box only line
            if ( prematch.blank? ) then                # If true: the Box is the 1st thing in the sub-column
                container_for_following_records_reset  # which we'll guess to mean to reset the container_for_following_records_A
              # SE.q {'current_container'}
            end
        end
    end
    return sub_column_value
end

def output_F_puts( stringer )
    if ( stringer == :flush ) then
        stringer = ''
    else
        self.output_cnt += 1
        if ( stringer.blank? ) then
            self.pending_output_BUF += "\n"     #  puts won't "double-space" if "\n" is added to the end of the string!  
                                                #  See just below.
            return
        end
        if ( stringer.match( /^\s*#\s*BOX_ONLY_LINE/ ) ) then
            self.pending_output_BUF += "\n#{stringer}"
            return
        end
    end
    if ( self.pending_output_BUF.not_empty? ) then
#
#                     puts adds a "\n" ONLY IF there's not one there already!!!
        self.output_F.print self.pending_output_BUF.gsub( embedded_crlf, '|' ) + "\n"
    end
    self.pending_output_BUF = stringer + ''
end

def put_column( column_idx = 0, title_length = 0 )
    SE.q { [ 'self.detail_column_A[ column_idx]' ]}  if ( $DEBUG )  
    column_value  = self.detail_column_A[ column_idx ]
    SE.q { [ 'column_idx','column_value' ]} if ( $DEBUG ) 
    
    if ( matchdata = column_value.match( /^"(.*)"$/ ) ) then
        column_value = matchdata[ 1 ]
    end

    sub_column_value_A = column_value.split( '|' ).map( &:to_s ).map( &:strip )    
    sub_column_value_A = sub_column_value_A.sort_by { | k | k.downcase.strip.gsub(/[^[a-z0-9 ]]/,'') } if ( self.cmdln_option_H[ :sort ] )

    SE.q { 'sub_column_value_A' } if ( $DEBUG )
    sub_column_value_A.each_with_index do | sub_column_value, sub_column_idx |
#       next if ( sub_column_value.blank? )
        sub_column_value_unaltered = sub_column_value + ''
        sub_column_without_notes = sub_column_value + ''
        sub_column_without_notes.gsub!( /\s+Note:.*/i, '' )  

        note = ''
        if ( sub_column_value.sub!( /\s+note:(.*)$/i, '' ) ) then
            note = $&
            note.strip!
        end
        if ( sub_column_value.sub!( /(\(.*?\))\s*$/, '' ) ) then    # Inmagic column detail notes are enclosed in ()
            if ( note.not_blank? ) then
                SE.q {'$&'}
                SE.q {'sub_column_value_unaltered'}
                SE.q {'note'}
                raise
            end
            note = $&                           # The note is put back AFTER the box logic
            note.gsub!( /[()]/, '' )
            note.strip!
            note.sub!( /./,&:upcase )
            note = "Note: #{note}"
        end

            
        stringer = ''
        loop do
            #   Move the container_and_child_types to the front of the record (without any brackets).            
            sub_column_value.sub!( K.container_and_child_types_RE, ' ' )  # <<  This must be a ' '
            break if ( $~.nil? )            
            stringer += $~[ :inside_the_dels ].downcase + ' '             # The downcase is needed for BOX ONLY logic below
            self.box_cnt += 1                                             # which uses upcase
            #   Move the bracketed words [volume,letterpress] to the front of the record without the brackket. 
            sub_column_value.sub!( K.container_bracketed_word_RE, ' ' )   # <<  This must be a ' '
            if ( $~.not_nil? )
                stringer += $~[ :bracketed_word ] + ' '
            end

        end
        stringer += sub_column_value
        sub_column_value = stringer + ''
        
        
        sub_column_value = box_only_line_logic( sub_column_value, note )
        
        sub_column_value += " #{note}." if ( note.not_blank? )
        
        this_column_is_a_record_group_continuation = false
        if ( column_idx == 0 )
            if ( self.column_stack_A.not_empty? and self.column_stack_A.last.match( /^\s*(#{K.recordgrp_text}\s+[0-9]+)/i ) ) then
                group_text_from_stack = $1
                stringer = sub_column_value_unaltered.downcase.sub( /[[:punct:]]\s*$/, '' ).gsub( /\s\s+/, ' ').strip
              # SE.q {'stringer'}
              # SE.q {'self.column_stack_A.last[ 0 .. stringer.maxindex ]'}
              # SE.q {'stringer.maxindex'}
              # SE.q {'stringer == self.column_stack_A.last[ 0 .. stringer.maxindex ]'}
                if ( stringer == self.column_stack_A.last[ 0 .. stringer.maxindex ] ) then
                    this_column_is_a_record_group_continuation = true
                else  
                  # SE.puts "#{SE.lineno}: POP:  #{self.column_stack_A.last[ 0, 30 ]}"
                    self.column_stack_A.pop                    
                    indent_spaces = ' ' * ( self.column_stack_A.length * 4 )
                    output_F_puts indent_spaces  + "#{K.fmtr_end_group} STARTofROW csv.row=#{$.}" +
                                " '#{group_text_from_stack}', #{self.column_stack_A.maxindex},#{column_idx},#{sub_column_idx}"
                end 
            end
        end        
        
        regexp = /^\s*((#{K.subseries}|#{K.sub_series_text})\s+[0-9]+)/i
        if ( sub_column_value_unaltered.match( regexp )  ) then
            if ( self.column_stack_A.last.match( regexp ) ) then
                group_text_from_stack = $1
              # SE.puts "#{SE.lineno}: POP:  #{self.column_stack_A.last[ 0, 30 ]}"
                self.column_stack_A.pop
                indent_spaces = ' ' * ( self.column_stack_A.length * 4 )
                output_F_puts indent_spaces  + "#{K.fmtr_end_group} End-Begin csv.row=#{$.}" +
                            " '#{group_text_from_stack}', #{self.column_stack_A.maxindex},#{column_idx},#{sub_column_idx}"
            end
        end
        if ( this_column_is_a_record_group_continuation ) then
        #   skip this column
        else
            stringer = ' ' * ( self.column_stack_A.length * 4 )
            if ( sub_column_value.blank? or sub_column_value.match?( /^\s*#/ ) ) then    # Don't put boxes on comment lines 
                group_record_MO = nil
              # SE.q {'sub_column_value'}
              # SE.q {'self.container_for_following_records_A'}
            else
                group_record_MO = sub_column_value_unaltered.match( /^\s*#{K.any_fmtr_group_record_RES}/i )
                if ( self.container_for_following_records_A.empty? or 
                      sub_column_value.index( self.container_for_following_records_A[ VALUE_IDX ] ) ) then
                #   do nothing...
                else
                    if ( group_record_MO.nil? ) then
                        stringer   += "%-20s  " % self.container_for_following_records_A[ VALUE_IDX ]
                        self.container_for_following_records_A[ COUNT_IDX ] += 1
                    else
                        if ( self.container_for_following_records_A[ COUNT_IDX ] > 0 ) then
                            SE.puts "#{SE.lineno}: Group Record '#{sub_column_value_unaltered}' hit with Box-Only Value " +
                                    "'#{self.container_for_following_records_A[ VALUE_IDX ]}', reset Box-Only prefixing."
                            self.container_for_following_records_reset
                        else
                            SE.puts "#{SE.lineno}: Box before a record group."
                            SE.q {['sub_column_value']}
                            SE.q {['sub_column_value_unaltered']}
                            SE.q {['self.container_for_following_records_A']}
                            SE.q {['sub_column_value.index( self.container_for_following_records_A[ VALUE_IDX ] )']}
                            raise
                        end
                    end
                end
            end
            stringer += sub_column_value                            
            output_F_puts stringer
            if ( group_record_MO.not_nil? ) then 
                self.column_stack_A.push( sub_column_value_unaltered.sub( /[[:punct:]]\s*$/, '' ).gsub( /\s\s+/, ' ').strip.downcase )  
              # SE.q {'self.column_stack_A'}
              # SE.puts "#{SE.lineno}: PUSH: #{self.column_stack_A.last[ 0, 30 ]}"
            end
        end

        if ( sub_column_value.count( '"' ) % 2 != 0 ) then
            SE.puts "WARNING: Odd number of double-quotes found at ln:#{self.output_cnt}:'#{sub_column_value}'"
            SE.puts ""
        end
        if ( ( sub_column_value.count( ')' ) + sub_column_value.count( '(' ) ) % 2 != 0 ) then
            SE.puts "WARNING: Odd number of parentheses found at ln:#{self.output_cnt}:'#{sub_column_value}'"
            SE.puts ""
        end
        if ( ( sub_column_value.count( ']' ) + sub_column_value.count( '[' ) ) % 2 != 0 ) then
            SE.puts "WARNING: Odd number of square-brackets found at ln:#{self.output_cnt}:'#{sub_column_value}'"
            SE.puts ""
        end
        if ( sub_column_without_notes.length > self.cmdln_option_H[ :max_title_size ] ) then
          # SE.puts "WARNING: Max title size is greater than #{self.cmdln_option_H[ :max_title_size ]} at ln:#{self.output_cnt}:'#{sub_column_value}'"
          # SE.puts ""
        end

        if ( column_idx < self.detail_column_A.maxindex ) then   
            self.container_for_following_records_reset

            put_column( column_idx + 1, title_length + sub_column_without_notes.length )   

            self.container_for_following_records_reset
        end

    end
    if ( self.column_stack_A.maxindex >= 0 ) then
        if ( m_O = self.column_stack_A.last.match( /^\s*#{K.any_fmtr_group_record_RES}/i ) and 
            m_O[ 1 ] != "#{K.recordgrp_text.downcase}" ) then
            group_text_from_stack = m_O[ 1 ]
          # SE.puts "#{SE.lineno}: POP:  #{self.column_stack_A.last[ 0, 30 ]}"
            self.column_stack_A.pop
            indent_spaces = ' ' * ( self.column_stack_A.length * 4 )
            output_F_puts indent_spaces + "#{K.fmtr_end_group} ENDofCOLUMN csv.row=#{$.}" +
                        " '#{group_text_from_stack}',#{self.column_stack_A.maxindex},#{column_idx}"
        end
    end
    if ( column_idx == 0 and self.column_stack_A.not_empty? and not self.column_stack_A.last.match?( /#{K.recordgrp_text}/i ) ) then   
        SE.q {['self.column_stack_A']}
        raise
    end

end

self.valid_column_uses_H = { K.fmtr_inmagic_recordgrp    => { :used_for_detail => true , :has_subcolumns => false, } ,
                             K.fmtr_inmagic_series       => { :used_for_detail => true , :has_subcolumns => false, } ,                             
                             K.fmtr_inmagic_seriesdate   => { :used_for_detail => false, :has_subcolumns => false, } ,
                             K.fmtr_inmagic_seriesnote   => { :used_for_detail => false, :has_subcolumns => false, } ,
                             K.fmtr_inmagic_detail       => { :used_for_detail => true , :has_subcolumns => true,  } ,
                           }

self.cmdln_option_H = { :r => 999999999,
                        :box_only_line => nil,
                        :sort => false,
                        :output_file_prefix => '',
                        :default_century_pivot_ccyymmdd => '',
                        :max_title_size => 150,
                        :column_use_H => {},
                        :embedded_crlf => K.embedded_CRLF,
                        :d => false,
                       }                                                                                        

OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"

    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do | opt_arg |
        self.cmdln_option_H[ :r ] = opt_arg
    end
    
    option.on( '--box-only-line=x[next|prior]', "A box by itself goes to the 'prior' or 'next' line") do | opt_arg |
        if ( opt_arg.not_in?( 'next', 'prior' ) ) then
            SE.puts "--box-only-line has an invalid argument '#{opt_arg}', was expecting 'next' or 'prior'."
            raise
        end
        self.cmdln_option_H[ :box_only_line ] = opt_arg.to_sym
    end
    
    option.on( "--sort", "Sort the detail records." ) do
        self.cmdln_option_H[ :sort ] = true
    end  
    
    option.on( "--output-file-prefix=x", "File prefix for the two output files." ) do | opt_arg |
        self.cmdln_option_H[ :output_file_prefix ] = opt_arg
    end

    option.on( "--default-century n", OptionParser::DecimalInteger, "Default century pivot date for 2-digit years." ) do
        self.cmdln_option_H[ :default_century_pivot_ccyymmdd ] = opt_arg
    end  
    
    option.on( "--columns=NAME[:use][,NAME:use]...", "Order and use of the columns") do | opt_arg |
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
    
    option.on( "--max-title-size n", OptionParser::DecimalInteger, "Warn if title-size over n" ) do | opt_arg |
        self.cmdln_option_H[ :max_title_size ] = opt_arg
    end

    option.on( "-d", "Turn on $DEBUG switch" ) do
        $DEBUG = true
    end

    option.on( "-h", "--help" ) do
        SE.puts option
        SE.puts ""
        SE.puts "Available columns and uses:"
        SE.q {[ 'self.valid_column_uses_H' ]}
        SE.puts ""
        SE.puts "Default values for program options:"
        SE.q {[ 'self.cmdln_option_H' ]}
        SE.puts ""
        exit
    end
end.parse!  # Bang because ARGV is altered
SE.q {[ 'self.cmdln_option_H' ]}
if ( box_only_line_option.nil? ) then
    SE.puts "#{SE.lineno}: The --box-only-line option is required."
    raise
end

self.columns_to_skip_for_notes = [ 'ms number',
                                   'collection name',
                                   'additional access',
                                   'extent',
                                 ]
                                 
self.inmagic_column_to_as_note_type_xlat_H = { 'scope and content'    => [ K.scopecontent, '' ],
                                               'oac scope and conten' => [ K.scopecontent, "InMagic 'OAC Scope and Conten' field:#{embedded_crlf}" ],
                                               'historical info'      => [ K.bioghist, '' ],
                                               'provenance'           => [ K.acqinfo, '' ],
                                               'filing location'      => [ K.physloc, '' ],
                                               'record id number'     => [ K.materialspec, "InMagic Record ID Number:" ],
                                               'former ms number'     => [ K.materialspec, "Former MS number:" ],
                                               'original inventory'   => [ K.materialspec, "InMagic 'Original inventory' field:#{embedded_crlf}" ],
                                               '__DETAIL_LINES__'     => [ K.materialspec, '' ],
                                            }


tmp1_F = File.new( "#{myself_name}.tmp1_F.json", 'w+' )
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

tmp2_F = File.new( "#{myself_name}.tmp2_F.json", 'w+' )
column_with_data_H = {}
original_file_header_A = []
tmp1_F.rewind
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
        column_value.gsub!( /\r?\n/, '|' )  
        column_value.gsub!( '+++DEL+++', ',' )      # Might be there from 'line' command.
        column_value.gsub!( /[^[:print:]]/, ' ' )
        column_value.gsub!( '""', '"' )
        column_value.tr!( '’“”', '\'""' )
#       column_value.strip!
        output_column_H[ column_header ] = column_value
       
        if ( column_value.not_blank? and column_with_data_H.has_no_key?( column_header ) ) then
            stringer = (column_value.include?( '|' ) ) ? '*|*' : '   '
            column_with_data_H[ column_header ] = "#{stringer} Line=#{$.}: #{column_value}"
        end
    end
    tmp2_F.puts output_column_H.to_json
end
tmp1_F.close

tmp3_F = File.new( "#{myself_name}.tmp3_F.json", 'w+' )
SE.q {['column_with_data_H']}
self.used_column_header_A = []
tmp2_F.rewind
tmp2_F.each_line do | input_column_J |    
    input_column_J.chomp!
    input_column_H = JSON.parse( input_column_J )
    output_column_H={}
    
    input_column_H.keys.each do | column_name |
        if ( column_with_data_H[ column_name ].nil? and column_use_H[ column_name ].nil? ) then
            next
        end
        output_column_H[ column_name] = input_column_H[ column_name ]  
    end

    if ( $. == 1 ) then
        self.used_column_header_A = output_column_H.keys
        if (self.cmdln_option_H[ :column_use_H ].empty? ) then
            self.used_column_header_A.each do | column_name | 
                self.cmdln_option_H[ :column_use_H ][ column_name ] = :none_assigned 
            end
        else
#           arr1 = column_use_H.keys - self.used_column_header_A          
            arr1 = column_use_H.keys - column_with_data_H.keys
            if ( arr1.not_empty? ) then
                SE.puts ""
                SE.puts ""
                SE.puts "#{SE.lineno}: Column(s) '#{arr1.join(', ')}' have no data in them but are specified in the --columns option."
                SE.puts "#{SE.lineno}: Some of these might be used for sorting (e.g. recordgrp and series)."
                SE.puts "#{SE.lineno}: The column names in the --columns option are case sensitive!"
                SE.puts ""
                SE.q {[ 'column_use_H.keys' ]}
                SE.q {[ 'column_with_data_H.keys' ]}
                raise
            end
            arr1 = self.used_column_header_A - column_use_H.keys
            if ( arr1.not_empty? ) then
                SE.puts "The following columns are being skipped:"
                SE.puts "#{arr1.join(', ')}"
            end
            self.used_column_header_A = column_use_H.keys
        end
        SE.puts ""
        SE.puts "Don't forget to look at: Dev/Projects/InMagic_Conversion/N++ Search Replace.docx"
        SE.puts ""
        SE.puts "CSV column headers      : #{original_file_header_A.join( ', ')}"
        SE.puts "Input columns being used: #{self.used_column_header_A.join( ', ' )}"
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
tmp2_F.close

# SE.q {[ 'column_use_H' ]}

resource_data_H = {}
tmp3_F.rewind
tmp3_F.each_line do | input_column_J |
    input_column_J.chomp!
    input_column_H = JSON.parse( input_column_J )
  # next if ( series_column_name.not_nil?    and input_column_H[ series_column_name ].not_blank? )
  # next if ( recordgrp_column_name.not_nil? and input_column_H[ recordgrp_column_name ].not_blank? )
    if ( is_there_series_or_recordgrp_data?( input_column_H ) ) then
        SE.puts "#{SE.lineno}: Record skipped in RESOURCE_DATA process because:"
        SE.q {[ 'is_there_series_or_recordgrp_data?( input_column_H )' ]}
        SE.q {[ 'input_column_H[ recordgrp_column_name ]', 'input_column_H[ series_column_name ]']}
    end
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
  
        column_value.rstrip!
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

output_resource_filename = self.cmdln_option_H[ :output_file_prefix ] + ".RESOURCE_DATA.json"
SE.puts "Output RESOURCE_DATA file '#{output_resource_filename}'"
output_resource_F = File::open( output_resource_filename, mode='w' )
resource_data_H.each_pair do | column_name, column_value |
    column_value.gsub!( '|', embedded_crlf )
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

tmp4_F = File.new( "#{myself_name}.tmp4_F.json",'w+' )
tmp3_F.rewind
tmp3_F.each_line do | input_column_J |
    input_column_J.chomp!
    input_column_H = JSON.parse( input_column_J )
    arr1 = input_column_H.keys.select{ | k | column_name_exists?( k ) and used_for_detail?( k )}.map{ | k | input_column_H[ k ] }
    if ( arr1.all?( &:empty? ) )
        SE.puts "#{SE.lineno}: WARNING: tmp3_F record skipped, having all blank detail rows"
        next
    end
    if ( is_there_series_or_recordgrp_data?( input_column_H ) ) then
        all_possible_notes_H = create_H_of_all_possible_notes( input_column_H )     # This doesn't include the 'series column' notes.
    else
        SE.puts "#{SE.lineno}: 'create_H_of_all_possible_notes' skpped because:"
        SE.q {[ 'is_there_series_or_recordgrp_data?( input_column_H )' ]}
        SE.q {[ 'input_column_H[ recordgrp_column_name ]', 'input_column_H[ series_column_name ]']}
        all_possible_notes_H = {}
    end
    
    seriesdate_column_value = ''
    output_column_H = {}
    column_use_H.each_pair do | column_name, column_use |     
        input_column_name_value__save = input_column_H[ column_name ].copy_by_value
        if ( self.used_column_header_A.index( column_name ).nil? ) then
            SE.puts "#{SE.lineno}: Couldn't find '#{column_name}' in 'self.used_column_header_A'"
            SE.q {[ 'self.used_column_header_A' ]}
            raise
        end
        
        case column_use
        when K.fmtr_inmagic_seriesdate
            if ( series_column_name.nil? ) then
                SE.puts "#{SE.lineno}: Couldn't find the 'series_column_name' for column-use: #{column_use}, for column: #{column_name}"
                SE.puts "#{SE.lineno}: Note: this is probably the 'extent' column.  If there are NO series records, it's the Resource date"
                SE.q {[ 'self.used_column_header_A' ]}
                SE.q {[ 'column_name' ]}
                raise
            end
            seriesdate_column_value = input_column_H[ column_name ]

        when K.fmtr_inmagic_seriesnote
            if ( input_column_H[ column_name ].not_blank? ) then
                note_A = input_column_H[ column_name ].split( '|' ).map( &:to_s ).map( &:strip ) 
                if ( all_possible_notes_H.has_key?( column_name ) ) then
                    SE.puts "#{SE.lineno}: Found duplicate column_name '#{column_name}' in 'all_possible_notes_H'"
                    SE.q {'all_possible_notes_H'}
                    SE.q {'input_column'}
                    raise
                end
                all_possible_notes_H[ column_name ] = "Note: {#{K.scopecontent}}: " + note_A.join( embedded_crlf ) 
            end
            
        when K.fmtr_inmagic_series
            if ( input_column_H[ column_name ].blank? ) then
                if ( recordgrp_column_name.nil? ) then
                    SE.puts "#{SE.lineno}: Column '#{column_name}' is supposed to be a '#{column_use}' but the column is blank"
                    SE.puts "#{SE.lineno}: and there's no '#{K.fmtr_inmagic_recordgrp}' column."
                    SE.puts "#{SE.lineno}: '#{input_column_name_value__save}'"                
                    SE.q {['input_column_H']}
                    SE.q {['output_column_H']}
                    raise
                end
                if ( recordgrp_column_name.nil? or output_column_H[ series_column_name ] != 'NO_SERIES_RECORD' ) 
                    SE.puts "#{SE.lineno}: Column '#{column_name}' is supposed to be a '#{column_use}' and the column is blank,"
                    SE.puts "#{SE.lineno}: but: output_column_H[ #{series_column_name} ] != 'NO_SERIES_RECORD'."
                    SE.puts "#{SE.lineno}: Is the recordgrp column (logically) before the series column?"
                    SE.puts "#{SE.lineno}: '#{input_column_name_value__save}'"                
                    SE.q {['input_column_H']}
                    SE.q {['output_column_H']}
                    raise
                end
            else
                input_column_H[ column_name ].sub!( /^\s*Series\s*/i, '' )
                input_column_H[ column_name ].sub!( /^([0-9]+)[.:]?\s+/, '' )
                if ( $~.nil? ) then
                    SE.puts "#{SE.lineno}: Column '#{column_name}' is supposed to be a '#{column_use}' but there's no series number"
                    SE.puts "#{SE.lineno}: at the begining of the column."
                    SE.puts "#{SE.lineno}: '#{input_column_name_value__save}'"
                    series_num = '? '
                else
                    series_num = $1
                end
                output_column_H[ column_name ] = ''
                arr1 = input_column_H[ column_name ].split( '|' ).map( &:to_s ).map( &:strip ) 
                series_name = ''
                note_A = []
                arr1.each_with_index do | e, idx |
                    if ( idx == 0 ) then
                        output_column_H[ column_name ] += "Series #{series_num}: #{e}"
                        series_name = e
                    end
                    next if ( e.blank? )
                    next if ( e.downcase == series_name.downcase )
                    note_A.push( e )
                end
                if ( all_possible_notes_H.has_key?( column_name ) ) then
                    SE.puts "#{SE.lineno}: Found duplicate column_name '#{column_name}' in 'all_possible_notes_H'"
                    SE.q {'all_possible_notes_H'}
                    SE.q {'input_column'}
                    raise
                end
                all_possible_notes_H[ column_name ] = "Note: {#{K.scopecontent}}: " + note_A.join( embedded_crlf ) if ( note_A.not_empty? )
            end            
        when K.fmtr_inmagic_recordgrp
            if ( output_column_H.has_key?( series_column_name ) ) then
                SE.puts "#{SE.lineno}: Column '#{column_name}' is supposed to be a '#{column_use}' and the column is blank,"
                SE.puts "#{SE.lineno}: but: output_column_H[ #{series_column_name} ] is already present."
                SE.puts "#{SE.lineno}: The recordgrp column must be processed before the series column."
                SE.puts "#{SE.lineno}: '#{input_column_name_value__save}'"                
                SE.q {['input_column_H.keys']}
                SE.q {['column_use_H']}
                raise      
            end            
            if ( input_column_H.has_no_key?( 'Collection Name' ) ) then
                SE.puts "#{SE.lineno}: No 'Collection Name' key in 'output_column_H'"
                SE.q {'output_column_H'}
                raise
            end
            
            output_column_H[ column_name ] = ' '     # This column must be before the series in output_column_H

#               The 'Collection Name' field seems to always be in the format of:
#                   Collection Name text|Record Group text|SubGroup Text
            arr1 = input_column_H[ 'Collection Name' ].split( '|' ).map( &:to_s ).map( &:strip ) 
            stringer = ''
            if ( arr1.maxindex > 0 )
                if ( m_O = arr1[ 1 ].match( /^\s*record\s*group\s+(#{input_column_H[ column_name ]})/i ) ) then
                    stringer = "#{K.recordgrp_text} #{m_O[ 1 ]}."
                elsif ( m_O = arr1[ 1 ].match( /^RG\s+([0-9]+)[ .]/ ) ) then
                    stringer = "#{K.recordgrp_text} #{m_O[ 1 ]}. #{m_O.post_match}"
                end
            end
            if ( stringer.blank? ) then    
                stringer = "#{K.recordgrp_text} #{input_column_H[ recordgrp_column_name ]}. #{arr1.join( ' ' )}"
                SE.puts "#{SE.lineno}: WARNING: Possible wrong Record Group name: '#{stringer}': input_column_H[#{column_name}]}='#{input_column_H[ column_name ]}'"                    
            else
                if ( arr1.maxindex > 1 ) then
                    SE.puts "#{SE.lineno}: WARNING: extra info for Record Group: '#{stringer}': '#{arr1.last( arr1.maxindex - 1 ).join( '| ' )}'"
                    stringer.concat( " #{arr1.last( arr1.maxindex - 1 ).join( ' ' )}" )
                end
            end
            stringer.gsub!( /\s\s+/, ' ')            
            output_column_H[ column_name ] = stringer
            
            if ( series_column_name.nil? or input_column_H[ series_column_name ].blank? ) then
                output_column_H[ series_column_name ] = 'NO_SERIES_RECORD'
            else
                output_column_H[ series_column_name ] = ''
            end
            
        when K.fmtr_inmagic_detail    
            output_column_H[ column_name ] = input_column_H[ column_name ]
        
        else
            SE.puts "Unknown column_use '#{column_use}'"
            SE.q {[ column_use_H ] }
            raise
        end
    end  
    if ( recordgrp_column_name.nil? ) then
        column_name_for_dates_n_notes = series_column_name
    else
        if ( output_column_H[ series_column_name ] == 'NO_SERIES_RECORD' ) then
            column_name_for_dates_n_notes = recordgrp_column_name
        else
            column_name_for_dates_n_notes = series_column_name 
        end
    end

    if ( column_name_for_dates_n_notes.nil? ) then
        if ( seriesdate_column_value.not_empty? ) then
            SE.puts "#{SE.lineno}: WARNING: Got dates but no place to put them!"
            SE.q {'column_name_for_dates_n_notes'}
            raise
        end
        if ( all_possible_notes_H.not_empty? ) then
            SE.puts "#{SE.lineno}: WARNING: Got notes but no place to put them!"
            SE.q {'all_possible_notes_H'}
#           raise
        end
    else   
        if ( seriesdate_column_value.not_empty? ) then
            output_column_H[ column_name_for_dates_n_notes ] += ' ' + seriesdate_column_value                 
        end     
        if ( all_possible_notes_H.not_empty? ) then
            output_column_H[ column_name_for_dates_n_notes ] += ' ' + all_possible_notes_H.values.join( ' ' )
        end                                                    
    end
#   SE.q {'column_name_for_dates_n_notes'}
#   SE.q {['input_column_H[ recordgrp_column_name ]','input_column_H[ series_column_name ]']}
#   SE.q {['output_column_H[ recordgrp_column_name ]','output_column_H[ series_column_name ]']}
    if ( output_column_H.keys.maxindex != self.used_column_header_A.select{ | e | e if (used_for_detail?( e ))}.maxindex ) then
        SE.puts "#{SE.lineno}: output_column_H.keys.maxindex != self.used_column_header_A.select{ | e | e if (used_for_detail?( e ))}.maxindex."
        SE.q {[ 'output_column_H.keys', 'self.used_column_header_A.select{ | e | e if (used_for_detail?( e ))}' ]}
        raise
    end
    self.detail_column_A = [ ]
    output_column_H.keys.each do | column_name | 
        next if ( output_column_H[ column_name ].blank? )
        next if ( output_column_H[ column_name ] == 'NO_SERIES_RECORD' )
        self.detail_column_A.push( output_column_H[ column_name ] )
    end
    tmp4_F.puts self.detail_column_A.to_json
end
tmp3_F.close

self.output_cnt = 0
self.box_cnt = 0
self.box_line_only_cnt = 0
container_for_following_records_reset

output_filename = self.cmdln_option_H[ :output_file_prefix ] + ".DETAIL.txt"
SE.puts "Output DETAIL file '#{output_filename}'"
SE.puts ''
SE.puts ''

self.output_F = File::open( output_filename, mode='w' )
self.pending_output_BUF = ''
self.column_stack_A = [ ]
tmp4_F.rewind
tmp4_F.each_line do | input_column_J |
    input_column_J.chomp!
    self.detail_column_A = JSON.parse( input_column_J )
    begin
        put_column( )
    rescue
        SE.puts "rescue ==================================================================="
        SE.q {['self.column_stack_A']}
        SE.puts "rescue ==================================================================="
        raise
    end
end
if ( self.column_stack_A.maxindex >= 0 ) then
    regexp = /^\s*(#{K.recordgrp_text}\s+[0-9]+)/i
    m_O = self.column_stack_A.last.match( regexp )
    if ( m_O.not_nil? )
        group_text_from_stack = m_O[1]
      # SE.puts "#{SE.lineno}: POP:  #{self.column_stack_A.last[ 0, 30 ]}"
        self.column_stack_A.pop
        indent_spaces = ' ' * ( self.column_stack_A.length * 4 )
        output_F_puts indent_spaces + "#{K.fmtr_end_group} ENDofPROGRAM csv.row=#{$.}" + 
                    " '#{group_text_from_stack}',#{self.column_stack_A.maxindex}"
    end
end
output_F_puts( :flush )   # flush pending output buffer
SE.puts "Box cnt     : #{self.box_cnt}"
SE.puts "Box only cnt: #{self.box_line_only_cnt}"
SE.puts "Record cnt  : #{self.output_cnt} (including control records and blank lines.)"
if ( self.column_stack_A.not_empty? ) then   
    SE.q {['self.column_stack_A']}
    raise
end
tmp4_F.close
self.output_F.close




