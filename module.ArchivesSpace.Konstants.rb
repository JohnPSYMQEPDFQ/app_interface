module K
    def K.alpha_month_RES
        stringer = '(january|february|march|april|may|june|july|august|september|october|november|december' +
                   '|jan\\.|feb\\.|mar\\.|apr\\.|may\\.|jun\\.|jul\\.|aug\\.|sep\\.|oct\\.|nov\\.|dec\\.' +
                   '|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec' +
                   ')'.freeze
        return stringer
    end 
    def K.alpha_month_RE
        return /#{K.alpha_month_RES}/xi
    end 
    def K.numeric_month_RES
        stringer = '(?:0?[1-9]|1[012])'.freeze
        return stringer
    end
    def K.numeric_month_RE
        return /#{K.numeric_month_RES}/xi
    end 
    def K.day_RES
        stringer = '(?:[0-9]|[012][0-9]|3[01])'.freeze
        return stringer
    end
    def K.day_RE
        return /#{K.day_RES}/
    end 
    def K.year4_RES
        stringer = '(?:1[89][0-9][0-9]|20[0-9][0-9])'.freeze
        return stringer
    end 
    def K.year4_RE
        return /#{K.year4_RES}/
    end 
    def K.year2_RES
        stringer = '?:([0-9][0-9])'.freeze
        return stringer
    end
    def K.year2_RE
        return /#{K.year2_RES}/
    end 
    def K.box_and_folder_RES
        stringer = '(\A|\s+)box(:\s*|\s+)(?<box_num>[0-9]+)\s+folder(s?)(:\s*|\s+)(?<folder_num>[0-9]+[a-z]?(\s*-\s*[0-9]+[a-z]?)?)(\Z|\s+)'.freeze
        return stringer
    end
    def K.box_and_folder_RE
        return /#{K.box_and_folder_RES}/i
    end

    
    def K.active_restrictions; return 'active_restrictions'.freeze; end   # top_container
    def K.ancestors; return 'ancestors'.freeze; end   # archival_object
    def K.archival_object; return 'archival_object'.freeze; end   # root
    def K.archival_objects; return 'archival_objects'.freeze; end    # <<<< Danger Plural
    def K.area; return 'area'.freeze; end   # location
    def K.barcode; return 'barcode'.freeze; end   # top_container location
    def K.begin; return 'begin'.freeze; end   # dates
    def K.box; return 'box'.freeze; end   # top_container
    def K.building; return 'building'.freeze; end   # location
    def K.calendar; return 'calendar'.freeze; end   # dates
    def K.certainty; return 'certainty'.freeze; end   # dates
    def K.children; return 'children'.freeze; end
    def K.child_count; return 'child_count'.freeze; end  # trees
    def K.classification; return 'classification'.freeze; end   # location
    def K.classifications; return 'classifications'.freeze; end   # resource  <<<< Danger Plural
    def K.collection; return 'collection'.freeze; end   # top_container
    def K.component_id; return 'component_id'.freeze; end  # archival_object
    def K.container_locations; return 'container_locations'.freeze; end   # top_container
    def K.content; return 'content'.freeze; end
    def K.coordinate_1_indicator; return 'coordinate_1_indicator'.freeze; end   # location
    def K.coordinate_1_label; return 'coordinate_1_label'.freeze; end   # location
    def K.coordinate_2_indicator; return 'coordinate_2_indicator'.freeze; end   # location
    def K.coordinate_2_label; return 'coordinate_2_label'.freeze; end   # location
    def K.coordinate_3_indicator; return 'coordinate_3_indicator'.freeze; end   # location
    def K.coordinate_3_label; return 'coordinate_3_label'.freeze; end   # location
    def K.created_by; return 'created_by'.freeze; end
    def K.created_for_collection; return 'created_for_collection'.freeze; end
    def K.create_time; return 'create_time'.freeze; end
    def K.creation; return 'creation'.freeze; end    #date
    def K.date; return 'date'.freeze; end   # revision_statements                       <<<< Danger Singular
    def K.date_certainty; return 'date_certainty'.freeze; end   # spreadsheet column header for K.certainty'
    def K.dates; return 'dates'.freeze; end   # archival_object, resource, formatter    <<<< Danger Plural
    def K.dates_label; return 'dates_label'.freeze; end   # spreadsheet column header for K.label'
    def K.date_type; return 'date_type'.freeze; end   # dates
    def K.deaccessions; return 'deaccessions'.freeze; end   # resource
    def K.description; return 'description'.freeze; end   # revision_statements
    def K.dimensions; return 'dimensions'.freeze; end   # extents
    def K.display_string; return 'display_string'.freeze; end
    def K.ead; return 'ead'.freeze; end   # spreadsheet column header for K.ead_id
    def K.ead_id; return 'ead_id'.freeze; end   # resource,  This and the id_0 must be unique
    def K.ead_location; return 'ead_location'.freeze; end   # resource
    def K.end; return 'end'.freeze; end   # dates
    def K.era; return 'era'.freeze; end   # dates
    def K.existence; return 'existence'.freeze; end   # dates
    def K.exported_to_ils; return 'exported_to_ils'.freeze; end   # top_container
    def K.expression; return 'expression'.freeze; end   # dates
    def K.extents; return 'extents'.freeze; end   # archival_object, resource
    def K.extent_type; return 'extent_type'.freeze; end   # extents
    def K.external_documents; return 'external_documents'.freeze; end   # archival_object, resource
    def K.external_ids; return 'external_ids'.freeze; end   # archival_object, resource
    def K.file; return 'file'.freeze; end
    def K.finding_aid_author; return 'finding_aid_author'.freeze; end  # resource
    def K.finding_aid_date; return 'finding_aid_date'.freeze; end   # resource
    def K.finding_aid_description_rules; return 'finding_aid_description_rules'.freeze; end   # resource
    def K.finding_aid_filing_title; return 'finding_aid_filing_title'.freeze; end  # resource
    def K.finding_aid_language; return 'finding_aid_language'.freeze; end   # resource
    def K.finding_aid_language_note; return 'finding_aid_language_note'.freeze; end   # resource
    def K.finding_aid_note; return 'finding_aid_note'.freeze; end   # resource
    def K.finding_aid_script; return 'finding_aid_script'.freeze; end   # resource
    def K.finding_aid_series_statement; return 'finding_aid_series_statement'.freeze; end   # resource
    def K.finding_aid_status; return 'finding_aid_status'.freeze; end  # resource
    def K.finding_aid_title; return 'finding_aid_title'.freeze; end  # resource
    def K.floor; return 'floor'.freeze; end  # location
    def K.fmtr_container; return '__CONTAINER__'.freeze; end   # formatter
    def K.fmtr_indent; return '__INDENT__'.freeze; end  # formatter
    def K.fmtr_inmagic_detail; return 'detail'.freeze; end              #InMagic formatter
    def K.fmtr_inmagic_quote; return '__INMAGIC__'.freeze; end          #inMagic Formatter
    def K.fmtr_inmagic_series; return 'series'.freeze; end              #InMagic formatter
    def K.fmtr_inmagic_seriesdate; return 'seriesdate'.freeze; end      #InMagic formatter
    def K.fmtr_inmagic_seriesnote; return 'seriesnote'.freeze; end      #InMagic formatter
    def K.fmtr_left; return '__LEFT__'.freeze; end  # formatter
    def K.fmtr_new_parent; return '__NEW_PARENT__'.freeze; end  # formatter
    def K.fmtr_record; return '__RECORD__'.freeze; end  # formatter
    def K.fmtr_record_indent_keys; return '__RECORD_INDENT_KEYS__'.freeze; end  # formatter
    def K.fmtr_record_num; return '__RECORD_NUM__'.freeze; end  # formatter
    def K.fmtr_record_original; return '__RECORD_ORIGINAL__'.freeze; end  # formatter
    def K.fmtr_record_sort_keys; return '__RECORD_SORT_KEYS__'.freeze; end  # formatter
    def K.fmtr_record_values; return '__RECORD_VALUES__'.freeze; end  # formatter
    def K.fmtr_record_values__text_idx; return 0.freeze; end  # formatter
    def K.fmtr_record_values__dates_idx; return 1.freeze; end  # formatter
    def K.fmtr_record_values__notes_idx; return 2.freeze; end  # formatter
    def K.fmtr_record_values__container_idx; return 3.freeze; end  # formatter
    def K.fmtr_record_values__special_processing_idx; return 4.freeze; end  # formatter
    def K.fmtr_right; return '__RIGHT__'.freeze; end  # formatter
    def K.fmtr_shelf_box; return '__SHELF_BOX__'.freeze; end  # formatter
    def K.fmtr_empty_container_H
        h = { K.shelf => nil,               # Use this to (someday) lookup a location.
              K.type => K.undefined ,
              K.indicator => K.undefined ,
              K.type_2 => K.undefined ,
              K.indicator_2 => K.undefined ,
              K.type_3 => nil ,
              K.indicator_3 => nil ,
              }
        return h
    end
    def K.folder; return 'Folder'.freeze; end
    def K.has_unpublished_ancestor; return 'has_unpublished_ancestor'.freeze; end
    def K.hierarchy; return 'hierarchy'.freeze; end   # spreadsheet
    def K.id; return 'id'.freeze; end   # tree
    def K.id_0; return 'id_0'.freeze; end   # resource  This and the ead_id must be unique.  
                                            #           This is called the 'unitid' in the XML dump file!
    def K.ils_holding_id; return 'ils_holding_id'.freeze; end   # top_container
    def K.ils_item_id; return 'ils_item_id'.freeze; end   # top_container
    def K.inclusive; return 'inclusive'.freeze; end
    def K.indicator; return 'indicator'.freeze; end   # top_container
    def K.indicator_2; return 'indicator_2'.freeze; end   # sub_container
    def K.indicator_3; return 'indicator_3'.freeze; end   # sub_container
    def K.ingest_problem; return 'ingest_problem'.freeze; end
    def K.instance; return 'instance'.freeze; end   # instances     WARNING SINGULAR
    def K.instances; return 'instances'.freeze; end   # archival_object, resource     WARNING PLURAL
    def K.instance_type; return 'instance_type'.freeze; end   # instances
    def K.is_representative; return 'is_representative'.freeze; end   # instances
    def K.is_slug_auto; return 'is_slug_auto'.freeze; end   # archival_object, resource
    def K.jsonmodel_type; return 'jsonmodel_type'.freeze; end   # everything
    def K.label; return 'label'.freeze; end   # dates
    def K.language; return 'language'.freeze; end   # language_and_script
    def K.language_and_script; return 'language_and_script'.freeze; end   # lang_materials
    def K.lang_materials; return 'lang_materials'.freeze; end   # archival_object, resource
    def K.last_modified_by; return 'last_modified_by'.freeze; end
    def K.level; return 'level'.freeze; end   # archival_object, resource
    def K.linked_agents; return 'linked_agents'.freeze; end   # archival_object, resource
    def K.linked_events; return 'linked_events'.freeze; end   # archival_object, resourcr
    def K.location; return 'location'.freeze; end  # location
    def K.lock_version; return 'lock_version'.freeze; end  # archival_object (incremented with eash update_
    def K.materialspec; return 'materialspec'.freeze; end  # note_singlepart (material specific)
    def K.mixed_materials; return 'mixed_materials'.freeze; end
    def K.n_physdesc; return 'n_physdesc'.freeze; end  # Spreadsheet only: physical description note text
    def K.no; return 'no'.freeze; end   
    def K.node_type; return 'node_type'.freeze; end   # tree
    def K.node_uri; return 'node_uri'.freeze; end   # tree
    def K.notes; return 'notes'.freeze; end   # archival_object, lang_materials, resource, formatter
    def K.note_multipart; return 'note_multipart'.freeze; end   
    def K.note_singlepart; return 'note_singlepart'.freeze; end   
    def K.note_text; return 'note_text'.freeze; end
    def K.number; return 'number'.freeze; end   # extents
    def K.object; return 'object'.freeze; end   # top_container
    def K.offset; return 'offset'.freeze; end   # tree
    def K.p_physdesc; return 'p_physdesc'.freeze; end  # Spreadsheet only: physical description note publish
    def K.parent; return 'parent'.freeze; end
    def K.parent_id; return 'parent_id'.freeze; end  # tree
    def K.parent_node; return 'parent_node'.freeze; end  # tree
    def K.password; return 'password'.freeze; end
    def K.persistent_id; return 'persistent_id'.freeze; end
    def K.physical_details; return 'physical_details'.freeze; end   # extents
    def K.physdesc; return 'physdesc'.freeze; end   # note_singlepart (physical description)
    def K.physloc; return 'physloc'.freeze; end   # note_singlepart (physical location)
    def K.portion; return 'portion'.freeze; end   # extents
    def K.position; return 'position'.freeze; end
    def K.precomputed_waypoints; return 'precomputed_waypoints'.freeze; end  # tree
    def K.processinfo; return 'processinfo'.freeze; end   # note_singlepart (process information)
    def K.publish; return 'publish'.freeze; end
    def K.recordgrp; return 'recordgrp'.freeze; end  #archival_object
    def K.record_uri; return 'record_uri'.freeze; end
    def K.ref; return 'ref'.freeze; end   # archival_object, sub_container
    def K.ref_id; return 'ref_id'.freeze; end   # archival_object
    def K.related_accessions; return 'related_accessions'.freeze; end   # resource
    def K.repository; return 'repository'.freeze; end
    def K.resource; return 'resource'.freeze; end   # archival_object
    def K.resource_tree; return 'resource_tree'.freeze; end
    def K.restrictions; return 'restrictions'.freeze; end   # resource
    def K.restrictions_apply; return 'restrictions_apply'.freeze; end   # archival_object
    def K.revision_statements; return 'revision_statements'.freeze; end   # resource
    def K.rights_statements; return 'rights_statements'.freeze; end   # archival_object, resource
    def K.room; return 'room'.freeze; end   # archival_object, location
    def K.scopecontent; return 'scopecontent'.freeze; end  # note_multipart (Scope and Content)
    def K.script; return 'script'.freeze; end   # language_and_script
    def K.series; return 'series'.freeze; end   # archival_object
    def K.session; return 'session'.freeze; end
    def K.shelf; return 'shelf'.freeze; end     # Someday (maybe) the shelf that the box is located on.  
    def K.single; return 'single'.freeze; end
    def K.slugged_url; return 'slugged_url'.freeze; end   # archival_object
    def K.status; return 'status'.freeze; end   # http
    def K.subjects; return 'subjects'.freeze; end   # archival_object, resource
    def K.subnotes; return 'subnotes'.freeze; end
    def K.subseries; return 'subseries'.freeze; end
    def K.sub_container; return 'sub_container'.freeze; end   # instances
    def K.suppressed; return 'suppressed'.freeze; end
    def K.spreadsheet_true; return '1'.freeze; end
    def K.spreadsheet_false; return '0'.freeze; end
    def K.system_mtime; return 'system_mtime'.freeze; end
    def K.title; return 'title'.freeze; end   # archival_object, resource
    def K.top_container; return 'top_container'.freeze; end   # sub_container
    def K.tree; return 'tree'.freeze; end   # resource
    def K.type; return 'type'.freeze; end   # top_container
    def K.type_2; return 'type_2'.freeze; end   # sub_container
    def K.type_3; return 'type_3'.freeze; end   # sub_container
    def K.undefined; return '__UNDEFINED__'.freeze; end  # used everywhere
    def K.uri; return 'uri'.freeze; end
    def K.user_mtime; return 'user_mtime'.freeze; end
    def K.waypoints; return 'waypoints'.freeze; end  # trees
    def K.waypoint_size; return 'waypoint_size'.freeze; end  # trees
    def K.yes; return 'yes'.freeze; end
end
