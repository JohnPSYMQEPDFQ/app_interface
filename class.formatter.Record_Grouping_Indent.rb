=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                TC = top container
                IT = instance type
                AS = ArchivesSpace
                _H = Hash
                _A = Array
                _I = Index of Array
               _0R = Zero Relative

  See bottom for example of how to use.

=end

require 'module.Se.rb'

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
            Se.puts "#{Se.lineno}: param3, must be 1 or greater (and, it's 0-relative remember...)."
            raise
        end
        @record_stack_size_0R = stack_size_0R
        @record_stack_A = []
        if (! indent_keys_prefixes_A.empty?) then
            if (! indent_keys_prefixes_A[0].is_a?(Array)) then
                Se.puts "#{Se.lineno}: param4, must be an array of arrays" +
                        " (eg. [ [ '/', 0] ] -or- [ [ '/', 0 ], [ 'x', 3 ] ]"
                raise
            end
        end
        @indent_key_stack_A = indent_keys_prefixes_A
        if ( @indent_key_stack_A.empty? or @indent_key_stack_A[0][0] != '/' ) then
            @indent_key_stack_A.unshift( [ '/', 0 ])
        end
        @indent_key_prefixes_A = @indent_key_stack_A.transpose[0]
    end
    private_class_method :new

    def flush
        @record_stack_size_0R = 0
        loop do
            break if (@record_stack_A.maxindex < 0)
            self.add_record( {} )
        end
        Se.pp "@indent_key_stack_A:", @indent_key_stack_A if ( ! @indent_key_stack_A.empty? )
    end


    def add_record( p1_new_record_H )
        @record_stack_A.push( p1_new_record_H ) if (! p1_new_record_H.empty?)
        Se.pp "@record_stack_A:", @record_stack_A if ( $DEBUG )
        Se.pp "@record_stack_A.maxindex:", @record_stack_A.maxindex if ( $DEBUG )
        Se.pp "@indent_key_stack_A:", @indent_key_stack_A if ( $DEBUG )
        return {} if ( @record_stack_A.maxindex < @record_stack_size_0R ) 
    
        first_record_H = @record_stack_A.shift( 1 )[ 0 ]
        first_record_indent_keys_A = @indent_key_prefixes_A + first_record_H[ K.fmtr_record_indent_keys ]
        highest_matched_indent_key_idx_A = [ ] 
        @record_stack_A.each_with_index do |other_record_H, record_stack_I|
            other_record_indent_keys_A = @indent_key_prefixes_A + other_record_H[ K.fmtr_record_indent_keys ] 
            indent_key_I = 0; loop do
                Se.p "indent_key_I=#{indent_key_I}, " +
                     "first_record_indent_keys_A.maxindex=#{first_record_indent_keys_A.maxindex}, " +
                     "other_record_indent_keys_A.maxindex=#{other_record_indent_keys_A.maxindex}" if ( $DEBUG )
                break if ( indent_key_I > first_record_indent_keys_A.maxindex or indent_key_I > other_record_indent_keys_A.maxindex )
                Se.p "first_record_indent_keys_A[ #{indent_key_I} ]" +
                     "='#{first_record_indent_keys_A[ indent_key_I ]}', " +
                     "other_record_indent_keys_A[ #{indent_key_I} ]='#{other_record_indent_keys_A[ indent_key_I ]}'" if ( $DEBUG )
                break if ( first_record_indent_keys_A[ indent_key_I ].downcase != other_record_indent_keys_A[ indent_key_I ].downcase )
                indent_key_I += 1        
            end
            indent_key_I += -1        
            highest_matched_indent_key_idx_A[ record_stack_I ] = indent_key_I
            Se.p "highest_matched_indent_key_idx_A:", highest_matched_indent_key_idx_A if ( $DEBUG )
        end
        indent_key_I = @indent_key_stack_A.maxindex; loop do
            break if ( indent_key_I < 0 )
            Se.p "indent_key_I=#{indent_key_I}" if ( $DEBUG )
            Se.p "@indent_key_stack_A.maxindex=#{@indent_key_stack_A.maxindex}" if ( $DEBUG )
            Se.p "@indent_key_stack_A[ indent_key_I ][ 0 ]" +
                 "=#{@indent_key_stack_A[ indent_key_I ][ 0 ]}" if ( $DEBUG )
            Se.p "first_record_indent_keys_A.maxindex=#{first_record_indent_keys_A.maxindex}" if ( $DEBUG )
            if (   indent_key_I > first_record_indent_keys_A.maxindex or
                   @indent_key_stack_A[ indent_key_I ][ 0 ].downcase != first_record_indent_keys_A[ indent_key_I ].downcase ) then
                a1 = @indent_key_stack_A.pop( 1 )[ 0 ]
                output_record_H = {}
                output_record_H[ K.fmtr_indent ] = [ K.fmtr_left, a1[ 0 ] ]
                puts output_record_H.to_json 
            else
                Se.p "first_record_indent_keys_A[ indent_key_I ].downcase=" +
                     "#{first_record_indent_keys_A[ indent_key_I ].downcase}" if ( $DEBUG )
            end
            indent_key_I += -1
        end 
        if ( highest_matched_indent_key_idx_A.maxindex >= 0 ) then
            matched_indent_key_indexes_are_in_desc_order = ( highest_matched_indent_key_idx_A.each_cons( 2 ).all?{|left, right| left >= right} )
            Se.p "matched_indent_key_indexes_are_in_desc_order" + 
                 "=#{matched_indent_key_indexes_are_in_desc_order}" if ( $DEBUG )
            if ( matched_indent_key_indexes_are_in_desc_order ) then
                indent_key_I = -1; loop do 
                    indent_key_I += 1
                    Se.p "indent_key_I=#{indent_key_I} " +
                         "highest_matched_indent_key_idx_A.min=#{highest_matched_indent_key_idx_A.min} " +
                         "@indent_key_stack_A.maxindex=#{@indent_key_stack_A.maxindex} " +
                         "first_record_indent_keys_A.maxindex=#{first_record_indent_keys_A.maxindex} " if ( $DEBUG )
                    break if ( indent_key_I > highest_matched_indent_key_idx_A.min )
                    Se.p "indent_key_I=#{indent_key_I} " +
                         "@indent_key_stack_A.maxindex=#{@indent_key_stack_A.maxindex}" if ($DEBUG)
                    if  (  indent_key_I > @indent_key_stack_A.maxindex or
                           @indent_key_stack_A[ indent_key_I ][ 0 ].downcase != first_record_indent_keys_A[ indent_key_I ].downcase ) then
                        if ( indent_key_I > @indent_key_stack_A.maxindex )
                        then
                            @indent_key_stack_A[ indent_key_I ] = [ first_record_indent_keys_A[ indent_key_I ], 0 ]
                            Se.p "@indent_key_stack_A[ #{indent_key_I} ]" +
                                 "=#{@indent_key_stack_A[ indent_key_I ]}" if ( $DEBUG )
                        end
                        if ( indent_key_I > 0 ) then
                            @indent_key_stack_A[ indent_key_I - 1 ][ 1 ] += 1
                            idx = -1; group_numbers_A = [ ]; loop do
                                idx += 1
                                break if ( idx >= indent_key_I )
                                group_numbers_A << @indent_key_stack_A[ idx ][ 1 ]   # Group numbers: n.n.n.etc...
                            end 
                            idx = 0; group_text_A = [ ]; loop do
                                idx += 1
                                break if ( idx > indent_key_I )
                                group_text_A << @indent_key_stack_A[ idx ][ 0 ]
                            end
                            @indent_print_method.call( group_numbers_A, group_text_A )
                            output_record_H={}
                            output_record_H[ K.fmtr_indent ] = [ K.fmtr_right,  "GROUP #{group_numbers_A.join( "." )}: #{group_text_A.join( ". " )}" ]
                            puts output_record_H.to_json
                        end
                    end
                end 
            end
        end
        @record_print_method.call( first_record_H )
    end
end

=begin

    How to use Record_Grouping_Indent

    rgi_O.new_with_flush( method( :put_record ), method( :put_indent ), desired_stacksize_0R, [ [ '/', 0 ] ]  ) do |rgi_O|

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
        Se.puts "#{Se.lineno}: =============================="
        Se.puts "Wasn't expecting param1 level_number_A to be empty"
        raise
    when 0
        output_record_H[ K.fmtr_record ][ K.level ] = K.series
        output_record_H[ K.fmtr_record ][ K.title ] = "Series #{level_number_A.join( "." )}: #{level_title_A.join( ". " )}" 
    when 1
        output_record_H[ K.fmtr_record ][ K.level ] = K.subseries
        output_record_H[ K.fmtr_record ][ K.title ] = "Subseries #{level_number_A.join( "." )}: #{level_title_A.join( ". " )}" 
    else     
        output_record_H[ K.fmtr_record ][ K.level ] = K.recordgrp
        output_record_H[ K.fmtr_record ][ K.title ] = "#{level_title_A.join( ". " )}" 
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
    stringer = stack_record__indent_keys_A[ 0..( stack_record__indent_keys_A.maxindex ) ].join( ". " ) +
               ". " +
               stack_record__values_A[ 0..( stack_record__values_A.maxindex - 1 ) ].join( " " )
    output_record_H[ K.fmtr_record ][ K.title ] = stringer.strip.gsub( /\.$/,'' )

    puts output_record_H.to_json    # <<<< Write the data record
end
=end
