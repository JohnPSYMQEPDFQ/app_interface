# frozen_string_literal: true
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

module K
    def K.acqinfo; return 'acqinfo'; end                                    # notes (Immediate Source of Acquisition)
    def K.active_restrictions; return 'active_restrictions'; end            # top_container
    def K.ancestors; return 'ancestors'; end                                # archival_object
    def K.approximate; return 'approximate'; end                            # dates
    def K.archival_object; return 'archival_object'; end                    # root
    def K.archival_objects; return 'archival_objects'; end                  # <<<< Danger Plural
    def K.area; return 'area'; end                                          # location
    def K.barcode; return 'barcode'; end                                    # top_container location
    def K.begin; return 'begin'; end                                        # dates
    def K.bioghist; return 'bioghist'; end                                  # notes (Biographical / Historical)
    def K.box; return 'box'; end                                            # top_container
    def K.building; return 'building'; end                                  # location
    def K.bulk; return 'bulk'; end                                          # dates
    def K.calendar; return 'calendar'; end                                  # dates
    def K.certainty; return 'certainty'; end                                # dates
    def K.children; return 'children'; end
    def K.child_count; return 'child_count'; end                            # trees
    def K.circa; return 'circa'; end                                        # dates         <<<< Danger: This is NOT a 'certainty' value!
                                                                            #               It's for display of dates only.
    def K.classification; return 'classification'; end                      # location      <<<< Danger Singular
    def K.classifications; return 'classifications'; end                    # resource      <<<< Danger Plural
    def K.collection; return 'collection'; end                              # top_container
    def K.component_id; return 'component_id'; end                          # archival_object
    def K.container_locations; return 'container_locations'; end            # top_container
    def K.content; return 'content'; end
    def K.coordinate_1_indicator; return 'coordinate_1_indicator'; end      # location
    def K.coordinate_1_label; return 'coordinate_1_label'; end              # location
    def K.coordinate_2_indicator; return 'coordinate_2_indicator'; end      # location
    def K.coordinate_2_label; return 'coordinate_2_label'; end              # location
    def K.coordinate_3_indicator; return 'coordinate_3_indicator'; end      # location
    def K.coordinate_3_label; return 'coordinate_3_label'; end              # location
    def K.created_by; return 'created_by'; end
    def K.created_for_collection; return 'created_for_collection'; end      # top_container
    def K.create_time; return 'create_time'; end
    def K.creation; return 'creation'; end                                  # dates
    def K.date; return 'date'; end                  # <<<< Danger Singular  # revision_statements                       
    def K.date_certainty; return 'date_certainty'; end                      # spreadsheet column header for K.certainty
    def K.date_type; return 'date_type'; end                                # DANGER!!!  This is the date_type
                                                                            #            in the AO records (e.g. 'single', 'inclusive', 'bulk' )
                                                                            #            In the INDEX, the same thing is called just 'type' !!!
                                                                            
    def K.dates; return 'dates'; end                # <<<< Danger Plural    # archival_object, resource, formatter
    def K.dates_label; return 'dates_label'; end                            # spreadsheet column header for K.label
    def K.deaccessions; return 'deaccessions'; end                          # resource
    def K.description; return 'description'; end                            # revision_statements
    def K.dimensions; return 'dimensions'; end                              # extents, note_type
    def K.display_string; return 'display_string'; end
    def K.ead; return 'ead'; end                                            # spreadsheet column header for K.ead_id
    def K.ead_id; return 'ead_id'; end                                      # resource,  This and the id_0 must be unique
    def K.ead_location; return 'ead_location'; end                          # resource
    def K.embedded_CRLF; return '+++CRLF+++'; end                           # used in text of formatters
    def K.end; return 'end'; end                                            # dates
    def K.era; return 'era'; end                                            # dates
    def K.existence; return 'existence'; end                                # dates
    def K.exported_to_ils; return 'exported_to_ils'; end                    # top_container
    def K.expression; return 'expression'; end                              # dates
    def K.extents; return 'extents'; end                                    # archival_object, resource
    def K.extent_type; return 'extent_type'; end                            # extents
    def K.external_documents; return 'external_documents'; end              # archival_object, resource
    def K.external_ids; return 'external_ids'; end                          # archival_object, resource
    def K.file; return 'file'; end                                          # archival_object, top_containers
    def K.finding_aid_author; return 'finding_aid_author'; end                          # resource
    def K.finding_aid_date; return 'finding_aid_date'; end                              # resource
    def K.finding_aid_description_rules; return 'finding_aid_description_rules'; end    # resource
    def K.finding_aid_filing_title; return 'finding_aid_filing_title'; end              # resource
    def K.finding_aid_language; return 'finding_aid_language'; end                      # resource
    def K.finding_aid_language_note; return 'finding_aid_language_note'; end            # resource
    def K.finding_aid_note; return 'finding_aid_note'; end                              # resource
    def K.finding_aid_script; return 'finding_aid_script'; end                          # resource
    def K.finding_aid_series_statement; return 'finding_aid_series_statement'; end      # resource
    def K.finding_aid_status; return 'finding_aid_status'; end                          # resource
    def K.finding_aid_title; return 'finding_aid_title'; end                            # resource
    def K.floor; return 'floor'; end                                        # location
    def K.fmtr_auto_group; return '__AUTOGROUP__'; end                      # formatter auto_group record type
    def K.fmtr_container; return '__CONTAINER__'; end                       # formatter
    def K.fmtr_drop; return 'drop'; end                                     # formatter
    def K.fmtr_indent; return '__INDENT__'; end                             # formatter
    def K.fmtr_end_group; return '__END_GROUP__'; end                       # formatter 
    def K.fmtr_forced_indent; return '__FORCED_INDENT__'; end               # formatter
    def K.fmtr_inmagic_detail; return 'detail'; end                         # InMagic formatter column-use
    def K.fmtr_inmagic_recordgrp; return 'recordgrp'; end                   # InMagic formatter column-use
    def K.fmtr_inmagic_series; return 'series'; end                         # InMagic formatter column-use
    def K.fmtr_inmagic_seriesdate; return 'seriesdate'; end                 # InMagic formatter column-use
    def K.fmtr_inmagic_seriesnote; return 'seriesnote'; end                 # InMagic formatter column-use
    def K.fmtr_left; return '__LEFT__'; end                                 # formatter
    def K.fmtr_new_parent; return '__NEW_PARENT__'; end                     # formatter
    def K.fmtr_prefix; return 'prefix'; end                                 # formatter
    def K.fmtr_prepend; return 'prepend'; end                               # formatter
    def K.fmtr_record; return '__RECORD__'; end                             # formatter
    def K.fmtr_record_indent_keys; return '__RECORD_INDENT_KEYS__'; end     # formatter
    def K.fmtr_record_num; return '__RECORD_NUM__'; end                     # formatter
    def K.fmtr_record_original; return '__RECORD_ORIGINAL__'; end           # formatter
    def K.fmtr_record_sort_keys; return '__RECORD_SORT_KEYS__'; end         # formatter
    def K.fmtr_record_values; return '__RECORD_VALUES__'; end               # formatter
    def K.fmtr_record_values__text_idx; return 0; end                       # formatter
    def K.fmtr_record_values__dates_idx; return 1; end                      # formatter
    def K.fmtr_record_values__notes_idx; return 2; end                      # formatter
    def K.fmtr_record_values__container_idx; return 3; end                  # formatter
    def K.fmtr_right; return '__RIGHT__'; end                               # formatter
    def K.fmtr_shelf_box; return '__SHELF_BOX__'; end                       # formatter
    def K.folder; return 'folder'; end
    def K.group; return 'group'; end                                        # archive_object: other_level field.
    def K.has_unpublished_ancestor; return 'has_unpublished_ancestor'; end
    def K.hierarchy; return 'hierarchy'; end                                # spreadsheet
    def K.id; return 'id'; end                                              # tree
    def K.identifier; return 'identifier'; end                              # top_container name for id_0 & id
    def K.id_0; return 'id_0'; end                                          # resource  This and the ead_id must be unique.  
                                                                            #           This is called the 'unitid' in the XML dump file!
    def K.ils_holding_id; return 'ils_holding_id'; end                      # top_container
    def K.ils_item_id; return 'ils_item_id'; end                            # top_container
    def K.inclusive; return 'inclusive'; end
    def K.indicator; return 'indicator'; end                                # top_container
    def K.indicator_2; return 'indicator_2'; end                            # sub_container
    def K.indicator_3; return 'indicator_3'; end                            # sub_container
    def K.ingest_problem; return 'ingest_problem'; end
    def K.instance; return 'instance'; end          # <<<< Danger Singular  # instances     
    def K.instances; return 'instances'; end        # <<<< Danger Plural    # archival_object, resource
    def K.instance_type; return 'instance_type'; end                        # instances
    def K.is_representative; return 'is_representative'; end                # instances
    def K.is_slug_auto; return 'is_slug_auto'; end                          # archival_object, resource
    def K.item; return 'item'; end                                          # top_containers
    def K.jsonmodel_type; return 'jsonmodel_type'; end                      # everything
    def K.label; return 'label'; end                                        # dates
    def K.language; return 'language'; end                                  # language_and_script
    def K.language_and_script; return 'language_and_script'; end            # lang_materials
    def K.lang_materials; return 'lang_materials'; end                      # archival_object, resource
    def K.last_modified_by; return 'last_modified_by'; end
    def K.level; return 'level'; end                                        # archival_object, resource
    def K.linked_agents; return 'linked_agents'; end                        # archival_object, resource
    def K.linked_events; return 'linked_events'; end                        # archival_object, resourcr
    def K.location; return 'location'; end                                  # location
    def K.lock_version; return 'lock_version'; end                          # incremented with each update
    def K.long_display_string; return 'long_display_string'; end            # top_container
    def K.materialspec; return 'materialspec'; end                          # note singlepart (material specific)
    def K.mixed_materials; return 'mixed_materials'; end
    def K.n_physdesc; return 'n_physdesc'; end                              # Spreadsheet only: physical description note text
    def K.no; return 'no'; end   
    def K.node_type; return 'node_type'; end                                # tree
    def K.node_uri; return 'node_uri'; end                                  # tree
    def K.notes; return 'notes'; end                                        # archival_object, lang_materials, resource, formatter
    def K.note_multipart; return 'note_multipart'; end   
    def K.note_singlepart; return 'note_singlepart'; end   
    def K.note_text; return 'note_text'; end
    def K.number; return 'number'; end                                      # extents
    def K.object; return 'object'; end                                      # top_container
    def K.offset; return 'offset'; end                                      # tree
    def K.otherlevel; return 'otherlevel'; end                              # archival_object (value for 'level' field)
    def K.other_level; return 'other_level'; end                            # archival_object (field name for 'otherlevel' value, eg "group")
    def K.p_physdesc; return 'p_physdesc'; end                              # Spreadsheet only: physical description note publish
    def K.parent; return 'parent'; end
    def K.parent_id; return 'parent_id'; end                                # tree
    def K.parent_node; return 'parent_node'; end                            # tree
    def K.password; return 'password'; end
    def K.persistent_id; return 'persistent_id'; end
    def K.physical_details; return 'physical_details'; end                  # extents
    def K.physdesc; return 'physdesc'; end                                  # note singlepart (physical description)
    def K.physloc; return 'physloc'; end                                    # note singlepart (physical location)
    def K.portion; return 'portion'; end                                    # extents
    def K.position; return 'position'; end
    def K.precomputed_waypoints; return 'precomputed_waypoints'; end        # tree
    def K.processinfo; return 'processinfo'; end                            # note multipart (process information)
    def K.publish; return 'publish'; end
    def K.recordgrp; return 'recordgrp'; end                                # archival_object
    def K.recordgrp_text; return 'Record Group'; end                        # formatters
    def K.record_uri; return 'record_uri'; end
    def K.ref; return 'ref'; end                                            # archival_object, sub_container
    def K.ref_id; return 'ref_id'; end                                      # archival_object
    def K.related_accessions; return 'related_accessions'; end              # resource
    def K.repository; return 'repository'; end
    def K.resource; return 'resource'; end                                  # archival_object
    def K.resource_tree; return 'resource_tree'; end
    def K.restrictions; return 'restrictions'; end                          # resource
    def K.restrictions_apply; return 'restrictions_apply'; end              # archival_object
    def K.revision_statements; return 'revision_statements'; end            # resource
    def K.rights_statements; return 'rights_statements'; end                # archival_object, resource
    def K.room; return 'room'; end                                          # archival_object, location
    def K.scopecontent; return 'scopecontent'; end                          # note multipart (Scope and Content)
    def K.script; return 'script'; end                                      # language_and_script
    def K.series; return 'series'; end                                      # archival_object
    def K.session; return 'session'; end
    def K.shelf; return 'shelf'; end                                        # Someday (maybe) the shelf that the box is located on.  
    def K.single; return 'single'; end
    def K.slugged_url; return 'slugged_url'; end                            # archival_object
    def K.status; return 'status'; end                                      # http
    def K.subjects; return 'subjects'; end                                  # archival_object, resource
    def K.subnotes; return 'subnotes'; end
    def K.subseries; return 'subseries'; end                                # As text, it's Sub-series;  see K.sub_series_text   
    def K.sub_container; return 'sub_container'; end                        # instances
    def K.sub_series_text; return 'Sub-series'; end                         # The 'level' value is subseries
    def K.suppressed; return 'suppressed'; end
    def K.spreadsheet_true; return 1; end                                   # Harvard-Spreadsheet (for booleans)
    def K.spreadsheet_false; return 0; end                                  # Harvard-Spreadsheet (for booleans)
    def K.system_mtime; return 'system_mtime'; end
    def K.title; return 'title'; end                                        # archival_object, resource
    def K.top_container; return 'top_container'; end                        # sub_container
    def K.tree; return 'tree'; end                                          # resource
    def K.type; return 'type'; end                                          # top_container, notes, and dates in the INDEX.
                                                                            #                       Also see: date_type (above).   
    def K.type_2; return 'type_2'; end                                      # sub_container
    def K.type_3; return 'type_3'; end                                      # sub_container
    def K.undefined; return '__UNDEFINED__'; end                            # used everywhere
    def K.uri; return 'uri'; end
    def K.user_mtime; return 'user_mtime'; end
    def K.volume; return 'volume'; end
    def K.waypoints; return 'waypoints'; end                                # trees
    def K.waypoint_size; return 'waypoint_size'; end                        # trees
    def K.yes; return 'yes'; end
    
    def K.alpha_month_RES
        stringer = '(january|february|march|april|may|june|july|august|september|october|november|december' +
                   '|jan\\.|feb\\.|mar\\.|apr\\.|may\\.|jun\\.|jul\\.|aug\\.|sep\\.|oct\\.|nov\\.|dec\\.' +
                   '|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec' +
                   ')'
        return stringer
    end 
    def K.alpha_month_RE
        return /#{K.alpha_month_RES}/xi
    end 
    def K.numeric_month_RES
        stringer = '(?:0?[1-9]|1[012])'
        return stringer
    end
    def K.numeric_month_RE
        return /#{K.numeric_month_RES}/xi
    end 
    def K.day_RES
        stringer = '(?:[0-9]|[012][0-9]|3[01])'
        return stringer
    end
    def K.day_RE
        return /#{K.day_RES}/
    end 
    def K.year4_RES
        stringer = '(?:1[789][0-9][0-9]|20[0-9][0-9])'
        return stringer
    end 
    def K.year4_RE
        return /#{K.year4_RES}/
    end 
    def K.year2_RES
        stringer = '(?:[0-9][0-9])'
        return stringer
    end
    def K.year2_RE
        return /#{K.year2_RES}/
    end 
    
    def K.fmtr_empty_container_H
        h = { K.shelf => nil,                                               # Use this to (someday) lookup a location.
              K.type => nil,
              K.indicator => nil,
              K.type_2 => '' ,
              K.indicator_2 => '' ,
              K.type_3 => '' ,
              K.indicator_3 => '' ,
              }.freeze
        return {}.merge( h )
    end    
    
    def K.container_type_separators_RES
        return '(\s+and\s+|\s*-\s*|\s*,\s*)'
    end
    
    def K.valid_container_types_RES
        return '(ov |box(s|es)?)'
    end
    def K.valid_child_types_RES
        return '(folders?|volumes?|items?)'
    end
    def K.valid_grandchild_types_RES
        return '(volumes?|files?)'
    end    

    def K.min_length_for_indent_key; return 3; end                  # Used in class.formatter.Record_Grouping_Indent.rb
    def K.skip_these_values_for_indent_key_A                        # Used in class.formatter.Record_Grouping_Indent.rb
        arr = [ 'ov', K.box, K.folder, K.volume, K.item, K.file ].freeze
        return arr
    end
    
    def K.container_and_child_types_RES   
        # stringer = '(?<begin_del>(\A|\s+|\[\s*))' +     # MUST use the /x option on the regex!!!
                   # '(?<inside_the_dels>' + 
                       # '(' +
                           # '(?<container_type>(ov |box(s|es)?))((\s+(nos?|numbers?)\.?))?(\s+)(?<container_num>[0-9]+(' + K.container_type_separators_RES + '[0-9]+)?),?' + 
                           # '(\s+(?<container_type_modifier>(ov|oversized?|\[oversized?\]|rc|record[\-\s]?cards?|sb|slide[\-\s]?box|\[slide[\-\s]?box\]))(\Z|\.|,)?)?' + 
                           # '(\s+(?<child_type>      (folders?|volumes?|items?))     (\s+(nos?|numbers?)\.?)?  (\s+(?<child_num>     ([0-9]+[a-z]?|[ivx]+)(' + K.container_type_separators_RES + '([0-9]+[a-z]?|[ivx]+))?  ))?  )?' +
                           # '(\s+(?<grandchild_type> (volumes?|files?))              (\s+(nos?|numbers?)\.?)?  (\s+(?<grandchild_num>([0-9]+[a-z]?|[ivx]+)(' + K.container_type_separators_RES + '([0-9]+[a-z]?|[ivx]+))?  ))?  )?' +
                       # ')' +
                   # ')' +
                   # '(?<end_del>(\Z|\.|,|:|\s*\]|\s+))'           
        # stringer = '(?<begin_del>(\A|\s+|\[\s*))' +     # MUST use the /x option on the regex!!!
                   # '(?<inside_the_dels>' + 
                       # '(' +
                           # '(?<container_type>'       + "(#{K.valid_container_types_RES}|#{K.valid_child_types_RES})" + ')((\s+(nos?|numbers?)\.?))?(\s+)(?<container_num>[0-9]+                (' + K.container_type_separators_RES + '[0-9]+)?),?' + 
                           # '(\s+(?<container_type_modifier>(ov|oversized?|\[oversized?\]|rc|record[\-\s]?cards?|sb|slide[\-\s]?box|\[slide[\-\s]?box\]))(\Z|\.|,)?)?' + 
                           # '(\s+(?<child_type>      ' + K.valid_child_types_RES                                       + ') (\s+(nos?|numbers?)\.?)?  (\s+(?<child_num>     ([0-9]+[a-z]?|[ivx]+)(' + K.container_type_separators_RES + '([0-9]+[a-z]?|[ivx]+))?  ))?  )?' +
                           # '(\s+(?<grandchild_type> ' + K.valid_grandchild_types_RES                                  + ') (\s+(nos?|numbers?)\.?)?  (\s+(?<grandchild_num>([0-9]+[a-z]?|[ivx]+)(' + K.container_type_separators_RES + '([0-9]+[a-z]?|[ivx]+))?  ))?  )?' +
                       # ')' +
                   # ')' +
                   # '(?<end_del>(\Z|\.|,|:|\s*\]|\s+))'    
        stringer = '(\A|\s+|\[\s*)\K' +                #\K = The behavior of \K is similar to a positive lookbehind assertion (?<=...), but with the key advantage of allowing variable-length lookbehind
                                                       # MUST use the /x option on the regex!!!
                   '(?<inside_the_dels>' + 
                       '(' +
                           '(?<container_type>'       + "(#{K.valid_container_types_RES}|#{K.valid_child_types_RES})" + ')((\s+(nos?|numbers?)\.?))?(\s+)(?<container_num>[0-9]+         (' + K.container_type_separators_RES + '[0-9]+)?),?' + 
                           '(\s+(?<container_type_modifier>(ov|oversized?|\[oversized?\]|rc|record[\-\s]?cards?|sb|slide[\-\s]?box|\[slide[\-\s]?box\]))(\Z|\.|,)?)?' + 
                           '(\s+(?<child_type>      ' + K.valid_child_types_RES                                       + ') (\s+(nos?|numbers?)\.?)?  (\s+(?<child_num>     [0-9]+[a-z]?(' + K.container_type_separators_RES + '[0-9]+[a-z]?)?  ))?  )?' +
                           '(\s+(?<grandchild_type> ' + K.valid_grandchild_types_RES                                  + ') (\s+(nos?|numbers?)\.?)?  (\s+(?<grandchild_num>[0-9]+[a-z]?(' + K.container_type_separators_RES + '[0-9]+[a-z]?)?  ))?  )?' +
                       ')' +
                   ')' +
                   '(?<trailing_del>(\Z|\s*[.,;:\]]|\s+))'        
#       When adding or changing stuff (like the '<container_type_modifier>') don't forget to add them to 
#       the 'formatter.dictation_1.to.indent.rb' program.        
        return stringer
    end
    def K.container_and_child_types_RE
        return /#{K.container_and_child_types_RES}/ix
    end
    def K.container_bracketed_word_RES
        stringer = '\[\s*(?<bracketed_word>(volumes?|letterpress))\s*\]'
        return stringer
    end
    def K.container_bracketed_word_RE
        return /#{K.container_bracketed_word_RES}/i
    end

    def K.any_fmtr_group_record_RES
        stringer = "(#{K.series}|#{K.recordgrp_text}|#{K.subseries}|#{K.sub_series_text}|#{K.group})"   #Used to have the number and an extra set of parentheeseses
        return stringer
    end
   
end
