require 'class.ArchivesSpace.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Location.rb'
require 'csv'
require 'optparse'


module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :cmdln_option_H, 
                      :aspace_O, :rep_O,
                      :locations_batch_update_H
                     
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
    option.banner = "Usage: #{myself_name} [ options ]"
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

self.aspace_O = ASpace.new
self.aspace_O.allow_updates             = cmdln_option[ :update ]

self.rep_O   = Repository.new( aspace_O, cmdln_option[ :rep_num ] )

# Query what we've got now
=begin

                      "area" => "2",
                  "building" => "SMCC",
    "coordinate_1_indicator" => "324",
        "coordinate_1_label" => "Range",
    "coordinate_2_indicator" => "A",
        "coordinate_2_label" => "Bay",
    "coordinate_3_indicator" => "1",
        "coordinate_3_label" => "Shelf",
               "create_time" => "2025-12-13T01:55:58Z",
                "created_by" => "bozo",
              "external_ids" => [],
                 "functions" => [],
            "jsonmodel_type" => "location",
          "last_modified_by" => "bozo",
              "lock_version" => 0,
                      "room" => "G Bay",
              "system_mtime" => "2025-12-13T01:55:58Z",
                     "title" => "SMCC, G Bay, 2 [Range: 324, Bay: A, Shelf: 1]",
                       "uri" => "/locations/2059",
                "user_mtime" => "2025-12-13T01:55:58Z"



        curl -H 'Content-Type: text/json' -H "X-ArchivesSpace-Session: $SESSION" \
          "http://localhost:8089/locations/batch_update" \
          -d '{
          "dry_run": "BooleanParam",
          "jsonmodel_type": "location_batch_update",
          "record_uris": [
            "/locations/99",
            "/locations/99"
          ],
          "building": "RRO362M"
        }'
=end

self.locations_batch_update_H =  {
#         'dry_run'             => true,                       #This doesn't work here.
          K.jsonmodel_type      => 'location_batch_update',
          'record_uris'         =>  [],         
#         KEY                   => VALUE ,         
        }
        
def fix__G_Bay_Bay_to_Column( loc_query_O, cnt )
    location_uri_A = []
    loc_query_O.result_A.each do | record_H |
        if record_H[ K.room ] == "G Bay"
            cnt += 1
            if record_H[ K.coordinate_2_label ] == "Bay" 
                location_uri_A.push( record_H[ K.uri ] )
            end
        end    
    end
    self.locations_batch_update_H[ K.coordinate_2_label ]  = 'Column'
    return location_uri_A
end
def fix__H_Bay( loc_query_O, cnt )
    location_uri_A = []
    loc_query_O.result_A.each do | record_H |
        if record_H[ K.room ] == "H"
            cnt += 1
            location_uri_A.push( record_H[ K.uri ] )
        end    
    end
    self.locations_batch_update_H[ K.room ]  = 'H Bay'
    return location_uri_A
end
def fix__2nd_floor( loc_query_O, cnt )
    location_uri_A = []
    loc_query_O.result_A.each do | record_H |
        if record_H[ K.floor ] == "2nd"
            cnt += 1
            location_uri_A.push( record_H[ K.uri ] )
        end    
    end
    self.locations_batch_update_H[ K.floor ]  = '2nd Floor'
    return location_uri_A
end
def fix__area_2( loc_query_O, cnt )
    location_uri_A = []
    loc_query_O.result_A.each do | record_H |
        if record_H[ K.area ] == "2"
            cnt += 1
            location_uri_A.push( record_H[ K.uri ] )
        end    
    end
    self.locations_batch_update_H[ K.area ]  = ' '
    return location_uri_A
end

loc_query_O = self.rep_O.query( LOCATIONS ).record_H_A__all
cnt = 0
location_uri_A = []
#location_uri_A = fix__G_Bay_Bay_to_Column( loc_query_O, cnt )
#location_uri_A = fix__H_Bay( loc_query_O, cnt )
#location_uri_A = fix__2nd_floor( loc_query_O, cnt )
location_uri_A = fix__area_2( loc_query_O, cnt )

SE.q {['cnt','location_uri_A.length']}
if ( location_uri_A.length == 0 ) then
    SE.puts "Nothing found to change."
    exit 1
end

SE.q {'self.locations_batch_update_H'}

changed = 0
location_uri_A.each_slice( 250 ) do | chunk__location_uri_A |
    SE.q {'chunk__location_uri_A.length'}
    self.locations_batch_update_H[ 'record_uris' ] = chunk__location_uri_A
    response = aspace_O.http_calls_O.post_with_body( '/locations/batch_update', self.locations_batch_update_H )
    changed += response.select { | thing | thing.start_with?( '#<Location:' ) }.length
end
SE.q {'changed'}
if location_uri_A.length != changed
    SE.puts "location_uri_A.length != changed"
    SE.q {[ 'location_uri_A.length', 'changed' ]}
end








