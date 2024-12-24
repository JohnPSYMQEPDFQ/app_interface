=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                TC = top container
                IT = instance type
                AS = ArchivesSpace
                _H = Hash
                _A = Array
                _O = Object
               _0R = Zero Relative

Usage: format_for_add_object.rb --help


=end

require 'json'
require 'optparse'

require 'class.ArchivesSpace.rb'
require 'class.formatter.Record_Grouping_Indent.rb'

def put_indent( group_number_A, group_title_A )
    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    case group_number_A.length 
    when 0
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "Wasn't expecting param1 group_number_A to be empty"
        raise
    when 1 .. @cmdln_option_H[ :max_series ]
        output_record_H[ K.fmtr_record ][ K.level ] = K.series
        title = "Series"
        if ( group_number_A.length <= @cmdln_option_H[ :max_levels ] ) then
            title += " #{group_number_A.join( "." )}" 
            output_record_H[ K.fmtr_record ][ K.component_id ] = group_number_A.join( "." )
        end
        title += ": #{group_title_A.join( ". " )}"  
        output_record_H[ K.fmtr_record ][ K.title ] = title
    
    when 2 .. @cmdln_option_H[ :max_series ] 
        output_record_H[ K.fmtr_record ][ K.level ] = K.subseries
        title = "Subseries"
        if ( group_number_A.length <= @cmdln_option_H[ :max_levels ] ) then
            title += " #{group_number_A.join( "." )}" 
            output_record_H[ K.fmtr_record ][ K.component_id ] = group_number_A.join( "." ) 
        end
        title += ": #{group_title_A.join( ". " )}"  
        output_record_H[ K.fmtr_record ][ K.title ] = title        
    else     
        output_record_H[ K.fmtr_record ][ K.level ] = K.recordgrp
        title = group_title_A.join( ". " )
        output_record_H[ K.fmtr_record ][ K.title ] = title
    end
    puts output_record_H.to_json
end

def put_record( stack_record_H )

    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = stack_record_H[ K.level ]
    
    a1 = stack_record_H[ K.fmtr_record_indent_keys ].push( stack_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__text_idx ] )
    title = a1.join( ". " )
    output_record_H[ K.fmtr_record ][ K.title ] = title.strip.gsub( /[\.\,]$/,'' )
    if ( output_record_H[ K.fmtr_record ][ K.title ].blank? )
        SE.puts "output_record_H[ K.fmtr_record ][ K.title ] is blank"
        SE.q {[ 'stack_record_H', 'output_record_H' ]}
        raise
    end
    
    output_record_H[ K.fmtr_record ][ K.dates ] = [ ]
    date_A_A = stack_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__dates_idx ]
    if ( date_A_A && date_A_A.maxindex >= 0 ) then
        date_A_A.each do | date_A |
            case date_A.maxindex
            when 0
                inclusive_dates_O = Record_Format.new( :inclusive_dates )
                inclusive_dates_O.record_H[ K.label ] = K.creation 
                inclusive_dates_O.record_H[ K.begin ] = date_A[ 0 ]
                inclusive_dates_O.record_H[ K.end ] = date_A[ 0 ]
                inclusive_dates_O.record_H[ K.expression] = @aspace_O.format_date_expression( date_A[ 0 ] )
                output_record_H[ K.fmtr_record ][ K.dates ].push( inclusive_dates_O.record_H )
            when 1
                inclusive_dates_O = Record_Format.new( :inclusive_dates )
                inclusive_dates_O.record_H[ K.label ] = K.creation 
                inclusive_dates_O.record_H[ K.begin ] = date_A[ 0 ]
                inclusive_dates_O.record_H[ K.end ] = date_A[ 1 ]             
                inclusive_dates_O.record_H[ K.expression] = @aspace_O.format_date_expression( date_A[ 0 ], date_A[ 1 ] )
                output_record_H[ K.fmtr_record ][ K.dates ].push( inclusive_dates_O.record_H )
            else
                SE.puts "#{SE.lineno}: Didn't expect date_A.maxindex to be > 1, the value is: #{date_A.maxindex}"
                SE.q {[ 'date_A' ]}
                raise
            end
        end
    end

    output_record_H[ K.fmtr_record ][ K.notes ] = [ ]
    note_A = stack_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__notes_idx ]
    if ( note_A && note_A.maxindex >= 0 ) then
        if ( output_record_H[ K.fmtr_record ][ K.level ].in?( [ K.series, K.subseries, K.recordgrp ] )) then
            note_multipart_O = Record_Format.new( :note_multipart )
            note_multipart_O.record_H = { K.type => K.scopecontent }
            note_multipart_O.record_H = { K.subnotes => [ ] } 

            note_text_O = Record_Format.new( :note_text )
            stringer = note_A.join( "\n\n" )
            note_text_O.record_H = { K.content => "#{stringer}" }
            
            note_multipart_O.record_H[ K.subnotes ].push( note_text_O.record_H )
            
            output_record_H[ K.fmtr_record ][ K.notes ].push( note_multipart_O.record_H )
        else
            note_A.each do | note |
                note_singlepart_O = Record_Format.new( :note_singlepart )
                note_singlepart_O.record_H = { K.type  => K.materialspec }
                note_singlepart_O.record_H = { K.content => [ "#{note}" ] }
                output_record_H[ K.fmtr_record ][ K.notes ].push( note_singlepart_O.record_H )
            end
        end
    end

    container_H = stack_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__container_idx ]
    if ( container_H && ! container_H.empty? ) then
        output_record_H[ K.fmtr_record ][ K.fmtr_container ] = container_H
    end
    puts output_record_H.to_json
end

def put_new_parent( title )
    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = K.fmtr_new_parent
    output_record_H[ K.fmtr_record ][ K.title ] = title
    puts output_record_H.to_json
end

BEGIN {}
END {}

myself_name = File.basename( $0 )

#   Note that:  The "Class variables" can be used in "programs", which means that
#               the program itself is somewhat like a class.
@cmdln_option_H = { :min_group_size => 4, 
                    :max_series => 0,
                    :max_levels => nil,
                    :parent_title => nil,
                    :r => nil,
                  }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"

    option.on( "--min-group-size n", OptionParser::DecimalInteger, "Min records in a Series/Subseries/Record-group (default = 4)" ) do |opt_arg|
        @cmdln_option_H[ :min_group_size ] = opt_arg
    end
    option.on( "--max-series n", OptionParser::DecimalInteger, "Max number of Series/Subseries (default = 0)" ) do |opt_arg|
        @cmdln_option_H[ :max_series ] = opt_arg
    end
    option.on( "--max-levels n", OptionParser::DecimalInteger, "Max number of N.N.N things to show (default --max-series)" ) do |opt_arg|
        @cmdln_option_H[ :max_levels ] = opt_arg
    end
    option.on( "--parent-title x", "The title of the record to attach the rest of the records too" ) do |opt_arg|
        @cmdln_option_H[ :parent_title ] = opt_arg
    end
    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        @cmdln_option_H[ :r ] = opt_arg
    end
    option.on( "-h", "--help" ) do
        warn option
        exit
    end
end.parse!  # Bang because ARGV is altered
@cmdln_option_H[ :min_group_size ] -= 1                   # min-group-size is zero relative.
@cmdln_option_H[ :min_group_size ] = 0 if ( @cmdln_option_H[ :min_group_size ] < 0 )

if ( not @cmdln_option_H[ :max_levels] ) then
    @cmdln_option_H[ :max_levels ] = @cmdln_option_H[ :max_series]
end

if ( @cmdln_option_H[ :parent_title ] ) then
    put_new_parent( @cmdln_option_H[ :parent_title ] )
end

@aspace_O = ASpace.new
@aspace_O.date_expression_format    = 'mmmddyyyy'
@aspace_O.date_expression_separator = ' - '

Record_Grouping_Indent.new_with_flush( method( :put_record ), method( :put_indent ), @cmdln_option_H[ :min_group_size ] ) do |rgi_O|
#   $DEBUG = true   
    ARGF.each_line do | input_record_J |
        input_record_H = JSON.parse( input_record_J )
        if ( @cmdln_option_H[ :r ] and $. > @cmdln_option_H[ :r ] ) then 
            break
        end
        SE.q {[ 'input_record_H' ]} if ( $DEBUG )
        begin
            rgi_O.add_record( input_record_H )   
        rescue
            SE.puts "#{SE.lineno}: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            raise
        end
    end

end
