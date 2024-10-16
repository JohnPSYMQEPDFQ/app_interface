require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'tempfile'

=begin 
      For the InMagic to ArchivesSpace Resource Record conversion the following inforation is known
      as-of 10/14/2024

          InMagic Column            -> ArchivesSpace equivalent

          Historical Information    -> Biography
          Series Summary            -> Arrangement
          Additional Access         ->
          Provenance                -> Immediate Source of Acquisition
          Extent                    -> Date (but the box nos. will have to be removed)

=end



myself_name = File.basename( $0 )

@valid_column_uses_H = { 'detail'       => { :split_on_bars => true  ,  :use_for_indentation => true } ,
                         'series'       => { :split_on_bars => false ,  :use_for_indentation => true } ,
                         'seriesnote'   => { :split_on_bars => false ,  :use_for_indentation => false }  ,
                       }

@cmdln_opt_H = { :r => 999999999,
                 :d => false,
                 :column_order_A => [],
                 :column_use_A => [],
                 :delimiter => '~',
               }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"

    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        @cmdln_opt_H[ :r ] = opt_arg
    end

    option.on( "--columns=NAME[:use][,NAME:use]...", "Order and use of the columns") do |opt_arg|
        a1 = opt_arg.split( ',' ).map( &:to_s ).map( &:strip )
        a1.each_with_index do | stringer, idx |
            a2 = stringer.split( ':' ).map( &:to_s ).map( &:strip )
            @cmdln_opt_H[ :column_order_A ].push( a2[ 0 ] )
            if ( a2[ 1 ] ) then
                if ( a2[ 1 ].downcase.in?( @valid_column_uses_H.keys ) ) then
                    @cmdln_opt_H[ :column_use_A ].push( a2[ 1 ] )
                else
                    SE.puts "Unknown column use '#{a2[ 1 ]}' on column '#{a2[ 0 ]}'"
                    SE.q {[ '@cmdln_opt_H' ]}
                    raise
                end
            else
                @cmdln_opt_H[ :column_use_A ].push( 'detail' )
            end
        end
    end

    option.on( "--delimiter=X", "Split on delimiter X (default is '~')" ) do |opt_arg|
        @cmdln_opt_H[ :delimiter ] = opt_arg
    end

    option.on( "-d", "Turn on $DEBUG switch" ) do
        $DEBUG=true
    end

    option.on( "-h", "--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
SE.q {[ '@cmdln_opt_H' ]}


def delimiter()
    @cmdln_opt_H[ :delimiter ]
end

def use_column_for_indentation?( column_idx )
    return get_column_use_for( column_idx, :use_for_indentation )
end
def split_column_on_bars?( column_idx )
    return get_column_use_for( column_idx, :split_on_bars )
end
def get_column_use_for( column_idx, column_control )
    SE.q {[ '@cmdln_opt_H[ :column_use_A ]' ]}  if ( $DEBUG )
    SE.q {[ '@cmdln_opt_H[ :column_use_A ][ column_idx ]' ]}   if ( $DEBUG )
    SE.q {[ '@valid_column_uses_H[ @cmdln_opt_H[ :column_use_A ][ column_idx ]]' ]}   if ( $DEBUG )
    SE.q {[ '@valid_column_uses_H[ @cmdln_opt_H[ :column_use_A ][ column_idx ]][ column_control ]' ]}  if ( $DEBUG )
    use = @cmdln_opt_H[ :column_use_A ][ column_idx ]
    if ( ! @valid_column_uses_H.has_key?( use ) ) then
        SE.puts "No column_use key (#{use}) in @valid_column_uses_H"
        SE.q {[ 'column_idx', '@valid_column_uses_H' ]}
        raise
    end
    if ( ! @valid_column_uses_H[ use ].has_key?( column_control ) ) then
        SE.puts "No column_use key ([#{ use }][ #{column_control} ]) in @valid_column_uses_H"
        SE.q {[ 'column_idx', 'use', 'column_control', '@valid_column_uses_H' ]}
        raise
    end
    return @valid_column_uses_H[ use ][ column_control ]
end

def put_column( column_A, column_idx, prefix )
    SE.q { [:column_idx, :prefix, :column_A ]}  if ( $DEBUG )
    if ( matchdata = column_A[ column_idx ].match( /^"(.*)"$/ ) ) then
        column_A[ column_idx ] = matchdata[ 1 ]
    end

    if ( split_column_on_bars?( column_idx )) then
        sub_column_A = column_A[ column_idx ].split( '|' ).map( &:to_s ).map( &:strip ) 
    else
        if ( column_A[ column_idx ].include?( '|' )) then
            SE.puts "non-bar column has a '|'"
            SE.q {[ 'column_idx', 'column_A' ]}
            raise
        end
        sub_column_A = [ column_A[ column_idx ] ]
    end
    SE.q { :sub_column_A } if ( $DEBUG )
    if ( sub_column_A.empty? ) then
        sub_column_A << " "
    end 
    sub_column_A.each do | sub_column |
        if ( sub_column.count( '"' ) % 2 != 0 ) then
            SE.puts "#{SE.lineno}: Odd number of double-quotes found in 'sub_column'"
            SE.q {[ 'sub_column', 'sub_column_A' ]}
            raise
        end
        if ( column_idx < column_A.maxindex ) then
            if ( use_column_for_indentation?( column_idx ) ) then
                puts sub_column 
                stringer = sub_column + ''
                stringer.sub!( /\s+#{K.fmtr_inmagic_quote}(#{K.series}|#{K.subseries}).*#{K.fmtr_inmagic_quote}/i, '' )
                stringer.sub!( / Note: .*\Z/i, '' )
                puts "Prepend: #{stringer}" 
            end
            put_column( column_A, column_idx + 1, prefix )
            puts "Drop:" if ( use_column_for_indentation?( column_idx ) )
        else
            puts sub_column if ( use_column_for_indentation?( column_idx ) )
        end
    end
end

tmp1_F = Tempfile.new( "#{myself_name}.tmp1_F." )
#SE.puts "tmp1_F.path=#{tmp1_F.path}"
column_has_data_A = []
original_file_header_A = []

ARGF.each_line do | input_record |   # Scan entire file for which columns are used 
    if ( $. > @cmdln_opt_H[ :r ] ) then 
        SE.puts ""
        SE.puts "Stopped after #{@cmdln_opt_H[ :r ]} records."
        SE.puts ""
        break
    end
    input_record.chomp!
    input_record.gsub!( '""', '"' )
    next if ( input_record =~ /^\s*$/ )

    input_record_A = input_record.split( delimiter ).map( &:to_s ).map( &:strip )
    if ( $. == 1 ) then
        original_file_header_A=input_record_A
    else
        input_record_A.each_with_index do | column, idx |
            if ( column > "" and column_has_data_A[ idx ].nil? ) then
                stringer = (column.include?( '|' ) ) ? '*|*' : "   "
                column_has_data_A[ idx ] = "#{stringer} Line=#{$.} '#{original_file_header_A[ idx ]}' #{column}"
            end
        end
    end

    tmp1_F.puts input_record  # Not worth Json'ing it...
end
tmp1_F.close
tmp1_F.open
tmp2_F = Tempfile.new( "#{myself_name}.tmp2_F." )

SE.q {['column_has_data_A']}
used_column_header_A = []
original_column_idx_xref_A = []
tmp1_F.each_line do | input_record |    # Select the columns wanted based on the --columns option
    input_record.chomp!
    column_A=[]
    SE.puts "$.=#{$.} #{input_record}" if ( $DEBUG )
    input_record_A = input_record.split( delimiter ).map( &:to_s ).map( &:strip )
    input_record_A.each_with_index do | column, idx |
        if ( column_has_data_A[ idx ].nil? ) then
            next
        end
        column_A << column    
    end

    if ( $. == 1 ) then
        used_column_header_A = column_A
        if ( used_column_header_A.uniq.size != used_column_header_A.size ) then
            SE.puts "Non-unique column header found!"
            SE.q {[ 'sed.column_header_A', 'sed.column_header_A.sort' ]}
            raise
        end
        if ( @cmdln_opt_H[ :column_order_A ] == [] ) then
            @cmdln_opt_H[ :column_order_A ] = used_column_header_A 
            @cmdln_opt_H[ :column_use_A ] = Array.new( used_column_header_A.length ) {""} 
        else
            if ( @cmdln_opt_H[ :column_order_A ].uniq.size != @cmdln_opt_H[ :column_order_A ].size ) then
                SE.puts "Non-unique column found in --columns option"
                SE.puts {[ '@cmdln_opt_H[ :column_order_A ]' ]}
                raise
            end
            a1 = @cmdln_opt_H[ :column_order_A ] - used_column_header_A           
            if ( a1 != [] ) then
                SE.puts ""
                SE.puts ""
                SE.puts "Unknown column '#{a1.join(', ')}' in --columns option"
                SE.puts ""
                SE.q {[ '@cmdln_opt_H[ :column_order_A ]', 'used_column_header_A' ]}
                raise
            end
            a1 = used_column_header_A - @cmdln_opt_H[ :column_order_A ]
            if ( a1 != [] ) then
                SE.puts "The following columns are being skipped:"
                SE.puts "'#{a1.join(', ')}'"
            end
            used_column_header_A = @cmdln_opt_H[ :column_order_A ]
        end
        original_column_idx_xref_A = @cmdln_opt_H[ :column_order_A ].map{ | column_name | original_file_header_A.index( column_name )}
        SE.puts ""
        SE.puts "Input columns being used: #{used_column_header_A.join( ', ' )}"
        SE.puts " which are input columns: #{original_column_idx_xref_A.join( ', ')} (ZERO relative)"
        if ( @cmdln_opt_H[ :column_use_A ].all?( &:empty? ) ) then
            SE.puts ""
            SE.puts ""
            SE.puts ""
            SE.puts "Provide the --columns option to get past this point."
            SE.puts ""
            exit
        end
        SE.puts "  in the following order: #{@cmdln_opt_H[ :column_order_A ].join( ', ' )}"
        SE.puts "   for the following use: #{@cmdln_opt_H[ :column_use_A ].join( ', ' )}"
        if ( @cmdln_opt_H[ :column_use_A ].uniq.size == 1 ) then
            SE.puts ""
            SE.puts ""
            SE.puts ""
            SE.puts "All the column uses are the same!"
            SE.puts ""
            exit
        end
        SE.puts ""   
        next    
    end
    a1 = original_column_idx_xref_A.map{ | idx | column_A[ idx ]}
    next if ( a1.all?(&:empty? ) )
    tmp2_F.puts a1.join( delimiter )
end
tmp1_F.close( true )

tmp2_F.close
tmp2_F.open

#   Below here, the TEMPFILES only have the "used columns". But NOTE, it's important to keep the number of columns
#   the same as the 'used_column_header_A' and 'original_column_idx_xref_A' were created from what's writen to tmp2_F (above).

tmp3_F = Tempfile.new( "#{myself_name}.tmp3_F." )
tmp2_F.each_line do | input_record |
    input_record.chomp!
    input_record_A = input_record.split( delimiter ).map( &:to_s ).map( &:strip )
    column_A = []
    @cmdln_opt_H[ :column_order_A ].each_with_index do | column_ordered, column_ordered_idx |       
        if ( used_column_header_A.index( column_ordered ).nil? ) then
            SE.puts "Couldn't find '#{column_ordered}' from '@cmdln_opt_H[ :column_order_A ]' in 'used_column_header_A'"
            SE.q {[ '@cmdln_opt_H[ :column_order_A ]', 'used_column_header_A' ]}
            raise
        end
        input_record_idx = used_column_header_A.index( column_ordered ) 
        case @cmdln_opt_H[ :column_use_A ][ column_ordered_idx ].downcase
        when 'seriesnote'
            if ( column_ordered_idx == 0 ) then
                SE.puts "The 1st column can't have a 'use' of type 'seriesnote'"
                SE.q {[ '@cmdln_opt_H[ :column_order_A ] ' ]}
                raise
            end
            if ( @cmdln_opt_H[ :column_use_A ][ column_ordered_idx - 1 ] != 'series' ) then
                SE.puts "The 'seriesnote' column must be immediately after the 'series' column"
                SE.q {[ 'column_ordered_idx', '@cmdln_opt_H[ :column_use_A ] ' ]}
                raise
            end
            if ( input_record_A[ input_record_idx ].not_empty? ) then
#               column_A[ column_A.maxindex ] += " #{K.fmtr_inmagic_quote}#{K.note_text} #{input_record_A[ input_record_idx ]}#{K.fmtr_inmagic_quote}"
                column_A[ column_A.maxindex ] += " Note: #{input_record_A[ input_record_idx ]}"
            end
            column_A << ""  # This is used to keep the number of columns the same.
        when 'series'
            input_record_A[ input_record_idx ].sub!( /\A([0-9])+[.]?\s+/, '' )
            if ( $~.nil? ) then
                SE.puts "Used column #{input_record_idx} (input column #{original_column_idx_xref_A[ input_record_idx ]}) is supposed to be a 'series' but there's no series number"
                SE.puts "at the begining of the column."
                SE.q {[ 'input_record_A[ input_record_idx ]' ]}
                raise
            end
            column_A << "#{input_record_A[ input_record_idx ]} #{K.fmtr_inmagic_quote}#{K.series} #{$~[ 1 ]}#{K.fmtr_inmagic_quote}"
        else    
            column_A << input_record_A[ input_record_idx ]
        end
    end         
    if ( column_A.maxindex != used_column_header_A.maxindex ) then
        SE.puts "column_A.maxindex != used_column_header_A.maxindex."
        SE.q {[ 'column_A', 'used_column_header_A' ]}
        raise
    end
    next if ( column_A.all?( &:empty?) )
    tmp3_F.puts column_A.join( delimiter )
end
tmp2_F.close( true )

tmp3_F.close
tmp3_F.open

tmp3_F.each_line do | input_record |
    input_record.chomp!
    SE.puts "$.=#{$.} #{input_record}" if ( $DEBUG )
    if ( input_record.count( '"' ) % 2 != 0 ) then
        SE.puts "#{SE.lineno}: Odd number of double-quotes found in 'input_record'"
        SE.q {[ 'input_record' ]}
        raise
    end
    column_A = input_record.split( delimiter ).map( &:to_s ).map( &:strip )
    if ( column_A.maxindex != used_column_header_A.maxindex ) then
        SE.puts "column_A.maxindex != used_column_header_A.maxindex."
        SE.q {[ 'column_A', 'used_column_header_A' ]}
        raise
    end
    put_column( column_A, 0, [] )
end
tmp3_F.close( true )


