=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                TC = top container
                IT = instance type
                AS = ArchivesSpace
                _H = Hash
                _A = Array
                _I = Index (of Array)
               _0R = Zero Relative

Usage: format_for_add_object.rb --help


=end

require "json"
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'

require 'class.archivesspace.rb'

class Record_Rollup

    def self.new_with_flush(*args)
        myself_O = new(*args)
        yield myself_O
        myself_O.flush
    end

    def initialize(put_method)
        @put_method = put_method
        @record_stack_A = []
    end
    
    def add_record(p1_rec_A)   
        if (! (p1_rec_A.empty?)) then
            push_it = false
            if ( @record_stack_A.maxindex < 0 ) then
                push_it = true
            else
                a1 = @record_stack_A [0]
                if ( a1 [1] == p1_rec_A [1] and a1 [2] == p1_rec_A [2] ) then
                    push_it = true
                end
            end
            if ( push_it ) then
                @record_stack_A.push( p1_rec_A )
                return 
            end
        end
#       p "@record_stack_A = #{@record_stack_A}"
#       p "@record_stack_A.maxindex = #{@record_stack_A.maxindex}"
 
        @put_method.call( @record_stack_A[0], @record_stack_A[ @record_stack_A.maxindex ] )
        @record_stack_A = [] 
        if (! (p1_rec_A.empty?)) then
            @record_stack_A.push( p1_rec_A )
        end
    end

    def flush 
        if ( @record_stack_A.maxindex >= 0) then
            add_record( {} )
        end
    end

end


def put_record( a1, a2 )
#   box_id = "Undetermined as-of March-2020"

#   if ( a1[ 0 ] == a2 [ 0 ] ) then
#       stringer = "#{a1 [ 0 ]}"
#   else
#       stringer = "#{ a1[ 0 ]} through #{a2[ 0 ]}"
#   end
#   fmtr_container_H = { K.fmtr_tc_type => K.box ,
#                        K.fmtr_tc_indicator => box_id ,
#                        K.fmtr_sc_type => K.folder ,
#                        K.fmtr_sc_indicator' => stringer ,
#                      }

    output_record_H = {}
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = K.file
    output_record_H[ K.fmtr_record ][ K.title ] = a1[ 1 ]
#   output_record_H[ K.fmtr_record ][ K.fmtr_container ] = fmtr_container_H
    output_record_H[ K.fmtr_record ][ K.dates ] = [ ]

    if ( a1[ 2 ] != "" ) then
        single_date_fragment_O = Record_Format.new( :single_date )
        single_date_fragment_O.record_H= { K.label => K.existence }
        single_date_fragment_O.record_H= { K.begin => a1[ 2 ] }
        output_record_H[ K.fmtr_record ][ K.dates ].push( single_date_fragment_O.record_H )
    end

    puts output_record_H.to_json
end


BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option = { "last-record-num" => nil }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [--last-record-num n ]"
    option.on( "--last-record-num n", OptionParser::DecimalInteger, "Stop after record N" ) do |opt_arg|
        cmdln_option[ 'last-record-num' ] = opt_arg
    end
    option.on( "-h","--help" ) do
        warn option
        exit
    end
end.parse!  # Bang because ARGV is altered
last_record_num = cmdln_option[ 'last-record-num' ]

Record_Rollup.new_with_flush( method( 'put_record' ) ) do |rr_O|

    ARGF.each_line do |input_record|
    
        if ( ! last_record_num.nil? and $. >= last_record_num ) then 
            break
        end
    
        input_record.chomp!
        p "input_record:",  input_record if ( $DEBUG )
        if ( input_record.match?( /^\s*$/ ) ) then
            next
        end
    
        a1 = input_record.split( ';',-1 ).map( &:to_s ).map( &:strip )
        
        rr_O.add_record( a1 )
    end
end
