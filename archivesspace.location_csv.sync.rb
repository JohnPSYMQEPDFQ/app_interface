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


# ------------------------------
# CLI parsing
# ------------------------------

cmdln_option = { :rep_num => 2  ,
                 :update => false
                }
                
OptionParser.new do | option |
    option.banner = "Usage: #{myself_name} [ options ] location.csv"
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
self.aspace_O.allow_updates             = cmdln_option[ :update ]

self.rep_O   = Repository.new( aspace_O, cmdln_option[ :rep_num ] )
loc_search_O = self.rep_O.search( record_type: LOCATIONS,
                                  search_text: 'SMCC, I Bay, 2 [Range: 210, Column: R, Shelf: 10]')
#SE.q {'loc_search_O.record_H_A'} 
          
# --- Read CSV into an array of hashes ---
=begin
                                       "area" => "2",
                                   "building" => "SMCC",
    "location_profile_display_string_u_ssort" => "I Bay Shelves (Standard) [18d, 14h, 41w Inches]",
                                       "room" => "I Bay",
                                      "title" => "SMCC, I Bay, 2 [Range: 210, Column: R, Shelf: 10]"
=end

record_H_H = {}
input_csv_O = CSV.open( csv_input_file, :headers => true )
input_csv_O.each_with_index do | input_row_CSV, row_num |
    input_row_H = input_row_CSV.to_h
    modified_title = input_row_H[ K.title ].gsub( /\s+/, '' ).downcase
    if ( modified_title.nil? ) then
        SE.puts "#{SE.lineno}: =============================================="
        SE.puts "input_row_CSV missing key 'K.title'"
        SE.q {['row_num','input_row_CSV']}
        raise
    end
    if ( record_H_H.has_key?( modified_title ) ) then
        SE.puts "#{SE.lineno}: =============================================="
        SE.puts "Duplicate key found in record_H_H[ '#{modified_title}' ]"
        SE.q {['row_num','input_row_CSV']}
        raise
    end

    coordinates = input_row_H[ K.title ].dup
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
    if ( coordinate_A.maxindex > 3 ) then
        record_H[ K.coordinate_3_label ]     = coordinate_A[ 4 ]
        record_H[ K.coordinate_3_indicator ] = coordinate_A[ 5 ]          
    end   
    record_H_H[ modified_title ] = record_H
end
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

loc_query_O = self.rep_O.query( LOCATIONS ).record_H_A__all
loc_query_O.result_A.each do | record_H |
    modified_title = record_H[ K.title ].gsub( /\s+/, '' ).downcase
    if ( record_H_H.has_key?( modified_title ) ) then
        record_H_H.delete( modified_title )
#       SE.puts "Same: #{record_H[ K.title ]}"
        next
    end
    SE.puts "Delete: #{record_H[ K.title ]}"
    SE.puts Location.new( rep_O, record_H[ K.uri ] ).new_buffer.delete
end


record_H_H.each_with_index do | ( key, record_H ), cnt |
    SE.puts "Create: #{record_H[ K.title ]}"
    Location.new( rep_O, record_H[ K.uri ] ).new_buffer.create.load( record_H ).store   
end



