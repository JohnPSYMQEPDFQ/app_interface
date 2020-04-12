=begin

Abbreviations,  AO = archival object(Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                AS = ArchivesSpace
                IT = instance type
                TC = top container
                SC = Sub-container
                _H = Hash
                _A = Array
                _I = Index(of Array)
                _O = Object
               _0R = Zero Relative

=end

class Record_Format < Buffer_Base
    def initialize( jsonmodel_type )
        super( )
        if (respond_to?( jsonmodel_type )) then
            method( jsonmodel_type ).call 
        else
#           Se.puts "#{Se.lineno}: unknown jsonmodel_type: #{jsonmodel_type}"        
        end
    end
    attr_reader :record_H
    
    def archival_object
        h = {   K.jsonmodel_type => K.archival_object ,
                K.resource => { 
                    K.ref => K.undefined 
                } ,
                K.parent => { 
                    K.ref => K.undefined    
                } ,
                K.title => K.undefined ,   #  "Southern Pacific" 
                K.level => K.undefined ,
                K.publish =>  true ,
                K.dates => [] ,
                K.notes => [] ,
                K.instances=> { }                                
            } 
        @record_H.merge!( h )
        return h
    end
    
    def date  
        h = {   K.jsonmodel_type => K.date,
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
    
    def instance      
        h = {   K.jsonmodel_type => K.instance,
                K.is_representative => false,
                K.instance_type => K.undefined ,
                K.sub_container => {} 
            }
        @record_H.merge!( h )
        return h
    end
    
    def note_multipart     
        h = {
                K.jsonmodel_type => K.note_multipart, 
                K.ingest_problem => '', 
                K.persistent_id => '', 
                K.label => '', 
                K.type => K.undefined, #(processinfo)
                K.subnotes =>  [  ]			
            }
        @record_H.merge!( h )
        return h
    end
    
    def note_singlepart
        h =  {
                K.jsonmodel_type => K.note_singlepart,
                K.ingest_problem => '',
                K.type => K.undefined,    #(physloc)
                K.publish =>  true,
                K.content => [ ],
                K.label => '',
                K.persistent_id => ''
            }
        @record_H.merge!( h )
        return h
    end
    
    def sub_container       
        h = {   K.jsonmodel_type => K.sub_container,
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
    
    def resource        
        h = {   K.jsonmodel_type => K.resource,
                K.title => K.undefined,
                K.publish => true,
                K.restrictions => false,
                K.ead_id => K.undefined,
                K.finding_aid_title => K.undefined,
                K.finding_aid_filing_title => K.undefined,
                K.finding_aid_date => K.undefined,
                K.finding_aid_author => K.undefined,
                K.finding_aid_language_note => K.undefined,
                K.suppressed => false,
                K.id_0 => K.undefined,
                K.level => K.undefined,
                K.finding_aid_language => K.undefined,
                K.finding_aid_script => K.undefined,
                K.finding_aid_status => K.undefined,
                K.external_ids => [],
                K.subjects => [{ K.ref => K.undefined }],
                K.linked_events=>[],
            }
        @record_H.merge!( h )
        return h
    end
    
    def top_container        
        h = {   K.jsonmodel_type => K.top_container ,
                K.resource => { 
                    K.ref => K.undefined
                } ,
                K.type => K.undefined ,       # 'box'
                K.indicator => K.undefined ,  #  box sequence number
                K.created_for_collection => K.undefined,
                K.collection => []
            } 
        @record_H.merge!( h )
        return h
    end
    
    def mixed_materials_IT       
        h =  {
                K.instance_type =>K.mixed_materials ,
                K.sub_container => {
                    K.top_container => {
                        K.ref => K.undefined      # Ref to top_container, eg. /repositories/2/top_containers/98
                    } ,
                    "type_2" => K.undefined ,     # 'folder'
                    "indicator_2" => K.undefined  #  Folder identifier, eg a sequence num
                }
            }
        @record_H.merge!( h )
        return h
    end

    def single_date           
        h = {
              K.label => K.undefined, 
              K.date_type => K.single, 
              K.begin => K.undefined 
            }
        @record_H.merge!( h )
        return h
    end
   
    def inclusive_dates  
        h =  {
                K.label => K.undefined, 
                K.date_type => K.inclusive, 
                K.begin => K.undefined, 
                K.end => K.undefined
             }
        @record_H.merge!( h )
        return h
    end
            
    def note_text 
        h = {
                K.jsonmodel_type => K.note_text, 
                K.ingest_problem => "", 
                K.content => K.undefined
            }
        @record_H.merge!( h )
        return h
    end
end
