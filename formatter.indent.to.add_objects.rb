# frozen_string_literal: true

=begin

Usage: format_for_add_object.rb --help

=end

require 'json'
require 'optparse'
require 'class.ArchivesSpace.rb'
require 'class.formatter.Record_Grouping_Indent.rb'

module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :cmdln_option_H, :output_fd3_F
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...


def put_indent( p1_calculated_indent_level, p2_group_number_A, p3_group_title_A )
    SE.q {'p3_group_title_A'}  if ( $DEBUG )
    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    case p2_group_number_A.length 
    when 0
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "Wasn't expecting param1 p2_group_number_A to be empty"
        raise
    when 1 .. self.cmdln_option_H[ :max_series ]
        output_record_H[ K.fmtr_record ][ K.level ] = K.series.downcase
        stringer = +"Series"
        if ( p2_group_number_A.length <= self.cmdln_option_H[ :max_levels ] ) then
            stringer << " #{p2_group_number_A.join( '.' )}" 
            output_record_H[ K.fmtr_record ][ K.component_id ] = p2_group_number_A.join( '.' )
        end
        stringer << ": #{p3_group_title_A.join( ' ' )}"  
        output_record_H[ K.fmtr_record ][ K.title ] = stringer
    
    when 2 .. self.cmdln_option_H[ :max_series ] 
        output_record_H[ K.fmtr_record ][ K.level ] = K.subseries.downcase
        stringer = +"Subseries"
        if ( p2_group_number_A.length <= self.cmdln_option_H[ :max_levels ] ) then
            stringer << " #{p2_group_number_A.join( '.' )}" 
            output_record_H[ K.fmtr_record ][ K.component_id ] = p2_group_number_A.join( '.' ) 
        end
        stringer << ": #{p3_group_title_A.join( ' ' )}"   
        output_record_H[ K.fmtr_record ][ K.title ] = stringer
    else     
        output_record_H[ K.fmtr_record ][ K.level ]       = K.otherlevel
        output_record_H[ K.fmtr_record ][ K.other_level ] = K.group.capitalize
        output_record_H[ K.fmtr_record ][ K.title ]       = p3_group_title_A.last
    end
    if ( output_record_H[ K.fmtr_record ][ K.title ].blank? ) then
        SE.puts "#{SE.lineno}: Title can't be blank."
        SE.q {'p3_group_title_A'}
        raise
    end
    
    output_record_H[ K.fmtr_record ][ K.title ].sub!( /[.,:;]\s*$/, '' )
    output_record_H[ K.fmtr_record ][ K.title ].sub!( /./,&:upcase )
    output_record_H[ K.fmtr_record ][ K.title ].strip!

    self.output_fd3_F.puts 'I %-13s: ' % output_record_H[ K.fmtr_record ][ K.level ] +
                           'L %1d ' % p1_calculated_indent_level + p3_group_title_A.join( "| " )
    puts output_record_H.to_json
end

def put_record( p1_calculated_indent_level, p2_record_H__stack_A, p3_current_record_H )

    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = p3_current_record_H[ K.level ]
    if ( output_record_H[ K.fmtr_record ][ K.level ] == K.otherlevel ) then
        output_record_H[ K.fmtr_record ][ K.other_level ] = K.group.capitalize
    end
     
    output_record_H[ K.fmtr_record ][ K.dates ] = [ ]
    date_H_A = p3_current_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__dates_idx ]
    if ( date_H_A && date_H_A.maxindex >= 0 ) then
        date_H_A.each do | date_H |
            if ( date_H.has_no_key?( K.begin ) ) then
                SE.puts "#{SE.lineno}: Didn't find date_H['#{K.begin}']"
                SE.q {[ 'date_H' ]}
                SE.q {[ 'p3_current_record_H' ]}
                raise
            end

            inclusive_dates_O = Record_Format.new( :inclusive_dates )
            inclusive_dates_O.record_H[ K.label ]     = K.creation 
            inclusive_dates_O.record_H[ K.date_type ] = ( date_H[ K.bulk ] ) ? K.bulk : K.inclusive
            inclusive_dates_O.record_H[ K.certainty ] = date_H[ K.certainty ]
            inclusive_dates_O.record_H[ K.begin ]     = date_H[ K.begin ]
            inclusive_dates_O.record_H[ K.end ]       = date_H[ K.end ]             
            inclusive_dates_O.record_H[ K.expression] = date_H[ K.expression ]
            output_record_H[ K.fmtr_record ][ K.dates ].push( inclusive_dates_O.record_H )
        end
    end

    output_record_H[ K.fmtr_record ][ K.notes ] = [ ]
    note_A = p3_current_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__notes_idx ]
    if ( note_A && note_A.maxindex >= 0 ) then
        note_A.each do | note |
            note.strip!
            regexp = /^([{<](.+?)[}>][: ])/
            m_O = note.match( regexp ) 
            if ( m_O.nil?  ) then
                if ( output_record_H[ K.fmtr_record ][ K.level ].in?( [ K.series, K.subseries, K.recordgrp, K.group ] )) then
                    note_type = K.scopecontent
                else
                    note_type = K.materialspec
                end
            else
                note.sub!( regexp, '' ) 
                note_type = m_O[ 2 ]
            end
            note.strip!
            if ( note.not_match?(/\A[[:alnum:]]/) ) then
                SE.puts "#{SE.lineno}: 1st char of note is not a letter or number."
                SE.q {'note'}
                SE.q {'note_type'}
                raise
            end
            note.gsub!( '|', "\n\n" )
            note.strip!
            case true
            when ( note_type.in?( [ K.materialspec, K.physloc ] ) ) 
                note_singlepart_O          = Record_Format.new( :note_singlepart )
                note_singlepart_O.record_H = { K.type  => note_type }
                note_singlepart_O.record_H = { K.content => [ note ] }
                output_record_H[ K.fmtr_record ][ K.notes ].push( note_singlepart_O.record_H )
            when ( note_type.in?( [K.acqinfo, K.bioghist, K.dimensions, K.processinfo, K.scopecontent ] ) )
                note_text_O          = Record_Format.new( :note_text )
                note_text_O.record_H = { K.content => note }
                note_multipart_O                        = Record_Format.new( :note_multipart )
                note_multipart_O.record_H[ K.type ]     = note_type 
                note_multipart_O.record_H[ K.subnotes ] = [ note_text_O.record_H ]                               
                output_record_H[ K.fmtr_record ][ K.notes ].push( note_multipart_O.record_H )
            else
                SE.puts "#{SE.lineno}: Unknown note type '#{note_type}'"
                SE.q {'note'}
                SE.q {'m_O'}
                raise
            end
        end
    end

    container_H_A = p3_current_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__container_idx ]
    if ( container_H_A.not_empty? ) then
        output_record_H[ K.fmtr_record ][ K.fmtr_container ] = container_H_A
    end

    arr1 = p3_current_record_H[ K.fmtr_record_indent_keys ] + [ p3_current_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__text_idx ] ]
    SE.q {'p3_current_record_H[ K.fmtr_record_indent_keys ]'}                               if ( $DEBUG )
    SE.q {'p3_current_record_H[ K.fmtr_record_values ][ K.fmtr_record_values__text_idx ]'}  if ( $DEBUG )
    SE.q {'p1_calculated_indent_level' }                                                    if ( $DEBUG )
    SE.q {'arr1'}                                                                           if ( $DEBUG )
    arr1.shift( p1_calculated_indent_level )
    output_record_H[ K.fmtr_record ][ K.title ] = arr1.join( ' ' ).strip
#   output_record_H[ K.fmtr_record ][ K.title ] = arr1[ -1 ].strip
    if ( output_record_H[ K.fmtr_record ][ K.title ].blank? ) then
        if ( date_H_A && date_H_A.maxindex >= 0 ) then
            output_record_H[ K.fmtr_record ][ K.title ] = +'[Dated]'
        else
            if ( p3_current_record_H[ K.fmtr_record_indent_keys ].empty? ) then
                output_record_H[ K.fmtr_record ][ K.title ] = +'[Item]'
            else
                SE.q {'p2_record_H__stack_A'}   if ( $DEBUG )
                SE.q {'p3_current_record_H'}    if ( $DEBUG )
                output_record_H[ K.fmtr_record ][ K.title ] = p3_current_record_H[ K.fmtr_record_indent_keys ].last
            end
        end
    end

    skip_auto_group_record = +''
    if ( output_record_H[ K.fmtr_record ][ K.level ] == K.fmtr_auto_group ) then
        if ( p2_record_H__stack_A.not_empty? ) then
#           SE.q {[ 'p2_record_H__stack_A' ]}
#           SE.q {[ 'output_record_H[ K.fmtr_record ][ K.title ]' ]}
            if ( p2_record_H__stack_A[ 0 ][ K.fmtr_record_indent_keys ].last == output_record_H[ K.fmtr_record ][ K.title ] ) then
                skip_auto_group_record = ' (Auto-Group record skipped)'
            else
                output_record_H[ K.fmtr_record ][ K.level ] = K.file
            end
        else
            output_record_H[ K.fmtr_record ][ K.level ] = K.file
        end  
    end

    output_record_H[ K.fmtr_record ][ K.title ].sub!( /[.,:;]\s*$/, '' )
    output_record_H[ K.fmtr_record ][ K.title ].sub!( /./,&:upcase )
    output_record_H[ K.fmtr_record ][ K.title ].strip!
   
    stringer = +''
    stringer = 'Forced' if ( output_record_H[ K.fmtr_record ][ K.level ] == K.otherlevel )
    self.output_fd3_F.puts 'R %-13s: ' % output_record_H[ K.fmtr_record ][ K.level ] + 
                           'L %1d ' % p1_calculated_indent_level + 
                           p3_current_record_H[ K.fmtr_record_indent_keys ].join( '| ' ) + stringer                                     
    self.output_fd3_F.puts ' ' * 21 + output_record_H[ K.fmtr_record ][ K.title ] + skip_auto_group_record
#   self.output_fd3_F.puts ' ' * 21 + output_record_H.to_json
    if ( output_record_H[ K.fmtr_record ][ K.level ] != K.fmtr_auto_group ) then
        puts output_record_H.to_json
    end

end

def put_new_parent( title )
    output_record_H={}
    output_record_H[ K.fmtr_record ] = {}
    output_record_H[ K.fmtr_record ][ K.level ] = K.fmtr_new_parent
    output_record_H[ K.fmtr_record ][ K.title ] = title.sub( /./,&:upcase )
    puts output_record_H.to_json
    stringer = 'P %-13s: ' % output_record_H[ K.fmtr_record ][ K.level ]
    self.output_fd3_F.puts stringer + title
end

BEGIN {}
END {}

myself_name = File.basename( $0 )

#   Note that:  The "Class variables" can be used in "programs", which means that
#               the program itself is somewhat like a class.
self.cmdln_option_H = { :min_group_size => 2, 
                        :max_series => 0,
                        :max_levels => nil,
                        :parent_title => nil,
                        :r => nil,
                      }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] [file]"

    option.on( "--min_group_size n", OptionParser::DecimalInteger, "Min records in a Series/Subseries/Record-group (default = 5)" ) do |opt_arg|
        self.cmdln_option_H[ :min_group_size ] = opt_arg
    end
    option.on( "--max_series n", OptionParser::DecimalInteger, "Max number of Series/Subseries (default = 0)" ) do |opt_arg|
        self.cmdln_option_H[ :max_series ] = opt_arg
    end
    option.on( "--max_levels n", OptionParser::DecimalInteger, "Max number of N.N.N things to show (default --max-series)" ) do |opt_arg|
        self.cmdln_option_H[ :max_levels ] = opt_arg
    end
    option.on( "--parent_title x", "The title of the record to attach the rest of the records too" ) do |opt_arg|
        self.cmdln_option_H[ :parent_title ] = opt_arg
    end
    option.on( "-r n", OptionParser::DecimalInteger, "Stop after N input records" ) do |opt_arg|
        self.cmdln_option_H[ :r ] = opt_arg
    end
    option.on( "-h", "--help" ) do
        warn option
        exit
    end
end.parse!  # Bang because ARGV is altered
self.cmdln_option_H[ :min_group_size ] -= 1                   # min-group-size is zero relative.
self.cmdln_option_H[ :min_group_size ] = 1 if ( self.cmdln_option_H[ :min_group_size ] < 1 )
if ( not self.cmdln_option_H[ :max_levels] ) then
    self.cmdln_option_H[ :max_levels ] = self.cmdln_option_H[ :max_series]
end
SE.q {'self.cmdln_option_H'}

if ( self.cmdln_option_H[ :parent_title ] ) then
    put_new_parent( self.cmdln_option_H[ :parent_title ] )
end

self.output_fd3_F = File::open( '/dev/fd/3', mode='w' )
#ObjectSpace.each_object(IO) { |f| SE.q { ['f.fileno','f'] } unless f.closed? }    <<< This stopped working for some reason.

Record_Grouping_Indent.new_with_flush( method( :put_record ), method( :put_indent ), self.cmdln_option_H[ :min_group_size ] ) do |rgi_O|
#   $DEBUG = true   
    ARGF.each_line do | input_record_J |
        input_record_H = JSON.parse( input_record_J )
        if ( self.cmdln_option_H[ :r ] and $. > self.cmdln_option_H[ :r ] ) then 
            break
        end
        SE.puts "\n\n"                                                      if ( $DEBUG )
        SE.puts "========================================================"  if ( $DEBUG )
        begin
            rgi_O.add_record( input_record_H )   
        rescue
            SE.puts "#{SE.lineno}: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            raise
        end
    end

end
