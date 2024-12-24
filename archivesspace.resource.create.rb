=begin

    Add a new Resource Collection Record

=end

require 'json'
require 'optparse'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'


BEGIN {}
END {}

def csrm_collection( repository_uri:,
                     ead_id:,
                     collection_name:,
                     scope_and_content:,
                     provenance:,
                     filing_location:,
                     historical_info:,
                     series_summary:
                     )      
    matchdata_O = ead_id.match( /MS [0-9]+/ )
    if  ( matchdata_O.nil? ) then
        ead_id__MS_NNNN_part_only = ead_id
    else
        ead_id__MS_NNNN_part_only = matchdata_O[ 0 ]
    end
    
    h = {   
            "ead_id"                    =>  ead_id,
            "finding_aid_author"        =>  "Library & Archives staff",
            "finding_aid_date"          =>  "2024 revision",
            "finding_aid_filing_title"  =>  collection_name,
            "finding_aid_language"      =>  "und",
            "finding_aid_language_note" =>  ".",
            "finding_aid_script"        =>  "Zyyy",
            "finding_aid_status"        =>  "completed",
            "finding_aid_title"         =>  "Guide to the #{collection_name} #{ead_id__MS_NNNN_part_only}.",
            "id_0"                      =>  ead_id,
            "jsonmodel_type"            =>  "resource",
            "level"                     =>  "collection",
            "publish"                   =>  true,
            "repository"                =>  { 'ref' => repository_uri },
            "restrictions"              =>  false,
            "suppressed"                =>  false,
            "title"                     =>  collection_name,
            
            "classifications"           =>  [],  
            "deaccessions"              =>  [],
            "external_documents"        =>  [],
            "external_ids"              =>  [],
            "instances"                 =>  [],
            "linked_agents"             =>  [],
            "linked_events"             =>  [],
            "related_accessions"        =>  [],
            "revision_statements"       =>  [],
            "rights_statements"         =>  [],
            "subjects"                  =>  [],
            
            "dates"             =>  [   {   "begin"             => "1600", 
                                            "date_type"         => "inclusive", 
                                            "end"               => "2600", 
                                            "expression"        => "1600 - 2600", 
                                            "jsonmodel_type"    => "date", 
                                            "label"             => "creation",
                                            }   # Index 0
                                        ],

            "extents"           =>  [   {   "container_summary" => "NNNN Boxes", 
                                            "extent_type"       => "Linear Feet", 
                                            "jsonmodel_type"    => "extent", 
                                            "number"            => "99999999999", 
                                            "portion"           => "whole" 
                                            }   # Index 0
                                        ],
                                
            "lang_materials"    =>  [   {   "jsonmodel_type"        =>  "lang_material",
                                            "language_and_script"   =>  {   "jsonmodel_type"    => "language_and_script", 
                                                                            "language"          => "und", 
                                                                            },
                                            "notes"                 =>  []
                                            },  
                                        {   "jsonmodel_type"        =>  "lang_material",
                                            "notes"                 =>  [   {   "content"           => ["English ."],
                                                                                "jsonmodel_type"    => "note_langmaterial",
                                                                                "type"              => "langmaterial"
                                                                                }
                                                                            ]
                                            }   
                                        ],

            "notes" =>  [   {   "content"           =>  [ "Statewide Museum Collection Center, #{filing_location}" ],
                                "jsonmodel_type"    =>  "note_singlepart",
                                "publish"           =>  false,
                                "type"              =>  "physloc"
                                },  # Index 0
                            {   "content"           =>  [ "PLACE HOLDER !!!!!!!!!!" ], 
                                "jsonmodel_type"    =>  "note_singlepart", 
                                "type"              =>  "abstract"
                                },  # Index 1
                            {   "jsonmodel_type"    =>  "note_multipart",
                                "label"             =>  "Immediate Source of Acquisition",
                                "subnotes"          =>  [   {   "content"           => provenance, 
                                                                "jsonmodel_type"    => "note_text"
                                                                }
                                                            ],
                                "type"              =>  "acqinfo"
                                },  # Index 2
                            {   "jsonmodel_type"    =>  "note_multipart",
                                "label"             =>  "Arrangement",
                                "subnotes"          =>  [   {   "content"           => series_summary, 
                                                                "jsonmodel_type"    => "note_text"
                                                                }
                                                            ],
                                "type"              =>  "arrangement"
                                },  # Index 3
                            {   "jsonmodel_type"    =>  "note_multipart",
                                "label"             =>  "Biography",
                                "subnotes"          =>  [   {   "content"           => historical_info, 
                                                                "jsonmodel_type"    => "note_text"
                                                                }
                                                            ],
                                "type"              =>  "bioghist"
                                },  # Index 4
                            {   "jsonmodel_type"    =>  "note_multipart",
                                "label"             =>  "Conditions Governing Access",
                                "subnotes"          =>  [   {   "content"           => "Collection is open for research by appointment. Contact Library Staff.",
                                                                "jsonmodel_type"    => "note_text"
                                                                }
                                                            ],
                                "type"              =>  "accessrestrict"
                                },  # Index 5
                            {   "jsonmodel_type"    =>  "note_multipart",
                                "label"             =>  "Conditions Governing Use",
                                "subnotes"          =>  [   {   "content"           =>  "Copyright has been assigned to the California State Railroad Museum. Permission for publication must be submitted in writing to the CSRM Library & Archives.",
                                                                "jsonmodel_type"    => "note_text"
                                                                }
                                                            ],
                                "type"              =>  "userestrict"
                                },  # Index 6
                            {   "jsonmodel_type"    =>  "note_multipart",
                                "label"             =>  "Scope and Contents",
                                "subnotes"          =>  [   {   "content"           => scope_and_content, 
                                                                "jsonmodel_type"    => "note_text"
                                                                }
                                                            ],
                                "type"              =>  "scopecontent"
                                },  # Index 7
                            {   "jsonmodel_type"    =>  "note_multipart",
                                "label"             =>  "Preferred Citation",
                                "subnotes"          =>  [   {   "content"           => "[Identification of item], #{collection_name}, #{ead_id__MS_NNNN_part_only}, California State Railroad Museum Library & Archives, Sacramento, California.",
                                                                "jsonmodel_type"    => "note_text"
                                                                }
                                                            ],
                                "type"              =>  "prefercite"
                                },  # Index 8
                            {   "content"           =>  [ "PLACE HOLDER !!!!!!!!!!" ],
                                "items"             =>  [ "PLACE HOLDER !!!!!!!!!!" ],
                                "jsonmodel_type"    =>  "note_bibliography",
                                "label"             =>  "Bibliography",
                                }   # Index 9
                            ],
            }
    return h
end

myself_name = File.basename( $0 )

cmdln_option_H = { :rep_num => 2  ,
                 :update => false ,
                 :ead_id => nil ,
                 :inmagic => false ,
                }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do |opt_arg|
        cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--ead-id x", "Ead_id.  Note: this will override InMagic MS number." ) do |opt_arg|
        cmdln_option_H[ :ead_id ] = opt_arg
    end
    option.on( "--inmagic", "Use InMagic file data to create Resource. A --ead-id string starting with '+' will append to the generated ead_id." ) do |opt_arg|
        cmdln_option_H[ :inmagic ] = true
    end
    option.on( "--update", "Do updates." ) do |opt_arg|
        cmdln_option_H[ :update ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option_H
#p ARGV
if ( cmdln_option_H[ :rep_num ] ) then
    rep_num = cmdln_option_H[ :rep_num ]
else
    SE.puts "The --rep-num option is required."
    raise
end


ead_id              = nil
collection_name     = "PLACE HOLDER !!!!!!!!!!"
scope_and_content   = "PLACE HOLDER !!!!!!!!!!"
provenance          = "PLACE HOLDER !!!!!!!!!!"
filing_location     = "PLACE HOLDER !!!!!!!!!!"
historical_info     = "PLACE HOLDER !!!!!!!!!!"
series_summary      = "PLACE HOLDER !!!!!!!!!!"

manual_process_columns_H = {}
if ( cmdln_option_H[ :inmagic ] ) then
    ARGF.each_line do | input_record_J |
         inmagic_resource_H = JSON.parse( input_record_J )
         inmagic_resource_H.each_pair do | inmagic_column, inmagic_value |
            case inmagic_column.downcase
            when 'Additional Access'.downcase
                # Not used
            when 'Collection Name'.downcase
                collection_name = inmagic_value
            when 'Filing Location'.downcase
                filing_location = inmagic_value
            when 'Historical Info'.downcase
                historical_info = inmagic_value.split( '|' ).map( &:strip ).join( "\n\n" )
            when 'MS Number'.downcase
                if ( cmdln_option_H[ :ead_id ].nil? ) then
                    ead_id = "InMagic MS #{inmagic_value}"
                    puts ''
                    puts "'ead_id' set to '#{ead_id}'"
                    puts ''
                else
                    matchdata_O = cmdln_option_H[ :ead_id ].match( /^\+/ )
                    if ( matchdata_O.nil? ) then
                        ead_id = cmdln_option_H[ :ead_id ]
                    else                        
                        if  ( matchdata_O.post_match.empty? ) then
                            SE.puts "#{SE.lineno}: For --ead-id option: nothing found after the '+'"
                            SE.q {[ 'matchdata_O' ]}
                            raise
                        end
                        ead_id =  "InMagic MS #{inmagic_value} #{matchdata_O.post_match}"
                        puts ''
                        puts "'ead_id' set to '#{ead_id}'"
                        puts ''
                    end
                end
            when 'Provenance'.downcase
                provenance = inmagic_value.split( '|' ).map( &:strip ).join( "\n\n" )         
            when 'Record ID number'.downcase
                # Not used
            when 'Scope and content'.downcase
                scope_and_content = inmagic_value.split( '|' ).map( &:strip ).join( "\n\n" ) 
            when 'Series Summary'.downcase
                series_summary = inmagic_value.split( '|' ).map( &:strip ).join( "\n\n" )
            else
                manual_process_columns_H[ inmagic_column ] = inmagic_value
            end
        end
    end   
else
    if ( cmdln_option_H[ :ead_id ].nil? ) then
        ead_id = "MS NNNNN"
        puts ''
        puts "WARNING: 'ead_id' set to: #{ead_id}"
        puts ''
    else
        matchdata_O = cmdln_option_H[ :ead_id ].match( /^\+/ )
        if ( matchdata_O.nil? ) then
            ead_id = cmdln_option_H[ :ead_id ]
        else
            SE.puts "#{SE.lineno}: --ead-id option starting with '+' is only for --inmagic mode."
            SE.q {[ 'cmdln_option_H' ]}
            raise
        end
    end
end 


aspace_O = ASpace.new
aspace_O.allow_updates = cmdln_option_H[ :update ]
rep_O = Repository.new( aspace_O, rep_num )

csrm_collection_H = csrm_collection( repository_uri: rep_O.uri,
                                     ead_id: ead_id,
                                     collection_name: collection_name,
                                     scope_and_content: scope_and_content,
                                     provenance: provenance,
                                     filing_location: filing_location,
                                     historical_info: historical_info,
                                     series_summary: series_summary
                                     )

res_buf_O_A = Repository_Query.new( rep_O ).get_all_Resource.buf_A
res_buf_O_A.each do | res_buf_O |
#   puts "#{res_buf_O.res_O.num}: #{res_buf_O.record_H[ K.title ]} '#{res_buf_O.record_H[ K.id_0 ]}' '#{res_buf_O.record_H[ K.ead_id ]}'"
    if ( csrm_collection_H[ K.ead_id ] == res_buf_O.record_H[ K.ead_id ] ) then
        SE.puts "#{SE.lineno}: Resource ead_id already exists."
        SE.puts "#{SE.lineno}: csrm_collection_H[ K.ead_id ] == res_buf_O.record_H[ K.ead_id ]"
        SE.q { [ 'csrm_collection_H[ K.ead_id ]', 'res_buf_O.record_H[ K.ead_id ]' ] } 
        raise 
    end
    if ( csrm_collection_H[ K.id_0 ] == res_buf_O.record_H[ K.id_0 ] ) then
        SE.puts "#{SE.lineno}: Resource id_0 already exists."
        SE.puts "#{SE.lineno}: csrm_collection_H[ K.id_0 ] == res_buf_O.record_H[ K.id_0 ]"
        SE.q { [ 'csrm_collection_H[ K.id_0 ]', 'res_buf_O.record_H[ K.id_0 ]' ] } 
        raise 
    end
end

resource_buf_O = Resource.new( rep_O ).new_buffer.create
resource_buf_O.load( csrm_collection_H )

# SE.q {[ 'resource_buf_O.record_H' ]}
new_resource = resource_buf_O.store
puts ""
puts "New resource created: #{new_resource}"
puts ""
if ( manual_process_columns_H.not_empty? ) then
    SE.q { [ 'manual_process_columns_H' ] }
end


    


