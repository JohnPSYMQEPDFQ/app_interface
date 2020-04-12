require 'json'
require 'class.Hash.extend.rb'
require 'class.Array.extend.rb'
require 'class.String.extend.rb'
j='{"root": [{'
j+='"archival_object":[ {"jsonmodel_type":"archival_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[],
"lang_materials":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"restrictions_apply":false,
"ancestors":[],
"instances":[],
"notes":[],
"ref_id":"816400605BS",
"level":"item",
"title":"Archival Object Title: 2",
"resource":{ "ref":"/repositories/2/resources/1"}}]'
j+=','
j+='"resource":[{"jsonmodel_type":"resource",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"part",
"number":"27",
"extent_type":"linear_feet",
"dimensions":"Y762370TE",
"physical_details":"K313THL"}],
"lang_materials":[{ "jsonmodel_type":"lang_material",
"notes":[],
"language_and_script":{ "jsonmodel_type":"language_and_script",
"language":"chv",
"script":"Pauc"}}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"2000-12-17",
"end":"2000-12-17",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"T490582T83"},
{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1985-04-13",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"K924315Q100"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"CCF732698",
"description":"X83923F545"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"microform",
"sub_container":{ "jsonmodel_type":"sub_container",
"top_container":{ "ref":"/repositories/2/top_containers/5"},
"type_2":"object",
"indicator_2":"HGO961872",
"type_3":"frame",
"indicator_3":"CM393HH"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render=\'italic\'>4</emph>",
"id_0":"476L510AX",
"level":"file",
"finding_aid_description_rules":"cco",
"finding_aid_date":"CU643MS",
"finding_aid_series_statement":"JW761101484",
"finding_aid_language":"urd",
"finding_aid_script":"Sylo",
"finding_aid_language_note":"S443RLQ",
"finding_aid_note":"990IXX217",
"ead_location":"KLUC995"}]' 
j+=','
j+='"top_container":[{"jsonmodel_type":"top_container",
"active_restrictions":[],
"container_locations":[],
"series":[],
"collection":[],
"indicator":"725M562H392",
"type":"box",
"barcode":"6bdba2fec86472e730fde114ee0a227e",
"ils_holding_id":"NW854OY",
"ils_item_id":"QEN891N",
"exported_to_ils":"2020-02-14T11:26:26-08:00"}]'
j+='}]}'

h = JSON.parse( j )
a = h.deep_keys_to_a

def print_constants( a, jsonmodel_type )
    prev_e = jsonmodel_type
    a.each do | e |
        if (e.is_a?( Array )) then
            if ( e.maxindex >= 0 and e[0] == 'jsonmodel_type' ) then
                stringer = prev_e
            else
                stringer = jsonmodel_type
            end
            print_constants( e, stringer )
        else
            
            puts "    def K.#{e}.freeze; return '#{e}'; end   # #{jsonmodel_type}"
            prev_e = e
        end
    end
end

print_constants( a, 'root')




