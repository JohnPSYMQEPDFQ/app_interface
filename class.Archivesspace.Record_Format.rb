
class Record_Format < Buffer_Base


    def initialize( jsonmodel_type )
        super( )
        if (respond_to?( jsonmodel_type )) then
            self.record_H = method( jsonmodel_type ).call 
        else
            self.record_H = {}
#           
#           This is called by Record_Buf#filter_jsonmodel, and not all of the jsonmodels in ArchivesSpace
#           are in this class, like: lang_material and extent.  
#           SE.puts "#{SE.lineno}, called from: #{SE.my_caller}: unknown jsonmodel_type: #{jsonmodel_type}"        
        end
        return self
    end
    
    def archival_object
        h = {   
                K.jsonmodel_type => K.archival_object ,
                K.resource => { 
                    K.ref => UNDEFINED 
                } ,
                K.parent => { 
                    K.ref => UNDEFINED    
                } ,
                K.title => UNDEFINED ,   #  "Southern Pacific" 
                K.level => UNDEFINED ,
                K.other_level => '',
                K.component_id => '',
                K.publish =>  true ,
                K.dates => [] ,
                K.notes => [] ,
                K.instances=> { }                                
            } 
#       self.record_H.merge!( h )
        return h
    end

    def container_location                  # Part of 'Top_Container' below, see 'container_locations' Array with an 's'
        h = {   
                K.status => K.current ,
                K.start_date => UNDEFINED ,
                K.end_date => '' ,
                K.note => '' ,
                K.ref => UNDEFINED        # Ref to location (eg "/locations/1").  **  Note there's no /repository/N !!!
            }
#       self.record_H.merge!( h )
        return h
    end
    
    def date  
        h = {  
                K.jsonmodel_type => K.date,
                K.date_type => UNDEFINED,
                K.label => UNDEFINED,
                K.begin => UNDEFINED,
                K.end => '',
                K.certainty => '',
                K.era => '',
                K.calendar => '',
                K.expression => ''
            }
#       self.record_H.merge!( h )
        return h
    end

    def inclusive_dates                         # Also see 'single_date'
        h =  {
                K.label => UNDEFINED, 
                K.certainty => '',
                K.date_type => K.inclusive, 
                K.begin => UNDEFINED, 
                K.end => UNDEFINED,
                K.expression => ''
             }
#       self.record_H.merge!( h )
        return h
    end
    
    def instance      
        h = {   
                K.jsonmodel_type => K.instance,
                K.is_representative => false,
                K.instance_type => UNDEFINED ,
                K.sub_container => {} 
            }
#       self.record_H.merge!( h )
        return h
    end
    
    def instance_type       
        h =  {  
                K.instance_type => UNDEFINED ,  # eg. 'mixed_materials'
                K.sub_container => {
                    K.top_container => {
                        K.ref => UNDEFINED      # Ref to top_container, eg. /repositories/2/top_containers/98
                    } ,
                    K.type_2 => UNDEFINED ,     # 'folder'
                    K.indicator_2 => UNDEFINED  #  Folder identifier, eg a sequence num
                }
            }
#       self.record_H.merge!( h )
        return h
    end
            
    def location 
        h = {
                K.jsonmodel_type => K.location,
                K.area => nil,
                K.building => UNDEFINED,
                K.floor => nil,
                K.room => nil,
                K.coordinate_1_label => nil,
                K.coordinate_1_indicator => nil,
                K.coordinate_2_label => nil,
                K.coordinate_2_indicator => nil,
                K.coordinate_3_label => nil,
                K.coordinate_3_indicator => nil,
                K.classification => nil,
                K.title => nil,            #  This is generated from everything else
                K.owner_repo => nil,       #  Not sure what this is for...
            }
#       self.record_H.merge!( h )
        return h
    end
            
    def note_text                       # This is the note-text of the multipart-note (in subnotes array)
        h = {
                K.jsonmodel_type => K.note_text, 
                K.content => UNDEFINED
            }
#       self.record_H.merge!( h )
        return h
    end
    
    def note_multipart     
        h = {
                K.jsonmodel_type => K.note_multipart, 
                K.label => '', 
                K.type => UNDEFINED, #(processinfo, general)
                K.subnotes =>  [  ]    # This is an array of 'note_text' Objects. (above) 
            }
#       self.record_H.merge!( h )
        return h
    end
    
    def note_singlepart
        h =  {
                K.jsonmodel_type => K.note_singlepart,
#               K.ingest_problem => '',
                K.type => UNDEFINED,    #(physloc)
                K.publish =>  true,
                K.content => [ ],
                K.label => ''
            }
#       self.record_H.merge!( h )
        return h
    end
    
    def resource        
        h = {   
                K.ead_id => UNDEFINED,
                K.external_ids => [],
                K.finding_aid_author => UNDEFINED,
                K.finding_aid_date => UNDEFINED,
                K.finding_aid_filing_title => UNDEFINED,
                K.finding_aid_language => UNDEFINED,
                K.finding_aid_language_note => UNDEFINED,
                K.finding_aid_script => UNDEFINED,
                K.finding_aid_status => UNDEFINED,
                K.finding_aid_title => UNDEFINED,
                K.id_0 => UNDEFINED,
                K.jsonmodel_type => K.resource,
                K.level => UNDEFINED,
                K.linked_events=>[],
                K.publish => true,
                K.repository => {
                    K.ref => UNDEFINED
                },
                K.restrictions => false,
                K.subjects => [],
                K.suppressed => false,
                K.title => UNDEFINED,
            }
#       self.record_H.merge!( h )
        return h
    end

    def single_date                             # Also see 'inclusive_date'
        h = {
              K.label => UNDEFINED, 
              K.date_type => K.single, 
              K.begin => UNDEFINED,
              K.expression => ''
            }
#       self.record_H.merge!( h )
        return h
    end
    
    def sub_container       
        h = {   
                K.jsonmodel_type => K.sub_container,
                K.top_container => {
                    K.ref => UNDEFINED
                },
                K.type_2 => UNDEFINED,
                K.indicator_2 => UNDEFINED,
                K.type_3 => UNDEFINED,
                K.indicator_3 => UNDEFINED
            }
#       self.record_H.merge!( h )
        return h
    end
    
    def top_container        
        h = {   
                K.jsonmodel_type => K.top_container ,
                K.resource => { 
                    K.ref => UNDEFINED
                } ,
                K.type => UNDEFINED ,                     # 'box', 'folder', etc...
                K.indicator => UNDEFINED ,                # identifier, sequence number, etc...
                K.created_for_collection => UNDEFINED,    # Ref to resource
                K.container_locations => {} ,             # Defined above, see container_location SINGULAR
                K.collection => []
            } 
#       self.record_H.merge!( h )
        return h
    end
end
