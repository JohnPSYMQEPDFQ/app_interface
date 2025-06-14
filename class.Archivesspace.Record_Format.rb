=begin

Variable Abbreviations:
        AO = Archival Object ( Resources are an AO too, but they have their own structure. )
        AS = ArchivesSpace
        IT = Instance Type
        TC = Top Container
        SC = Sub-Container
        _H = Hash
        _J = Json string
        _RES = Regular Expression String, e.g: find_bozo_RES = '\s+bozo\s+'
        _RE  = Regular Expression, e.g.: find_bozo_RE = /#{find_bozo_RES}/
        _A = Array
        _O = Object
        _Q = Query
        _C = Class of Struct
        _S = Structure of _C 
        __ = reads as: 'in a(n)', e.g.: record_H__A = 'record' Hash "in an" Array.

=end

class Record_Format < Buffer_Base
    def initialize( jsonmodel_type )
        super( )
        if (respond_to?( jsonmodel_type )) then
            method( jsonmodel_type ).call 
        else
#           SE.puts "#{SE.lineno}: unknown jsonmodel_type: #{jsonmodel_type}"        
        end
    end
    
    def archival_object
        h = {   
                K.jsonmodel_type => K.archival_object ,
                K.resource => { 
                    K.ref => K.undefined 
                } ,
                K.parent => { 
                    K.ref => K.undefined    
                } ,
                K.title => K.undefined ,   #  "Southern Pacific" 
                K.level => K.undefined ,
                K.other_level => "",
                K.component_id => "",
                K.publish =>  true ,
                K.dates => [] ,
                K.notes => [] ,
                K.instances=> { }                                
            } 
        @record_H.merge!( h )
        return h
    end

    def container_locations
        h = {   
                K.status => K.current ,
                K.start_date => K.undefined ,
                K.end_date => "" ,
                K.note => "" ,
                K.ref => K.undefined        # Ref to location (eg "/locations/1").  **  Note there's no /repository/N !!!
            }
        @record_H.merge!( h )
        return h
    end
    
    def date  
        h = {  
                K.jsonmodel_type => K.date,
                K.date_type => K.undefined,
                K.label => K.undefined,
                K.begin => K.undefined,
                K.end => '',
                K.certainty => '',
                K.era => '',
                K.calendar => '',
                K.expression => ''
            }
        @record_H.merge!( h )
        return h
    end

    def single_date           
        h = {
              K.label => K.undefined, 
              K.date_type => K.single, 
              K.begin => K.undefined,
              K.expression => ''
            }
        @record_H.merge!( h )
        return h
    end
   
    def inclusive_dates  
        h =  {
                K.label => K.undefined, 
                K.certainty => '',
                K.date_type => K.inclusive, 
                K.begin => K.undefined, 
                K.end => K.undefined,
                K.expression => ''
             }
        @record_H.merge!( h )
        return h
    end
    
    def instance      
        h = {   
                K.jsonmodel_type => K.instance,
                K.is_representative => false,
                K.instance_type => K.undefined ,
                K.sub_container => {} 
            }
        @record_H.merge!( h )
        return h
    end
    
    def instance_type       
        h =  {  
                K.instance_type => K.undefined ,  # eg. 'mixed_materials'
                K.sub_container => {
                    K.top_container => {
                        K.ref => K.undefined      # Ref to top_container, eg. /repositories/2/top_containers/98
                    } ,
                    K.type_2 => K.undefined ,     # 'folder'
                    K.indicator_2 => K.undefined  #  Folder identifier, eg a sequence num
                }
            }
        @record_H.merge!( h )
        return h
    end
            
    def location 
        h = {
                K.jsonmodel_type => K.location,
                K.building => K.undefined,
                K.floor => "",
                K.room => "",
                K.area => "",
                K.barcode => "",
                K.classification => K.undefined,
                K.coordinate_1_label => "",
                K.coordinate_1_indicator => "",
                K.coordinate_2_label => "",
                K.coordinate_2_indicator => "",
                K.coordinate_3_label => "",
                K.coordinate_3_indicator => "",
            }
        @record_H.merge!( h )
        return h
    end
            
    def note_text                       # This is the note-text of the multipart-note (in subnotes array)
        h = {
                K.jsonmodel_type => K.note_text, 
                K.content => K.undefined
            }
        @record_H.merge!( h )
        return h
    end
    
    def note_multipart     
        h = {
                K.jsonmodel_type => K.note_multipart, 
                K.label => '', 
                K.type => K.undefined, #(processinfo, general)
                K.subnotes =>  [  ]    # This is an array of 'note_text' Objects. (above) 
            }
        @record_H.merge!( h )
        return h
    end
    
    def note_singlepart
        h =  {
                K.jsonmodel_type => K.note_singlepart,
#               K.ingest_problem => '',
                K.type => K.undefined,    #(physloc)
                K.publish =>  true,
                K.content => [ ],
                K.label => ''
            }
        @record_H.merge!( h )
        return h
    end
    
    def resource        
        h = {   
                K.ead_id => K.undefined,
                K.external_ids => [],
                K.finding_aid_author => K.undefined,
                K.finding_aid_date => K.undefined,
                K.finding_aid_filing_title => K.undefined,
                K.finding_aid_language => K.undefined,
                K.finding_aid_language_note => K.undefined,
                K.finding_aid_script => K.undefined,
                K.finding_aid_status => K.undefined,
                K.finding_aid_title => K.undefined,
                K.id_0 => K.undefined,
                K.jsonmodel_type => K.resource,
                K.level => K.undefined,
                K.linked_events=>[],
                K.publish => true,
                K.repository => {
                    K.ref => K.undefined
                },
                K.restrictions => false,
                K.subjects => [],
                K.suppressed => false,
                K.title => K.undefined,
            }
        @record_H.merge!( h )
        return h
    end
    
    def sub_container       
        h = {   
                K.jsonmodel_type => K.sub_container,
                K.top_container => {
                    K.ref => K.undefined
                },
                K.type_2 => K.undefined,
                K.indicator_2 => K.undefined,
                K.type_3 => K.undefined,
                K.indicator_3 => K.undefined
            }
        @record_H.merge!( h )
        return h
    end
    
    def top_container        
        h = {   
                K.jsonmodel_type => K.top_container ,
                K.resource => { 
                    K.ref => K.undefined
                } ,
                K.type => K.undefined ,       # 'box', 'folder', etc...
                K.indicator => K.undefined ,  #  identifier, sequence number, etc...
                K.created_for_collection => K.undefined,    # Ref to resource
                K.container_locations => {} ,
                K.collection => []
            } 
        @record_H.merge!( h )
        return h
    end
end
