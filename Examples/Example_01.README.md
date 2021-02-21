This is an example of loading a simple text file into a Resource.
It's only text.  No delimited records.   There a 4 record formats in the raw data:

    1)  Series/subseries records
    2)  Indent right, to start a record group
    3)  Outdent left, to end a record group
    4)  And everything else, which becomes an Archival-Object (AO).

The empty Resource is defined in the EAD file "MS_79_Central_Pacific.Empty.ead.xml".  
The Series and Subseries records are in the EAD.  This is a requirement for this
particular example.

The starting data is "Central_Pacific.unedited.txt".  This was exported from a Word doc as txt.

The manually edited version of the file is "Central_Pacific.edited.txt".  

The manual edits were:
    1)  Making sure the Series/Subseries records matches what was actually in the EAD.  The text has to match.
    2)  Added the ">:" and "<:" records to define with the "record groups".  
    3)  Fixed up some of the data.
    
The formatter is programmed to:
    1)  Find the series/subseries records and mark them as "new_parent" records.  The add_objects program
        will find the matching AO in the Resource and attach all the following records to it.
    2)  Find the ">:" and "<:" records and output an indent right or left record along with a "recordgrp" record
        with the text.
    3)  Parse the "everything else" records, looking for specific data inside brackets [].  This data is
        passed to the add_objects program which eventually adds AO's, "notes", and "top-containers".
        
How to run...

Import the "MS_79_Central_Pacific.Empty.ead.xml" file into ArchivesSpace.

Assuming the program code is in the RUBYLIB path, run the "central_pacific" formatter program to convert the 
"Central_Pacific.edited.txt" file into a file for the add_objects program, as follows:

cat Central_Pacific.edited.txt | ruby -w -S formatter.txt.to.add_objects.central_pacific.rb > central_pacific.as_input.txt

The "central_pacific.as_input.txt" file has 5 record formats:

    1)  {"__RECORD__":{"level":"__NEW_PARENT__","title":"Series 1: Financial Records"}}
        The "new parent" record is used to find an AO with the matching "title".  All following
        records are attached to the found record.  It doesn't have to any specific type of AO record.
    2)  {"__RECORD__":{"level":"recordgrp","title":"Abstract of earnings and operating expenses"}}
    3)  {"__INDENT__":["__RIGHT__","Abstract of earnings and operating expenses"]}
        These two records are the start of a new "Record Group".   There's the "recordgrp" record itself, then
        the "indent right" record. They'll always be in the same order.  The "indent" record doesn't create an AO, but tells the add_objects program
        to attach following records to the previous "recordgrp" record.  (The text in the "indent record"
        is just for debug purposes.)
    4)  {"__RECORD__":{"level":"file","notes":[{"jsonmodel_type":"note_singlepart","ingest_problem":"","type":"physloc","publish":true,"content":["Shelf I2.200.C7"],"label":"Statewide Museum Collections Center"}],"__CONTAINER__":{"__TC_TYPE__":"Box","__TC_INDICATOR__":"208","__SC_TYPE__":"object","__SC_INDICATOR__":"653"},"title":"Abstracts of cash disbursements, Sacramento Division, [Volume] Apr. - May 1912 "}}
        This is a "normal" data record used to create a AO.  This record as a "notes" array, as well as a "__CONTAINER__" hash that will be used to find
        the matching "top container", or create it, and attach the AO to it (along with any subcontainer data).
    5)  {"__INDENT__":["__LEFT__","<:"]}
        This is the "end indent" records.   Records following this one will be attached to the record prior to the last "recordgrp" record.


The "central_pacific.as_input.txt" is then used as input to the add_objects program, as follows:

ruby -w -S archivesspace.add_objects.rb --res-num NNN [--update] central_pacific.as_input.txt

"--res-num NNN" is the resource number.

The output will looks something like:

archivesspace.add_objects.rb:223:in '<main>': initial_parent_AO_uri = /repositories/2/resources/126     <<<<  The default parent of all records.
/repositories/2/archival_objects/167792 'Series 1: Financial Records'                                   <<<<  A list of all the current AO's in the resource.
/repositories/2/archival_objects/167793 'Series 2: Engineering Department Records'
/repositories/2/archival_objects/167800 'Subseries 1: Invoices and Vouchers'
/repositories/2/archival_objects/167801 'Subseries 2: Payroll'
...
archivesspace.add_objects.rb:242:in '<main>': Delete top_container: /repositories/2/top_containers/1666  <<<<  Any unused "top containers" are deleted.
...
archivesspace.add_objects.rb:299:in '<main>': Rec:1: '{"__RECORD__":{"level":"__NEW_PARENT__","title":"Series 1: Financial Records"}}'              <<< A "new parent" input record.
New parent: /repositories/2/archival_objects/167792 'Series 1: Financial Records'                                                                   <<< The matched uri

archivesspace.add_objects.rb:299:in '<main>': Rec:2: '{"__RECORD__":{"level":"file","notes":[{"jsonmodel_type":"note_singlepart","ingest_problem":"","type":"physloc","publish":true,"content":["Shelf I2.200.J6"],"label":"Statewide Museum Collections Center"}],"__CONTAINER__":{"__TC_TYPE__":"Box","__TC_INDICATOR__":"299","__SC_TYPE__":"object","__SC_INDICATOR__":"965"},"title":"Abstract of disbursements, [Volume] Jan. 1910 - Dec. 1911 "}}'
class.Archivesspace.TopContainer.rb:133:in 'store': Created TopContainer, uri = /repositories/2/top_containers/1739                                 <<<  Created a "top container" for record 2
class.Archivesspace.ArchivalObject.rb:167:in 'store': Created ArchivalObject, uri = /repositories/2/archival_objects/167808                         <<<  Created a "AO" for record 2

archivesspace.add_objects.rb:299:in '<main>': Rec:3: '{"__RECORD__":{"level":"recordgrp","title":"Abstract of earnings and operating expenses"}}'   <<<  A new "record group"
class.Archivesspace.ArchivalObject.rb:167:in 'store': Created ArchivalObject, uri = /repositories/2/archival_objects/167809                         <<<  Created the AO
archivesspace.add_objects.rb:279:in '<main>': Rec:4: '{"__INDENT__":["__RIGHT__","Abstract of earnings and operating expenses"]}'                   <<<  The following "Indent"
New parent: /repositories/2/archival_objects/167809                                                                                                 <<<  So the "New parent" uri is now 167809

archivesspace.add_objects.rb:299:in '<main>': Rec:5: '{"__RECORD__":{"level":"file","notes":[{"jsonmodel_type":"note_singlepart","ingest_problem":"","type":"physloc","publish":true,"content":["Shelf I2.300.H10"],"label":"Statewide Museum Collections Center"}],"__CONTAINER__":{"__TC_TYPE__":"Box","__TC_INDICATOR__":"6","__SC_TYPE__":"","__SC_INDICATOR__":""},"title":"[Volume] 1864 - 1870 "}}'
class.Archivesspace.TopContainer.rb:133:in 'store': Created TopContainer, uri = /repositories/2/top_containers/1740                                 <<<  Created another "top container" for record 5

class.Archivesspace.ArchivalObject.rb:167:in 'store': Created ArchivalObject, uri = /repositories/2/archival_objects/167810
archivesspace.add_objects.rb:299:in '<main>': Rec:6: '{"__RECORD__":{"level":"file","notes":[{"jsonmodel_type":"note_singlepart","ingest_problem":"","type":"physloc","publish":true,"content":["Item 252, Shelf I2.200.C10"],"label":"Statewide Museum Collections Center"}],"title":"[Volume] 1876 - 1879 "}}'
class.Archivesspace.ArchivalObject.rb:167:in 'store': Created ArchivalObject, uri = /repositories/2/archival_objects/167811
archivesspace.add_objects.rb:299:in '<main>': Rec:7: '{"__RECORD__":{"level":"file","notes":[{"jsonmodel_type":"note_singlepart","ingest_problem":"","type":"physloc","publish":true,"content":["Item 253, Shelf I2.200.C10"],"label":"Statewide Museum Collections Center"}],"title":"[Volume] 1880 - 1882 "}}'
class.Archivesspace.ArchivalObject.rb:167:in 'store': Created ArchivalObject, uri = /repositories/2/archival_objects/167812
archivesspace.add_objects.rb:299:in '<main>': Rec:8: '{"__RECORD__":{"level":"file","notes":[{"jsonmodel_type":"note_singlepart","ingest_problem":"","type":"physloc","publish":true,"content":["Item 254, Shelf I2.200.C10"],"label":"Statewide Museum Collections Center"}],"title":"[Volume] 1883 - 1885 "}}'
class.Archivesspace.ArchivalObject.rb:167:in 'store': Created ArchivalObject, uri = /repositories/2/archival_objects/167813
archivesspace.add_objects.rb:279:in '<main>': Rec:9: '{"__INDENT__":["__LEFT__","<:"]}'                                                             <<< End of "record group"
New parent: /repositories/2/archival_objects/167792                                                                                                 <<< So the "new parent" uri is the "Series 1:"
archivesspace.add_objects.rb:299:in '<main>': Rec:10: '{"__RECORD__":{"level":"file","notes":[{"jsonmodel_type":"note_singlepart","ingest_problem":"","type":"physloc","publish":true,"content":["Shelf I2.200.C7"],"label":"Statewide Museum Collections Center"}],"__CONTAINER__":{"__TC_TYPE__":"Box","__TC_INDICATOR__":"208","__SC_TYPE__":"object","__SC_INDICATOR__":"653"},"title":"Abstracts of cash disbursements, Sacramento Division, [Volume] Apr. - May 1912 "}}'
class.Archivesspace.TopContainer.rb:133:in 'store': Created TopContainer, uri = /repositories/2/top_containers/1741
