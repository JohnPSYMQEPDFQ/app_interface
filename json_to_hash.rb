require 'json'

j = '{ "jsonmodel_type":"archival_object",
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
"resource":{ "ref":"/repositories/2/resources/1"}}'

j = '{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"microform",
"sub_container":{ "jsonmodel_type":"sub_container",
"top_container":{ "ref":"/repositories/2/top_containers/5"},
"type_2":"object",
"indicator_2":"HGO961872",
"type_3":"frame",
"indicator_3":"CM393HH"}}'

j = '{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1985-04-13",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"K924315Q100"} '

h = JSON.parse(j)
pp h


