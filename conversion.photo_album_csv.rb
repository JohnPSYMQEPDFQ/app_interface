require 'class.ArchivesSpace.rb'
require 'class.Find_Dates_in_String.rb'
require 'csv'
require 'optparse'

        # "Binder_num" => "5",
    # "Corporate Name" => "AT&SF",
             # "Dates" => "1988-1994",
             # "Notes" => "Includes restoration work and presentation to CSRM",
          # "Quantity" => "1 of 1",
            # "Series" => "Equipment",
             # "Title" => "Locomotives. Diesel"


module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :cmdln_option_H, 
                      :find_dates_with_4digit_years_O, :aspace_O, :min_date, :max_date
    
    #   input_row_CSV column name constants
        BINDER_NUM      = 'Binder_num'
        CORPORATE_NAME  = 'Corporate Name'
        DATES           = 'Dates'
        NOTES           = 'Notes'
        QUANTITY        = 'Quantity'
        SERIES          = 'Series'
        TITLE           = 'Title'
        

                      
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

# ------------------------------
# Harvard headers (notes included as n_/p_ pairs)
# ------------------------------
HARVARD_HEADERS = [
  "ArchivesSpace field code (please don't edit this row)",
  "collection_id","ead","ref_id","title","unit_id","hierarchy","level","other_level","publish",
  "restrictions_flag","processing_note",
  "dates_label","begin","end","date_type","expression","date_certainty",
  "dates_label_2","begin_2","end_2","date_type_2","expression_2","date_certainty_2",
  "portion","number","extent_type","container_summary","physical_details","dimensions",
  "portion_2","number_2","extent_type_2","container_summary_2","physical_details_2","dimensions_2",
  "cont_instance_type","type_1","indicator_1","barcode","type_2","indicator_2","type_3","indicator_3",
  "cont_instance_type_2","type_1_2","indicator_1_2","barcode_2","type_2_2","indicator_2_2","type_3_2","indicator_3_2",
  "digital_object_title","digital_object_link","thumbnail",
  # notes (n_ = note text, p_ = publish flag)
  "n_abstract","p_abstract",
  "n_accessrestrict","p_accessrestrict",
  "n_acqinfo","p_acqinfo",
  "n_arrangement","p_arrangement",
  "n_bioghist","p_bioghist",
  "n_custodhist","p_custodhist",
  "n_dimensions","p_dimensions",
  "n_odd","p_odd",
  "n_langmaterial","p_langmaterial",
  "n_physdesc","p_physdesc",
  "n_physfacet","p_physfacet",
  "n_physloc","p_physloc",
  "n_prefercite","p_prefercite",
  "n_processinfo","p_processinfo",
  "n_relatedmaterial","p_relatedmaterial",
  "n_scopecontent","p_scopecontent",
  "n_separatedmaterial","p_separatedmaterial",
  "n_userestrict","p_userestrict"
]

def scrape_off_dates( title_field )
    title_field.sub!( /\s*\.\s*$/, '' )
    from_thru_date_H_A = [ ]
    title_field = self.find_dates_with_4digit_years_O.do_find( title_field )
    self.find_dates_with_4digit_years_O.good__date_clump_S__A.each do | date_clump_S |
        from_thru_date_H = {}
        from_thru_date_H[ K.begin ] = date_clump_S.as_from_date
        if ( self.min_date == '' or self.min_date > date_clump_S.as_from_date ) then
            self.min_date = date_clump_S.as_from_date
        end
        if ( self.max_date == '' or self.max_date < date_clump_S.as_from_date ) then
            self.max_date = date_clump_S.as_from_date
        end

        from_thru_date_H[ K.end ] = date_clump_S.as_thru_date( :else_from_date )
        if ( self.min_date == '' or self.min_date > from_thru_date_H[ K.end ] ) then
            self.min_date = from_thru_date_H[ K.end ]
        end
        if ( self.max_date == '' or self.max_date < from_thru_date_H[ K.end ]) then
            self.max_date = from_thru_date_H[ K.end ]
        end 
        from_thru_date_H[ K.bulk ]      = date_clump_S.bulk 
        from_thru_date_H[ K.certainty ] = date_clump_S.certainty 
        from_thru_date_H[ K.expression] = self.aspace_O.format_date_expression( from_date: from_thru_date_H[ K.begin ], 
                                                                                certainty: from_thru_date_H[ K.certainty ] )
        from_thru_date_H_A << from_thru_date_H
    end
    return from_thru_date_H_A
end

def fill_dates( harvard_row_H, input_row_H )
  if ( input_row_H.has_key?( DATES ) and input_row_H[ DATES ].not_blank? ) then
    input_row_H[ TITLE ] = " #{input_row_H[ DATES ]}"
  end 
  dates = scrape_off_dates( input_row_H[ TITLE ] )
  warn "Warning: input_row_H #{input_row_H[ TITLE ]} has #{dates.size} dates; only first two exported." if dates.size > 2
  dates.first(2).each_with_index do | d, i |
    s = (i == 0 ? '' : "_2")
    harvard_row_H[ "dates_label#{s}" ]    = K.creation
    harvard_row_H[ "begin#{s}" ]          = d[ K.begin ]
    harvard_row_H[ "end#{s}" ]            = d[ K.end ]
    harvard_row_H[ "date_type#{s}" ]      = K.inclusive
    harvard_row_H[ "expression#{s}" ]     = d[ K.expression ]
  end
end

def fill_instances(harvard_row_H, input_row_H )  
    harvard_row_H[ "cont_instance_type"] = K.mixed_materials
    harvard_row_H[ "type_1" ]            = "binder" 
    if ( input_row_H.has_no_key?( BINDER_NUM ) or input_row_H[ BINDER_NUM ].nil? ) then
        SE.q {'input_row_H'}
        raise
    end
    harvard_row_H[ "indicator_1" ]       = input_row_H[ BINDER_NUM ]
end

def fill_notes(harvard_row_H, input_row_H)
    return if ( input_row_H.has_no_key?( NOTES ) or input_row_H[ NOTES ].blank? )
    type = 'scopecontent' 
    # n_ => note text; p_ => publish flag
    harvard_row_H[ "n_#{type}" ] = input_row_H[ NOTES ]
    harvard_row_H[ "p_#{type}" ] = 1
end

# ------------------------------
# Build a full harvard_row_H for an input_row_H
# ------------------------------
def build_harvard_row_H_from_input_row_H( input_row_H )
    harvard_row_H = Hash[HARVARD_HEADERS.map { | e | [ e, nil ] }]

#   harvard_row_H[ "collection_id" ]     = collection_id
    harvard_row_H[ "ead" ]               = self.cmdln_option_H[ :ead ]
    harvard_row_H[ "title" ]             = input_row_H[ TITLE ]
    if ( input_row_H[ K.level ] == K.file ) then
        arr = []
        arr << input_row_H[ CORPORATE_NAME ] + '.'
        arr << input_row_H[ TITLE ]
        arr << "[#{input_row_H[ QUANTITY ]}]" if ( input_row_H.has_key?( QUANTITY ) && input_row_H[ QUANTITY ].not_blank? )
        harvard_row_H[ "title" ] = arr.join( ' ' )
    else
        harvard_row_H[ "title" ]         = input_row_H[ TITLE ]
    end
    harvard_row_H[ "hierarchy" ]         = input_row_H[ K.hierarchy ]
    harvard_row_H[ "level" ]             = input_row_H[ K.level ]
    harvard_row_H[ "other_level" ]       = input_row_H[ K.other_level ]
    harvard_row_H[ "publish" ]           = 1

    if ( input_row_H[ K.level ] == K.file ) then
        fill_dates( harvard_row_H, input_row_H ) 
        fill_instances( harvard_row_H, input_row_H )
        fill_notes( harvard_row_H, input_row_H )
    end

    harvard_row_H
end

def control_fields_H( hierarchy:, level:, other_level: '' )
    {   K.hierarchy     => hierarchy, 
        K.level         => level,
        K.other_level   => other_level,
    }
end

BEGIN{}
END{}

self.myself_name = File.basename( $0 )
self.aspace_O = ASpace.new
self.find_dates_with_4digit_years_O = Find_Dates_in_String.new( { Find_Dates_in_String::MORALITY_OPTION => { :good  => Find_Dates_in_String::REMOVE_FROM_END },
                                                                  :pattern_name_RES => '.',
                                                                  :date_string_composition => :dates_in_text,
                                                                  :yyyymmdd_min_value => '1800',
                                                                } )

# ------------------------------
# CLI parsing
# ------------------------------
self.cmdln_option_H = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby #{self.myself_name} --ead EADID "

  opts.on("--ead ID", String, "EAD ID string (required)")       { |v| self.cmdln_option_H[ :ead ] = v }

end.parse!

abort("ERROR: --ead is required.") unless self.cmdln_option_H[ :ead ]

csv_input_file = ARGV[0]   
if ( csv_input_file.nil? ) then
    SE.puts "No file specific (ARGV[0] == nil)"
    exit
end

# --- Read CSV into an array of hashes ---
header_A = [] 
input_row_H_A = []
csv_O = CSV.open( csv_input_file, :headers => true )
csv_O.each do | input_row_CSV |
    input_row_H_A.push( input_row_CSV.to_h.compact )
end
header_A = csv_O.headers.to_a.compact
header_A.delete_if { | header | input_row_H_A.all? { | input_row_H | input_row_H[ header ].nil? } }
csv_O.close

self.min_date = ''
self.max_date = ''

output_row_H_A = []
series_A = input_row_H_A.map { | h | h[ SERIES ] }.uniq
series_A.each_with_index do | series, idx |
    group_row_H = { TITLE => "Series #{idx + 1}: #{series}"}.merge( control_fields_H( hierarchy: 1, 
                                                                                      level: K.series, 
                                                                                      other_level: '' ) )
    output_row_H_A << build_harvard_row_H_from_input_row_H( group_row_H )
#   puts "Series row '#{group_row_H[ TITLE ]}'"
    corporate_name_H = input_row_H_A.filter_map { | h |  h[ CORPORATE_NAME ] if ( h[ SERIES ] == series ) }.tally
    corporate_name_H.each_pair do | corporate_name, count |
        do_group = ( corporate_name_H.keys.count > 1 and count > 1 ) 
        if ( do_group ) then
            group_row_H = { TITLE => "#{corporate_name}"}.merge( control_fields_H( hierarchy: 2, 
                                                                                   level: K.otherlevel, 
                                                                                   other_level: "Group" ) )
            output_row_H_A << build_harvard_row_H_from_input_row_H( group_row_H )
#           puts "Group row in '#{series}' -> '#{corporate_name}"
        end
        input_row_H_A.each.select { | h | h[ SERIES ] == series && h[ CORPORATE_NAME ] == corporate_name }.each do | input_row_H | 
            file_row_H = input_row_H.merge( control_fields_H( hierarchy: do_group ? 3 : 2, 
                                                              level: K.file ) )
            output_row_H_A << build_harvard_row_H_from_input_row_H( file_row_H )
#           SE.q { 'file_row_H' }
        end
    end
end

csv_output_file = csv_input_file.sub( /\.csv$/, '') + '.harvard_spreadsheet.csv'
CSV.open( csv_output_file, 'w', write_headers: true, headers: HARVARD_HEADERS) do | output_row_CSV |
    output_row_H_A.each do | output_row_H | 
        output_row_CSV << HARVARD_HEADERS.map { | e | output_row_H[ e ] } 
    end
end

SE.q {[ self.min_date, self.max_date ]}



