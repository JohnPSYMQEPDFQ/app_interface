require 'Date'
require 'json'
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'class.ArchivesSpace.rb'


#       OUTPUT record_values:
#   Filing Location; top_container; (Data)

#       INPUT RECORD:
#   Filing Location: Statewide Museum Collection Center ID 2785
#   Series 1: PHOTOGRAPHS
#   Subseries 1: Subjects
#   top_container 1
#   Amtrak. Pers
#   GROUP: WOMAN
#   Commissaries. Dining Car Department (2)

fmtr_container_H = { K.fmtr_tc_type => K.undefined ,
                     K.fmtr_tc_indicator => K.undefined ,
                     K.fmtr_sc_type => K.undefined ,
                     K.fmtr_sc_indicator => K.undefined }
rec_cnt = 0
ARGF.each_line do |input_record|


#   if ( $. > 10 ) then 
#       break
#   end
    rec_cnt += 1
    input_record.chomp!
    if ( input_record.match?( /^\s*$/ ) ) then
        next
    end

    input_record_save = input_record + ''
    output_record_H = {}

    record_values = []
  
    input_record_A = input_record.split
    if ( input_record =~ /^filing Location/i ) then
        next
    end

    if ( input_record =~ /^(series|subseries)\s+[0-9]+:\s+/i ) then
        input_record.gsub!( /\s+$/, "" )
        output_record_H[ K.fmtr_record_indent_keys ] = [ ]
        record_values << [] 
        record_values << []
        record_values << input_record
        output_record_H[ K.fmtr_record_values ] = record_values
        output_record_H[ K.level ] = K.fmtr_new_parent
        output_record_H[ K.fmtr_record_num ] = "#{rec_cnt}"
        output_record_H[ K.fmtr_record_original ] = "#{input_record_save}"
        puts output_record_H.to_json
        next
    end
    if ( input_record =~ /^drawer /i ) then
        fmtr_container_H[ K.fmtr_tc_type ] = K.object 
        fmtr_container_H[ K.fmtr_tc_indicator ] = "Drawer " + input_record_A[ 1 ] 
        next
    end
    if ( input_record =~ /^box /i ) then
        fmtr_container_H[ K.fmtr_tc_type ] = K.box
        fmtr_container_H[ K.fmtr_tc_indicator ] = input_record_A[ 1 ] 
        next
    end

    
    if ( fmtr_container_H[ K.fmtr_tc_type ] == K.object ) then
        match_O = input_record.match( /\s*\(([0-9]+)\)/ )   # Folder count pattern match
        if ( match_O ) then
            input_record.sub!( /\s*\(([0-9]+)\)/,"" )
            fmtr_container_H[ K.fmtr_sc_type ] =  K.folder
            fmtr_container_H[ K.fmtr_sc_indicator ] =  "Count " + match_O[ 1 ] 
        else
            fmtr_container_H[ K.fmtr_sc_type ] =  K.folder
            fmtr_container_H[ K.fmtr_sc_indicator ] =  "Count 1"
        end
    else
        regexp = %r{^folder\s+(?<folder_cnt>[0-9]+)\s+}i
        if (match_vars = input_record.match( regexp )) then
            input_record.gsub!( regexp, "")
            fmtr_container_H[ K.fmtr_sc_type ] =  K.folder
            fmtr_container_H[ K.fmtr_sc_indicator ] =  match_vars[:folder_cnt]
        else
            fmtr_container_H[ K.fmtr_sc_type ] = ""
            fmtr_container_H[ K.fmtr_sc_indicator ] =  ""
        end
    end
    record_values << fmtr_container_H   #[0]

    ao_date_A = []
    loop do
        regexp = %r{
                   \s*(?:,)?\s*(
                                 (#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}\s*-\s*(#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}
                                |(#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}
                               )
                   (?:\s+|$)}x
        match_O = input_record.match( regexp )  # date pattern match
        if ( match_O ) then
            input_record.sub!( regexp, "" )
            date_A = match_O[ 1 ].split( /-/ )
            if ( not date_A.maxindex.between?( 0, 1) ) then
                SE.puts "#{SE.lineno}: bad date: rec: #{input_record_save}"
                raise
            end
            idx = -1; loop do
                idx += 1
                break if ( idx > date_A.maxindex )
                if ( date_A[ idx ] =~ K.month_RE ) then
                    begin
                        date_type=Date.parse( date_A[ idx ] )
                        if ( date_type.year < 0 ) then
                            SE.puts "#{SE.lineno}: bad date: -> #{date_A[ idx ]}: rec: #{input_record_save}"
                            raise
                        end
                        date_A[ idx ] = "#{date_type.year}-#{date_type.mon}-#{date_type.mday}"
                    rescue
                        SE.puts "#{SE.lineno}: bad date: -> #{date_A[ idx ]}: rec: #{input_record_save}"
                        raise
                    end
                end
            end
            if ( date_A.maxindex == 0 ) then
                single_date_O = Record_Format.new( :single_date )
                single_date_O.record_H = { K.label => K.existence }
                single_date_O.record_H = { K.begin => date_A[ 0 ] }
                ao_date_A.push( single_date_O.record_H )
            end
            if ( date_A.maxindex == 1 ) then
                inclusive_dates_O = Record_Format.new( :inclusive_dates )
                inclusive_dates_O.record_H[ K.label ] = K.existence 
                inclusive_dates_O.record_H[ K.begin ] = date_A[ 0 ]
                inclusive_dates_O.record_H[ K.end ] = date_A[ 1 ]
                ao_date_A.push( inclusive_dates_O.record_H )
            end
        else
            break
        end
    end
    record_values << ao_date_A   #[1]
    record_values << input_record   #[2]
    
    output_record_H[ K.fmtr_record_indent_keys ] = [ ]
    output_record_H[ K.fmtr_record_values ] = record_values
    regexp = %r{^group: }i
    if ( input_record =~ regexp ) then
        input_record.sub!( regexp, "" )
        output_record_H[ K.level ] = K.recordgrp
        record_values[ 0 ] = [ ]                   # No container info on the GROUP: records.
    else
        output_record_H[ K.level ] = K.file
    end
    output_record_H[ K.fmtr_record_num ] = "#{rec_cnt}"
    output_record_H[ K.fmtr_record_original ] = "#{input_record_save}"
    puts output_record_H.to_json
end
SE.puts "#{SE.lineno}: The output from this program should not be sorted."