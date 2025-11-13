=begin

    Add a new Resource Collection Record

=end

require 'json'
require 'optparse'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Find_Dates_in_String.rb'

BEGIN {}
END {}

def csrm_collection( repository_uri:,
                     ead_id:,
                     collection_name:,
                     scope_and_content:,
                     provenance:,
                     filing_location:,
                     historical_info:,
                     series_summary:,
                     process_info:,
                     begin_date:,
                     end_date:
                     )      
                     
    collection_name     = "PLACE HOLDER !!!!!!!!!!" if ( collection_name.blank? )
    scope_and_content   = "PLACE HOLDER !!!!!!!!!!" if ( scope_and_content.blank? )
    provenance          = "PLACE HOLDER !!!!!!!!!!" if ( provenance.blank? )
    filing_location     = "PLACE HOLDER !!!!!!!!!!" if ( filing_location.blank? )
    historical_info     = "PLACE HOLDER !!!!!!!!!!" if ( historical_info.blank? )
    series_summary      = "PLACE HOLDER !!!!!!!!!!" if ( series_summary.blank? )
    
    matchdata_O = ead_id.match( /MS [0-9]+/ )
    if  ( matchdata_O.nil? ) then
        ead_id__MS_NNNN_part_only = ead_id
    else
        ead_id__MS_NNNN_part_only = matchdata_O[ 0 ]
    end
    
    resource_H = {   
            "ead_id"                    =>  ead_id,
            "finding_aid_author"        =>  "Library & Archives staff",
            "finding_aid_date"          =>  "2025 revision",
            "finding_aid_filing_title"  =>  collection_name,
            "finding_aid_language"      =>  "eng",
            "finding_aid_language_note" =>  ".",
            "finding_aid_script"        =>  "Latn",
            "finding_aid_status"        =>  "completed",
            "finding_aid_title"         =>  "Guide to the #{collection_name} #{ead_id__MS_NNNN_part_only}.",
            "id_0"                      =>  ead_id,
            K.jsonmodel_type            =>  "resource",
            "level"                     =>  "collection",
            K.publish                   =>  true,
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
            
            "dates"             =>  [   {   "begin"             => begin_date, 
                                            "date_type"         => "inclusive", 
                                            "end"               => end_date, 
                                            "expression"        => "#{begin_date} - #{end_date}", 
                                            K.jsonmodel_type    => "date", 
                                            K.label             => "creation",
                                            }   # Index 0
                                        ],

            "extents"           =>  [   {   "container_summary" => "NNNN Boxes", 
                                            "extent_type"       => "Linear Feet", 
                                            K.jsonmodel_type    => "extent", 
                                            "number"            => "99999999999", 
                                            "portion"           => "whole" 
                                            }   # Index 0
                                        ],
                                
            "lang_materials"    =>  [   {   K.jsonmodel_type        =>  "lang_material",
                                            "language_and_script"   =>  {   K.jsonmodel_type    => "language_and_script", 
                                                                            "language"          => "eng", 
                                                                            },
                                            K.notes                 =>  []
                                            },  
                                        {   K.jsonmodel_type        =>  "lang_material",
                                            K.notes                 =>  [   {   K.content           => ["English."],
                                                                                K.jsonmodel_type    => "note_langmaterial",
                                                                                K.type              => "langmaterial"
                                                                                }
                                                                            ]
                                            }   
                                        ],

            K.notes =>  [   {   K.content           =>  [ "Statewide Museum Collection Center, #{filing_location}" ],
                                K.jsonmodel_type    =>  K.note_singlepart,
                                K.publish           =>  true,
                                K.type              =>  K.physloc
                                },  # Index 0
                            {   K.content           =>  [ "PLACE HOLDER !!!!!!!!!!" ], 
                                K.jsonmodel_type    =>  K.note_singlepart, 
                                K.type              =>  "abstract"
                                },  # Index 1
                            {   K.jsonmodel_type    =>  K.note_multipart,
#                               K.label             =>  "Immediate Source of Acquisition",
                                K.subnotes          =>  [   {   K.content           => provenance, 
                                                                K.jsonmodel_type    => K.note_text
                                                                }
                                                            ],
                                K.type              =>  K.acqinfo
                                },  # Index 2
                            {   K.jsonmodel_type    =>  K.note_multipart,
#                               K.label             =>  "Arrangement",
                                K.subnotes          =>  [   {   K.content           => series_summary, 
                                                                K.jsonmodel_type    => K.note_text
                                                                }
                                                            ],
                                K.type              =>  "arrangement"
                                },  # Index 3
                            {   K.jsonmodel_type    =>  K.note_multipart,
#                               K.label             =>  "Biography",
                                K.subnotes          =>  [   {   K.content           => historical_info, 
                                                                K.jsonmodel_type    => K.note_text
                                                                }
                                                            ],
                                K.type              =>  "bioghist"
                                },  # Index 4
                            {   K.jsonmodel_type    =>  K.note_multipart,
#                               K.label             =>  "Conditions Governing Access",
                                K.subnotes          =>  [   {   K.content           => "Collection is open for research by appointment. Contact Library Staff.",
                                                                K.jsonmodel_type    => K.note_text
                                                                }
                                                            ],
                                K.type              =>  "accessrestrict"
                                },  # Index 5
                            {   K.jsonmodel_type    =>  K.note_multipart,
#                               K.label             =>  "Conditions Governing Use",
                                K.subnotes          =>  [   {   K.content           =>  "Copyright has been assigned to the California State Railroad Museum. Permission for publication must be submitted in writing to the CSRM Library & Archives.",
                                                                K.jsonmodel_type    => K.note_text
                                                                }
                                                            ],
                                K.type              =>  "userestrict"
                                },  # Index 6
                            {   K.jsonmodel_type    =>  K.note_multipart,
#                               K.label             =>  "Scope and Contents",
                                K.subnotes          =>  [   {   K.content           => scope_and_content, 
                                                                K.jsonmodel_type    => K.note_text
                                                                }
                                                            ],
                                K.type              =>  K.scopecontent
                                },  # Index 7
                            {   K.jsonmodel_type    =>  K.note_multipart,
#                               K.label             =>  "Preferred Citation",
                                K.subnotes          =>  [   {   K.content           => "[Identification of item], #{collection_name}, #{ead_id__MS_NNNN_part_only}, California State Railroad Museum Library & Archives, Sacramento, California.",
                                                                K.jsonmodel_type    => K.note_text
                                                                }
                                                            ],
                                K.type              =>  "prefercite"
                                },  # Index 8
                            {   K.content           =>  [ "PLACE HOLDER !!!!!!!!!!" ],
                                "items"             =>  [ "PLACE HOLDER !!!!!!!!!!" ],
                                K.jsonmodel_type    =>  "note_bibliography",
                                K.label             =>  "Bibliography",
                                }   # Index 9
                            ],
            }
    if ( process_info.not_blank? ) then
        h = {   K.jsonmodel_type    =>  K.note_multipart,
                K.subnotes          =>  [   {   K.content           => process_info, 
                                                K.jsonmodel_type    => K.note_text
                                                }
                                            ],
                K.type              =>  K.processinfo
                }   # Index 10
        resource_H[ K.notes ].push( h )
    end
    return resource_H
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

find_dates_O = Find_Dates_in_String.new( {  :morality_replace_option => { :good  => :remove },
                                            :date_string_composition => :dates_in_text,
#                                           :default_century_pivot_ccyymmdd => '1900',
                                            :sort => false,
                                         } )
#SE.q {[ 'find_dates_O.option_H' ]}

ead_id              = nil
collection_name     = ''
scope_and_content   = ''
provenance          = ''
filing_location     = ''
historical_info     = ''
series_summary      = ''
process_info        = ''
begin_date          = '1600'
end_date            = '2600'

manual_process_columns_H = {}
if ( cmdln_option_H[ :inmagic ] ) then
    ARGF.each_line do | input_record_J |
         inmagic_resource_H = JSON.parse( input_record_J )
         inmagic_resource_H.each_pair do | inmagic_column, inmagic_value |
            case inmagic_column.downcase
            when 'Additional Access'.downcase
                # Not used
            when 'Collection Name'.downcase
                collection_name += inmagic_value.gsub( K.embedded_CRLF, "\n" )
            when 'Filing Location'.downcase
                filing_location += inmagic_value.gsub( K.embedded_CRLF, "\n" )
            when 'Historical Info'.downcase
                historical_info += inmagic_value.gsub( K.embedded_CRLF, "\n" )
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
                provenance += inmagic_value.gsub( K.embedded_CRLF, "\n" )        
            when 'Record ID number'.downcase
                # Not used
            when 'Scope and content'.downcase
                scope_and_content += inmagic_value.gsub( K.embedded_CRLF, "\n" )
            when 'Series Summary'.downcase
                series_summary += inmagic_value.gsub( K.embedded_CRLF, "\n" )
            when 'Extent'.downcase
                output_string = find_dates_O.do_find( inmagic_value )
                if ( output_string == inmagic_value or find_dates_O.good__date_clump_S__A.length > 1 ) then
                    manual_process_columns_H[ inmagic_column ] = inmagic_value
                else
                    manual_process_columns_H[ inmagic_column ] = output_string.strip
                    begin_date = find_dates_O.good__date_clump_S__A.first.as_from_date
                    if ( find_dates_O.good__date_clump_S__A.first.as_thru_date.blank? ) then
                        end_date = begin_date
                    else
                        end_date = find_dates_O.good__date_clump_S__A.first.as_thru_date
                    end
                end
            else
                process_info += "InMagic column '#{inmagic_column}':\n" + 
                                inmagic_value.gsub( K.embedded_CRLF, "\n" ) + "\n\n"
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

resource_H = csrm_collection( repository_uri: rep_O.uri,
                              ead_id: ead_id,
                              collection_name: collection_name,
                              scope_and_content: scope_and_content,
                              provenance: provenance,
                              filing_location: filing_location,
                              historical_info: historical_info,
                              series_summary: series_summary,
                              process_info: process_info,
                              begin_date: begin_date,
                              end_date: end_date
                              )
#SE.q {'resource_H'}
resource_buf_O = Resource.new( rep_O ).new_buffer.create
resource_buf_O.load( resource_H )

#SE.q {[ 'resource_buf_O.record_H' ]}
new_resource_num = resource_buf_O.store
puts ""
puts "New resource number: #{new_resource_num}"
puts "               name: #{collection_name}"   
puts ""
if ( manual_process_columns_H.not_empty? ) then
    SE.q { [ 'manual_process_columns_H' ] }
end


    


