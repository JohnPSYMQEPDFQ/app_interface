=begin

Variable Abbreviations:
        AO = Archival Object ( Resources are an AO too, but they have their own structure. )
        AS = ArchivesSpace
        IT = Instance Type
        TC = Top Container
        SC = Sub-Container
        _H = Hash
        _J = Json string
        _RES = Regular Expression String, e.g: find_bozo_RES = '\s+bozo\s+'
        _RE  = Regular Expression, e.g.: find_bozo_RE = /#{find_bozo_RES}/
        _A = Array
        _O = Object
        _Q = Query
        _C = Class of Struct
        _S = Structure of _C 
        __ = reads as: 'in a(n)', e.g.: record_H__A = 'record' Hash "in an" Array.

=end

class Record_Grouping_Indent

    def self.new_with_flush(*args)
        myself_O = new(*args)
        yield myself_O
        myself_O.flush
    end

    def initialize(record_print_method, indent_print_method, stack_size_0R, indent_keys_prefixes_A = [ [ '/', 0 ] ] )
        @record_print_method = record_print_method
        @indent_print_method = indent_print_method
        if (stack_size_0R < 1) then
            SE.puts "#{SE.lineno}: stack_size_0R, must be 1 or greater (and, it's 0-relative remember...)."
            raise
        end
        @record_stack_size_0R = stack_size_0R
        @record_H__stack_A = []
        if (! indent_keys_prefixes_A.empty?) then
            if (! indent_keys_prefixes_A[ 0 ].is_a?(Array)) then
                SE.puts "#{SE.lineno}: indent_keys_prefixes_A, must be an array of arrays" +
                        " (eg. [ [ '/', 0] ] -or- [ [ '/', 0 ], [ 'x', 3 ] ]"
                raise
            end
        end
        @indent_key_stack_A_A = indent_keys_prefixes_A
        if ( @indent_key_stack_A_A.empty? or @indent_key_stack_A_A[ 0 ][ 0 ] != '/' ) then
            @indent_key_stack_A_A.unshift( [ '/', 0 ])
        end
        @indent_key_prefixes_A = @indent_key_stack_A_A.transpose[ 0 ]
        @calculated_indent_right_rec_cnt = 0
        @forced_indent_right_rec_cnt = 0
        @calculated_indent_left_rec_cnt = 0
        @forced_indent_left_rec_cnt = 0
        @current_calculated_indent_level = 0
        @group_rec_cnt = 0
        @file_rec_cnt = 0
        @total_rec_cnt = 0
    end
    private_class_method :new
    private attr_accessor :record_print_method, :indent_print_method, :record_stack_size_0R, :record_H__stack_A,
                          :indent_key_stack_A_A, :indent_key_prefixes_A, :first_record_indent_keys_A, :highest_matched_indent_key_idx_A,
                          :calculated_indent_right_rec_cnt, :forced_indent_right_rec_cnt,
                          :calculated_indent_left_rec_cnt, :forced_indent_left_rec_cnt,
                          :current_calculated_indent_level,
                          :group_rec_cnt, :file_rec_cnt, :total_rec_cnt

    def flush
        self.record_stack_size_0R = 0
        ld = SE::Loop_detector.new
        loop do
            break if ( self.record_H__stack_A.maxindex < 0 )  
            ld.loop
            self.add_record( {} )
        end
        
        if ( self.indent_key_stack_A_A.maxindex >= 1 ) then
            SE.puts "Entries left in self.indent_key_stack_A_A at end: #{self.indent_key_stack_A_A[1 .. -1].column( 0 ).join(',')}"
            SE.q {[ 'self.record_H__stack_A' ]}
#           raise 
        end
        
        SE.puts "Right record count:        #{self.calculated_indent_right_rec_cnt}"       
        SE.puts "            forced:        #{self.forced_indent_right_rec_cnt}"  if ( self.forced_indent_right_rec_cnt > 0 )
        SE.puts "Left record count:         #{self.calculated_indent_left_rec_cnt}"
        SE.puts "            forced:        #{self.forced_indent_left_rec_cnt}"  if ( self.forced_indent_left_rec_cnt > 0 )  
        SE.puts "Calculated indent level:   #{self.current_calculated_indent_level}" if ( self.current_calculated_indent_level != 0 )
        SE.puts "****** Left/Right UNEQUAL" if ( ( self.calculated_indent_right_rec_cnt + self.forced_indent_right_rec_cnt ) != 
                                                 ( self.calculated_indent_left_rec_cnt  + self.forced_indent_left_rec_cnt  ) )
        SE.puts "Group record count:        #{self.group_rec_cnt}"
        SE.puts "File record count:         #{self.file_rec_cnt}"
        SE.puts "Total record count:        #{self.total_rec_cnt}"
#       SE.ap_stack
    end
    
    def adj_calculated_indent_level( num, indent_key_stack_A_A_maxindex )
        self.current_calculated_indent_level += num
        if ( self.current_calculated_indent_level != indent_key_stack_A_A_maxindex ) then
            SE.puts "#{SE.lineno}: self.current_calculated_indent_level != indent_key_stack_A_A_maxindex"
            SE.q{[ 'self.current_calculated_indent_level', 'indent_key_stack_A_A_maxindex' ]}
            raise
        end
        if ( self.current_calculated_indent_level < 0 ) then
            SE.puts "#{SE.lineno}: self.current_calculated_indent_level < 0!"
            raise
        end
    end

    def add_1_to_total_rec_cnt
    
    #       Useful to turn debug on and off at a specific record range.
    
        self.total_rec_cnt += 1
        SE.puts "#{SE.lineno}: ADD 1 TO TOTAL REC CNT ************" if ( $DEBUG )
        SE.q {[ 'self.total_rec_cnt' ]}  if ( $DEBUG )
#       SE.debug_on_the_range( self.total_rec_cnt, x..y )
    end
        
    def forced_indent_left( record_H )
        return if ( record_H.has_no_key?( K.fmtr_forced_indent ) ) 
        return if ( not ( record_H[ K.fmtr_forced_indent ].first == K.fmtr_left ) )
        record_H[ K.fmtr_forced_indent ].each do | e |
            if ( e != K.fmtr_left ) then
                SE.puts "#{SE.lineno}: Was expecting only K.fmtr_left in array."
                SE.q { [ 'record_H' ] }
                raise
            end
            output_record_H = {}
            output_record_H[ K.fmtr_indent ] = [ K.fmtr_left, K.fmtr_forced_indent ]
            puts output_record_H.to_json 
            SE.puts "#{SE.lineno}: FORCED INDENT LEFT ****** #{record_H}"   if ( $DEBUG )
            self.forced_indent_left_rec_cnt += 1
            add_1_to_total_rec_cnt
        end        
    end
    
    def calculated_indent_left( call_type )
        ld = SE::Loop_detector.new
        SE.q {[ 'self.record_H__stack_A.maxindex' ]}  if ( $DEBUG )
        SE.q {[ 'self.indent_key_stack_A_A.maxindex','self.indent_key_stack_A_A' ]}  if ( $DEBUG )
        SE.q {[ 'self.first_record_indent_keys_A.maxindex','self.first_record_indent_keys_A' ]}  if ( $DEBUG )
        indent_key_I = self.indent_key_stack_A_A.maxindex; loop do
            ld.loop
            break if ( indent_key_I <= 0 )  # The top/first entry is never popped.  
            SE.q {[ 'indent_key_I', 'self.first_record_indent_keys_A.maxindex' ]} if ( $DEBUG )
            SE.q {[ 'self.indent_key_stack_A_A[ indent_key_I ][ 0 ]' ]} if ( $DEBUG ) 
            stringer = self.indent_key_stack_A_A.column( 0 )[ 0 .. indent_key_I ].join.downcase
            SE.q {[ 'stringer' ]}  if ( $DEBUG )
            if (   indent_key_I > self.first_record_indent_keys_A.maxindex or 
                   stringer != self.first_record_indent_keys_A[ 0 .. indent_key_I ].join.downcase or
                   (   self.record_H__stack_A.maxindex < 0 and call_type == :special_last_record_call ) 
                ) then
                SE.q {[ 'self.first_record_indent_keys_A[ 0 .. indent_key_I ].join.downcase' ]} if ( $DEBUG )
                a1 = self.indent_key_stack_A_A.pop( 1 )[ 0 ]
                SE.q {[ 'self.indent_key_stack_A_A', 'self.indent_key_stack_A_A.maxindex' ]}  if ( $DEBUG )
                output_record_H = {}
                output_record_H[ K.fmtr_indent ] = [ K.fmtr_left, a1[ 0 ] ]
                puts output_record_H.to_json 
                SE.puts "#{SE.lineno}: CALCULATED INDENT LEFT *****************"  if ( $DEBUG )
                self.calculated_indent_left_rec_cnt += 1
                adj_calculated_indent_level( -1, self.indent_key_stack_A_A.maxindex )
                add_1_to_total_rec_cnt
            else
                SE.q {[ 'self.first_record_indent_keys_A[ 0 .. indent_key_I ].join.downcase' ]}  if ( $DEBUG )                
            end
            indent_key_I -= 1
        end
    end
    
    def forced_indent_right( record_H )
        return if ( record_H.has_no_key?( K.fmtr_forced_indent ) )
        return if ( not ( record_H[ K.fmtr_forced_indent ].first == K.fmtr_right ) )
        record_H[ K.fmtr_forced_indent ].each do | e |
            if ( e != K.fmtr_right ) then
                SE.puts "#{SE.lineno}: Was expecting only K.fmtr_right in array."
                SE.q { [ 'record_H' ] }
                raise
            end
            output_record_H = {}
            output_record_H[ K.fmtr_indent ] = [ K.fmtr_right, K.fmtr_forced_indent ]
            puts output_record_H.to_json
            SE.puts "#{SE.lineno}: FORCED INDENT RIGHT ****** #{record_H}"   if ( $DEBUG )
            self.forced_indent_right_rec_cnt += 1
            add_1_to_total_rec_cnt
        end
    end
    
    def calculated_indent_right
        SE.q {[ 'self.indent_key_stack_A_A' ]}  if ( $DEBUG )
        ld = SE::Loop_detector.new
        indent_key_I = -1; loop do 
            ld.loop
            indent_key_I += 1
            SE.q {[ 'indent_key_I', 'self.highest_matched_indent_key_idx_A.maxindex', 'self.highest_matched_indent_key_idx_A.min',
                    'self.indent_key_stack_A_A.maxindex', 'self.first_record_indent_keys_A.maxindex' ]}  if ( $DEBUG )
            if ( self.highest_matched_indent_key_idx_A.maxindex >= 0 and indent_key_I > self.highest_matched_indent_key_idx_A.min ) then
                break
            end

            SE.q {[ 'self.indent_key_stack_A_A.maxindex' ]}  if ($DEBUG)
            next  if  (  indent_key_I <= self.indent_key_stack_A_A.maxindex and
                         self.indent_key_stack_A_A[ indent_key_I ][ 0 ].downcase == self.first_record_indent_keys_A[ indent_key_I ].downcase ) 
                         
            if ( indent_key_I > self.indent_key_stack_A_A.maxindex )
            then
                if ( indent_key_I > self.first_record_indent_keys_A.maxindex ) then
                    SE.puts "indent_key_I > self.first_record_indent_keys_A.maxindex"
                    SE.q {[ 'indent_key_I', 'self.first_record_indent_keys_A', 'self.indent_key_stack_A_A' ]}
                    raise "Abort"
                end
                if  ( self.first_record_indent_keys_A[ indent_key_I ].in?( K.skip_these_values_for_indent_key_A ) ) then
                    SE.puts "#{SE.lineno}: Record group '#{self.first_record_indent_keys_A[ indent_key_I ]}' skipped " +
                            "due to being in 'K.skip_these_values_for_indent_key_A}'."
                    next
                end                    
                self.indent_key_stack_A_A.push( [ self.first_record_indent_keys_A[ indent_key_I ], 0 ] )  # Pushes the value and a 0 
                SE.q {[ 'self.indent_key_stack_A_A[ indent_key_I ]' ]}   if ( $DEBUG )
            end
            
            if ( indent_key_I <= 0 ) then
                SE.puts "#{SE.lineno}: Have you ever seen 'indent_key_I <= 0'?"  
                next
            end
            
            SE.q {[ 'indent_key_I', 'self.indent_key_stack_A_A' ]}  if ( $DEBUG )
            self.indent_key_stack_A_A[ indent_key_I - 1 ][ 1 ] += 1
            idx = -1; group_number_A = [ ]; loop do
                idx += 1
                break if ( idx >= indent_key_I or idx > self.indent_key_stack_A_A.maxindex )
                group_number_A << self.indent_key_stack_A_A[ idx ][ 1 ]   # Group numbers: n.n.n.etc...
            end 
            
            idx = 0; group_title_A = [ ]; loop do
                idx += 1
                break if ( idx > indent_key_I or idx > self.indent_key_stack_A_A.maxindex )
                group_title_A << self.indent_key_stack_A_A[ idx ][ 0 ]
            end

            self.indent_print_method.call( self.current_calculated_indent_level, group_number_A.deep_copy, group_title_A.deep_copy )
            self.group_rec_cnt += 1
            add_1_to_total_rec_cnt

            output_record_H={}
            output_record_H[ K.fmtr_indent ] = [ K.fmtr_right, "GROUP: #{group_title_A.join( ' ' ).sub( /[[:punct:]]\s*$/, '')}, indent_key_I=#{indent_key_I}" ]
            puts output_record_H.to_json
            SE.puts "#{SE.lineno}: CALCULATED INDENT RIGHT #{output_record_H[ K.fmtr_indent ]} *****************"  if ( $DEBUG )
            self.calculated_indent_right_rec_cnt += 1
            adj_calculated_indent_level( 1, self.indent_key_stack_A_A.maxindex )
            add_1_to_total_rec_cnt
        end 
    end
        
    def add_record( p1_new_record_H )
        SE.q {[ 'p1_new_record_H' ]}  if ( $DEBUG )
        if ( ! p1_new_record_H.empty? ) then
            self.record_H__stack_A.push( p1_new_record_H ) 
        end
        
        SE.q {[ 'self.record_stack_size_0R', 'self.record_H__stack_A', 'self.indent_key_stack_A_A' ]}  if ( $DEBUG )
        if ( self.record_H__stack_A.maxindex < self.record_stack_size_0R ) then
            self.first_record_indent_keys_A = [ ]
            SE.q {[ 'self.first_record_indent_keys_A' ]}  if ( $DEBUG )
            return
        end
              
        first_record_H = self.record_H__stack_A.shift( 1 )[ 0 ].merge( {} )
        self.first_record_indent_keys_A = self.indent_key_prefixes_A + first_record_H[ K.fmtr_record_indent_keys ]
#       SE.debug_on_the_range( first_record_H[ K.fmtr_record_num ].to_i, ( x..y ) )    # Original Record Number
        SE.puts "#{SE.lineno}: ORIGINAL RECORD NUMBER: #{first_record_H[ K.fmtr_record_num ]}"  if ( $DEBUG )
        SE.q {[ 'self.first_record_indent_keys_A' ]}  if ( $DEBUG )

        ld = SE::Loop_detector.new
        self.highest_matched_indent_key_idx_A = [ ] 
        self.record_H__stack_A.each_with_index do |other_record_H, record_stack_I|
            ld.loop
            SE.q {[ 'self.indent_key_prefixes_A','other_record_H[ K.fmtr_record_indent_keys]' ]}  if ( $DEBUG )
            other_record_indent_keys_A = self.indent_key_prefixes_A + other_record_H[ K.fmtr_record_indent_keys ] 
            indent_key_I = 0; loop do
                SE.q {[ 'indent_key_I', 'self.first_record_indent_keys_A.maxindex', 'other_record_indent_keys_A.maxindex' ]}  if ( $DEBUG )
                break if ( indent_key_I > self.first_record_indent_keys_A.maxindex or indent_key_I > other_record_indent_keys_A.maxindex )
                SE.q {[ 'indent_key_I', 'self.first_record_indent_keys_A[ indent_key_I ]', 'other_record_indent_keys_A[ indent_key_I ]' ]}  if ( $DEBUG )
                break if ( self.first_record_indent_keys_A[ indent_key_I ].downcase != other_record_indent_keys_A[ indent_key_I ].downcase )        
                indent_key_I += 1
            end
            indent_key_I -= 1  
            self.highest_matched_indent_key_idx_A[ record_stack_I ] = indent_key_I
            SE.q {[ 'self.highest_matched_indent_key_idx_A' ]}   if ( $DEBUG )
        end
        
        calculated_indent_left( :regular_non_end_of_file_call )

        if ( p1_new_record_H.not_empty? and self.highest_matched_indent_key_idx_A.not_empty? ) then
            matched_indent_key_indexes_are_in_desc_order = ( self.highest_matched_indent_key_idx_A.each_cons( 2 ).all?{|left, right| left >= right} )
            SE.q {[ 'matched_indent_key_indexes_are_in_desc_order' ]}  if ( $DEBUG )
            if ( matched_indent_key_indexes_are_in_desc_order ) then
                calculated_indent_right
            end
        end
        
        SE.puts "#{SE.lineno}: FILE RECORD: #{first_record_H}"  if ( $DEBUG )
        self.record_print_method.call( self.current_calculated_indent_level, self.record_H__stack_A.deep_copy, first_record_H )
        self.file_rec_cnt += 1
        add_1_to_total_rec_cnt
        
        if ( self.record_H__stack_A.maxindex < 0 ) then
            calculated_indent_left( :special_last_record_call )  # Flush out any left indents at last record.
        end

        forced_indent_left( first_record_H )
                               
        forced_indent_right( first_record_H )


    end
end

=begin

    How to use Record_Grouping_Indent
    
    require 'class.formatter.Record_Grouping_Indent.rb'

    Record_Grouping_Indent.new_with_flush( method( :put_record ), method( :put_indent ), desired_stacksize_0R, [ [ '/', 0 ] ]  ) do |rgi_O|

    ARGF.each_line do |input_record|                      #  << loop for each input record...

        input_record_H = JSON.parse( input_record )
        rgi_O.add_record( input_record_H )                #  << passing the input record to the stack process

    end

end
    Argument 1 is the data record write routine.
  
    Argument 2 is the indent record write routine.

    Argument 3 is how far to match "ahead".   So, this is the number of records stored in the stack.
    NOTE:  this is a Zero-Relative number.

    Argument 4 is an optional array of indent-key-prefixes (idx 0) and starting counter (idx 1).   The first indent-key-prefix is '/' (ie the-root).   
    If this key isn't found as the first entry of the array, [ '/', 0 ] will be prepended.  This allows the top-level of indentation to start
    at number 1 (0 + 1).  


    The indent-print routine is something like this:

def put_indent( level_number_A, level_title_A )
    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    case level_number_A.maxindex 
    when -1
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "Wasn't expecting param1 level_number_A to be empty"
        raise
    when 0
        output_record_H[ K.fmtr_record ][ K.level ] = K.series
        output_record_H[ K.fmtr_record ][ K.title ] = "Series #{level_number_A.join( ' ' )}: #{level_title_A.join( ' ' )}" 
    when 1
        output_record_H[ K.fmtr_record ][ K.level ] = K.subseries
        output_record_H[ K.fmtr_record ][ K.title ] = "Subseries #{level_number_A.join( ' ' )}: #{level_title_A.join( ' ' )}" 
    else     
        output_record_H[ K.fmtr_record ][ K.level ] = K.recordgrp
        output_record_H[ K.fmtr_record ][ K.title ] = "#{level_title_A.join( ' ' )}" 
    end
    puts output_record_H.to_json      # <<<< Write the indent record
end


    The record-print routine is something like this:

def put_record( stack_record_H )
    stack_record__indent_keys_A = stack_record_H[ K.fmtr_record_indent_keys ]
    stack_record__values_A = stack_record_H[ K.fmtr_record_values ]

    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = stack_record_H[ K.level ]
    stringer = stack_record__indent_keys_A[ 0..( stack_record__indent_keys_A.maxindex ) ].join( ' ' ) +
               ". " +
               stack_record__values_A[ 0..( stack_record__values_A.maxindex - 1 ) ].join( ' 'up )
    output_record_H[ K.fmtr_record ][ K.title ] = stringer.strip.gsub( /\.$/,'' )

    puts output_record_H.to_json    # <<<< Write the data record
end
=end
