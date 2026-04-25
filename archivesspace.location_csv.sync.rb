#
#   Export the CSRM Locations using the following program:
#       rr -ac archivesspace.all_records.to_csv.rb --pco --type LOCATIONS > LIVE.locations.AsOf_ccyymmdd.csv
#                                                              >All CAPS<
#
#   and then use the exported file as import into this program.

require 'class.ArchivesSpace.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Location.rb'
require 'csv'
require 'optparse'


module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :cmdln_option_H, 
                      :aspace_O, :rep_O
                     
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...


BEGIN{}
END{}

self.myself_name = File.basename( $0 )



cmdln_option = { :rep_num => 2  ,
                 :update => false
                }
                
OptionParser.new do | option |
    option.banner = "Usage: #{myself_name} [ options ] [location-file].csv"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do | opt_arg |
        cmdln_option[ :rep_num ] = opt_arg
    end
    option.on( "--update", "Do updates" ) do |opt_arg|
        cmdln_option[ :update ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!

csv_input_file = ARGV[0]   
if ( csv_input_file.nil? ) then
    SE.puts "No file specified (ARGV[0] == nil)"
    exit
end

self.aspace_O = ASpace.new
self.aspace_O.allow_updates = cmdln_option.fetch( :update )

self.rep_O   = Repository.new( aspace_O, cmdln_option.fetch( :rep_num ) )
# loc_search_O = self.rep_O.search( record_type_A: [ LOCATIONS ],
                                  # search_text: 'SMCC, I Bay, 2 [Range: 210, Column: R, Shelf: 10]')
#SE.q {'loc_search_O.record_H_A'} 
          
# --- Read CSV into an array of hashes ---
=begin
                                       "area" => "2",
                                   "building" => "SMCC",
    "location_profile_display_string_u_ssort" => "I Bay Shelves (Standard) [18d, 14h, 41w Inches]",
                                       "room" => "I Bay",
                                      "title" => "SMCC, I Bay, 2 [Range: 210, Column: R, Shelf: 10]"
=end

record_H_H__by_title_H = {}
ala_problem_record_cnt = 0
input_csv_O = CSV.open( csv_input_file, :headers => true )
#
#   DANGER!!!:  The $. variable will NOT be accurate for files read as CSV's. !!!!!!!!!!!!!
#
input_csv_O.each_with_index do | input_row_CSV, row_num |
    input_row_H = input_row_CSV.to_h
    title_downcase_WO_spaces = input_row_H.fetch( K.title ).strip.gsub( /\s+/, '' ).downcase
    if ( title_downcase_WO_spaces.nil? ) then
        SE.puts "#{SE.lineno}: =============================================="
        SE.puts "input_row_CSV missing key 'K.title'"
        SE.q {['row_num','input_row_CSV']}
        raise
    end
    if ( record_H_H__by_title_H.has_key?( title_downcase_WO_spaces ) ) then
        dup_uri      = record_H_H__by_title_H.fetch( title_downcase_WO_spaces ).fetch( :uri_from_csv )
        print "Skipped dup key: row_num=#{row_num} title='#{input_row_CSV.fetch( K.title )}' uri=#{input_row_CSV.fetch( K.uri )}" 
        print " other uri=#{dup_uri}"
        puts ''
#       SE.q {['row_num','input_row_CSV']}
        next
    end
    if ( input_row_H.fetch( K.building ) == ALA_PROBLEMS ) then
       #puts "Skipped ALA key: row_num=#{row_num} title='#{input_row_CSV.fetch( K.title )}' uri=#{input_row_CSV.fetch( K.uri )}"
        ala_problem_record_cnt += 1
        next
    end
    coordinates = input_row_H.fetch( K.title ).dup
    coordinates.sub!( /^.*\[/, '' )
    coordinates.sub!( /\].*$/, '' )
    coordinates.gsub!( /\s+/, '' )
    coordinate_A = coordinates.split( /[:,]/ )
    if ( ! ( coordinate_A.maxindex >= 1 && coordinate_A.length % 2 == 0 ) ) then
        SE.puts "#{SE.lineno}: =============================================="
        SE.puts "! ( coordinate_A.maxindex >= 1 && coordinate_A.length % 2 == 0 ) )"
        SE.q {'coordinate_A'}
        raise
    end
    if ( coordinate_A.maxindex > 5 ) then
        SE.puts "#{SE.lineno}: =============================================="
        SE.puts "coordinate_A.maxindex > 5"
        SE.q {'coordinate_A'}
        raise
    end

    record_H = Record_Format.new( K.location ).record_H
    record_H[ K.title ]                      = input_row_H[ K.title ]
    record_H[ K.building ]                   = input_row_H[ K.building ]
    record_H[ K.floor ]                      = input_row_H[ K.floor ]
    record_H[ K.room ]                       = input_row_H[ K.room ]              
    record_H[ K.area ]                       = input_row_H[ K.area ]

    record_H[ K.coordinate_1_label ]         = coordinate_A[ 0 ]
    record_H[ K.coordinate_1_indicator]      = coordinate_A[ 1 ]
    if ( coordinate_A.maxindex > 1 ) then
        record_H[ K.coordinate_2_label ]     = coordinate_A[ 2 ]
        record_H[ K.coordinate_2_indicator ] = coordinate_A[ 3 ]
    end
    if ( coordinate_A.maxindex > 2 ) then                           ##  This was > 3 
        record_H[ K.coordinate_3_label ]     = coordinate_A[ 4 ]
        record_H[ K.coordinate_3_indicator ] = coordinate_A[ 5 ]          
    end
    record_H_H__by_title_H[ title_downcase_WO_spaces ] = { :location_record_H => record_H, 
                                                           :uri_from_csv      => input_row_H[ K.uri ] }
end
puts "#{record_H_H__by_title_H.length} location records loaded from csv file."
puts "#{ala_problem_record_cnt} ALA_PROBLEM records skipped."
# header_A = input_csv_O.headers.to_a
# SE.puts header_A.join( ',' )
input_csv_O.close

# Query what we've got now
=begin
                   [ "building" ] => "test",
     [ "coordinate_1_indicator" ] => "i0 - i99",
         [ "coordinate_1_label" ] => "Bay",
     [ "coordinate_2_indicator" ] => "1-999",
         [ "coordinate_2_label" ] => "Number",
     [ "coordinate_3_indicator" ] => "E0-6",
         [ "coordinate_3_label" ] => "Elevation",
             [ "jsonmodel_type" ] => "location",
    [ "location_profile", "ref" ] => "/location_profiles/1",
          [ "owner_repo", "ref" ] => "/repositories/2",
                      [ "title" ] => "test [Bay: i0 - i99, Number: 1-999, Elevation: E0-6]",
                        [ "uri" ] => "/locations/2",

=end

ala_problem_record_cnt = 0
loc_query_O = self.rep_O.query( LOCATIONS ).record_H_A__all
location_delete_uri_A = [ ]
SE.puts "#{loc_query_O.result_A.length} location records in ASpace."
loc_query_O.result_A.each do | record_H |
    title_downcase_WO_spaces = record_H.fetch( K.title ).gsub( /\s+/, '' ).downcase
    if ( record_H_H__by_title_H.has_key?( title_downcase_WO_spaces ) ) then
        record_H_H__by_title_H.delete( title_downcase_WO_spaces )
#       SE.puts "Same: #{record_H[ K.title ]}"
        next
    end
    if ( record_H.fetch( K.building ) == ALA_PROBLEMS ) then
        ala_problem_record_cnt += 1
        next
    end
    if ( record_H.fetch( K.title ).match( /ala/i ) ) then
        SE.puts "Found 'ala' in title"
        SE.q {'record_H'}
        raise
    end
    location_delete_uri_A.push( record_H.fetch( K.uri ) )
    puts "2B-Deleted: title='#{record_H.fetch( K.title )}' uri=#{record_H.fetch( K.uri )}"
    puts ''
end
puts "#{ala_problem_record_cnt} ALA_PROBLEM records not deleted."
deleted_cnt = 0
if ( location_delete_uri_A.length > 0 ) then
    puts "#{location_delete_uri_A.length} records to be deleted."
    deleted_cnt += self.aspace_O.batch_delete( location_delete_uri_A ).deleted_cnt
end
if self.aspace_O.allow_updates && location_delete_uri_A.length != deleted_cnt
    SE.puts "location_delete_uri_A.length != deleted_cnt"
    SE.q {[ 'location_delete_uri_A.length', 'deleted_cnt' ]}
    raise
end
puts "#{deleted_cnt} records deleted."

puts "#{record_H_H__by_title_H.length} records to_be created."
created_cnt = 0
record_H_H__by_title_H.each_pair do | title_downcase_WO_spaces, record_H_H |
    record_H = record_H_H.fetch( :location_record_H )
    puts "Create: #{record_H.fetch( K.title )}"
    Location.new( rep_O ).new_buffer.create.load( record_H ).store   
    created_cnt += 1
end
puts "#{created_cnt} records created."



