# ArchivesSpace Backend App interface

This code was written (over a two-year period) to support the California State Railroad Museum Library migration of data to ArchivesSpace.

## The basic requirement was:

1) Data is located in some database, spreadsheet, or other text-oriented document.

2) The data needs to edited and (sometimes) grouped by "subjects" (for indentation purposes. The series, subseries, group things...) 

3) The data needs to be loaded into ArchivesSpace and attached to an existing Resource, sometimes as children of an existing Archival-Object.

## The basic solution was:

1) The data would be extracted from the "other place”, delimited with semicolons.

2) The data would be edited (if needed) and "lightly" formatted using a "good" text-editor (not notepad or wordpad).

3) The data would be passed through a custom formatter that would (depending on the data):
   
   a. Convert free-format dates into Aspace friendly dates.
   
   b.  Assign "top-container" info to the records (stuff like: box numbers and folder numbers). 
   
   c.  Create "note data" with information like: "I couldn't format a date" -or- "here's the original record".
   
   d.  Split the record data into "Group Key Data" and "Not Group Key data" (two sets of data).
   
   e.  Output a jsonized record for input into the "Group Indenter Program" or the "Archival-Object Loader" program.

4) If the data was "indent aware", the file from step 3 was passed into the "Group Indenter Program" which:
   
   a.  sorted the data (actually this was done with Unix 'sort' but was easier to type here).
   
   b.  Process the "Group Key Data" (see 3e) and create "Indent Right" or "Indent Left" records with group sequencing numbers:  
   
        Series 1.2.7: Southern Pacific. Locomotives. Steam Engines
   
   c.  Output the record data (and records from 4b) in processing order.

5) Load the file from Step 4 (or 3, if grouping wasn't needed) into ArchivesSpace, which does:
   
   a.  Get the Resource Record and (optionally) an existing Archival-Object record to attach the new records to (as children).
   
       This initial parent-record is added to a parent-stack.
   
   b.  Read each input record.   Determine if it's a regular data record or an "indent right/left" record (see 4b).
   
   - For a regular data record:
     
     - Initialize a new Archival-Object record.
     
     - Look-up the top-container data and "post" a new top-container record (if needed)
     
     - Store the new or existing top-container "refid" in the initialize AO record.
     
     - Create any note and date sub-records in the AO records.
     
     - Store the parent-refid in the initialized Archival-Object record.
     
     - "Post" the new Archival-Object record.
   
   - For an "Indent Right" record:
     
     - Initialize a new Archival-Object record.
     
     - Store the parent-ref in the initialized Archival-Object record.
     
     - "Post" the new Archival-Object record.
     
     - Push the (new created) uri of this record onto the parent-stack.
   
   - For an "Indent Left" record:
     
     - Pop the parent-stack.

That's basically it.
