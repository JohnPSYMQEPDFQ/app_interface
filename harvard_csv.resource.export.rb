=begin
Odd things...

If you see this error when loading the Harvard Spreadsheet:

    Unable to create Container Instance 1: [undefined method `message' for nil:NilClass]
    
        This means the container type value, or instance type_2 or type_3 value, doesn't have a corresponding value in
        the 'Controlled Value List: Container Type (container_type)'.  

        However, there's also a strange oddity in the 'Controlled Value List':   
        
            The 'value' and 'translation' values are cases-insensitive.  And the order seems to matter.
            I hit a problem where I had the following values for folders:
            
                Position    Value   Translation
                6           Folder  Folder
                7           folder  Folder
                
            When the spreadsheet used "Folder" in the type_2 field, the record would process correctly.
            When the value was "folder" it would fail with the above error, AND not add the Top-Container record.
            When I flipped the order around, to:
            
                Position    Value   Translation
                6           folder  Folder
                7           Folder  Folder
                
            Then "Folder" and "folder" both worked.
            
=end

# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'csv'
require 'optparse'
require 'class.Archivesspace.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.TopContainer.rb'

# ------------------------------
# Defaults (overrideable via CLI)
# ------------------------------
DEFAULT_BASE_URL = "http://localhost:8089"
DEFAULT_USER     = "admin"
DEFAULT_PASS     = "admin"
REPO_ID          = 2

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

# Supported note types (exported into columns). All other note types are warned only.
SUPPORTED_NOTE_TYPES = %w[
  abstract accessrestrict acqinfo arrangement bioghist custodhist
  dimensions odd langmaterial physdesc physfacet physloc
  prefercite processinfo relatedmaterial scopecontent separatedmaterial userestrict
]

# ------------------------------
# CLI parsing
# ------------------------------
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby harvard_export.rb --res-num NNN --ead EADID [--base-url URL --user USER --password PASS]"

  opts.on("--res-num N", Integer, "Resource number (required)") { |v| options[:res_num] = v }
  opts.on("--ead ID", String, "EAD ID string (required)")       { |v| options[:ead] = v }
  opts.on("--base-url URL", String, "ArchivesSpace backend URL (default #{DEFAULT_BASE_URL})") { |v| options[:base_url] = v }
  opts.on("--user USER", String, "Username (default #{DEFAULT_USER})") { |v| options[:user] = v }
  opts.on("--password PASS", String, "Password (default #{DEFAULT_PASS})") { |v| options[:password] = v }
end.parse!

abort("ERROR: Both --res-num and --ead are required.") unless options[:res_num] && options[:ead]

BASE_URL   = options[:base_url] || ENV[ 'ASPACE_URI_BASE' ]
USERNAME   = options[:user]     || DEFAULT_USER
PASSWORD   = options[:password] || DEFAULT_PASS
RESOURCE_ID= options[:res_num]
EAD_ID     = options[:ead]
OUTPUT_CSV = "harvard_export.#{EAD_ID}.csv"

# ------------------------------
# ArchivesSpace API helpers
# ------------------------------
def aspace_login
  # uri = URI("#{BASE_URL}/users/#{USERNAME}/login")
  # res = Net::HTTP.post_form(uri, 'password' => PASSWORD)
  # raise "Login failed: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)
  # JSON.parse(res.body)['session']
  aspace_O = ASpace.new
  aspace_O.session
end

def get_json(path_or_uri )
  url = path_or_uri.start_with?('http') ? path_or_uri : "#{BASE_URL}#{path_or_uri}"
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  req['X-ArchivesSpace-Session'] = SESSION
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(req) }
  raise "GET #{path_or_uri} failed: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)
  JSON.parse(res.body)
end

def fetch_resource()
  get_json("/repositories/#{REPO_ID}/resources/#{RESOURCE_ID}")
end

def resource_identifier_string(resource)
  [resource["id_0"], resource["id_1"], resource["id_2"], resource["id_3"]].compact.join(".")
end


# ------------------------------
# Data fill helpers
# ------------------------------
def fill_dates(row, ao)
  dates = ao["dates"].to_a
  warn "Warning: AO #{ao['uri']} has #{dates.size} dates; only first two exported." if dates.size > 2
  dates.first(2).each_with_index do |d, i|
    s = (i == 0 ? "" : "_2")
    row["dates_label#{s}"]    = d["label"]
    row["begin#{s}"]          = d["begin"]
    row["end#{s}"]            = d["end"]
    row["date_type#{s}"]      = d["date_type"]
    row["expression#{s}"]     = d["expression"]
    row["date_certainty#{s}"] = d["certainty"]
  end
end

def fill_extents(row, ao)
  exts = ao["extents"].to_a
  warn "Warning: AO #{ao['uri']} has #{exts.size} extents; only first two exported." if exts.size > 2
  exts.first(2).each_with_index do |e, i|
    s = (i == 0 ? "" : "_2")
    row["portion#{s}"]           = e["portion"]
    row["number#{s}"]            = e["number"]
    row["extent_type#{s}"]       = e["extent_type"]
    row["container_summary#{s}"] = e["container_summary"]
    row["physical_details#{s}"]  = e["physical_details"]
    row["dimensions#{s}"]        = e["dimensions"]
  end
end

def fetch_top_container(sub_container, tc_query_O)
  ref = sub_container.dig("top_container", "ref")
  return nil unless ref
  tc = tc_query_O.record_H_of_uri_num( ref )
  if ( tc.nil? ) then
    raise "Invalid tc ref '#{ref}'"
  end
  return tc
end

def fill_instances(row, ao, tc_query_O)
  insts = ao["instances"].to_a

  # Warn if AO references multiple different top-container refs across instances
  tc_refs = insts.map { |i| i.dig("sub_container", "top_container", "ref") }.compact.uniq
  warn "Warning: AO #{ao['uri']} links to multiple top containers (#{tc_refs.size})." if tc_refs.size > 1

  warn "Warning: AO #{ao['uri']} has #{insts.size} instances; only first two exported." if insts.size > 2

  insts.first(2).each_with_index do |inst, i|
    s = (i == 0 ? "" : "_2")
    row["cont_instance_type#{s}"] = inst["instance_type"]

    subc = inst["sub_container"]
    if subc
      # child & grandchild values are stored on sub_container as type_2/indicator_2 and type_3/indicator_3
      row["type_2#{s}"]      = subc["type_2"]
      row["indicator_2#{s}"] = subc["indicator_2"]
      row["type_3#{s}"]      = subc["type_3"]
      row["indicator_3#{s}"] = subc["indicator_3"]

      if (tc = fetch_top_container(subc, tc_query_O))
        row["type_1#{s}"]      = tc["type"]
        row["indicator_1#{s}"] = tc["indicator"]
        row["barcode#{s}"]     = tc["barcode"]
      end
    end
  end
end

# extract note text for singlepart and multipart notes (handles strings and arrays)
def extract_note_text(note)
  chunks = []
  case note["jsonmodel_type"]
  when "note_singlepart"
    c = note["content"]
    if c.is_a?(Array)
      chunks.concat(c.compact)
    elsif c.is_a?(String)
      chunks << c
    end
  when "note_multipart"
    (note["subnotes"] || []).each do |s|
      sc = s.is_a?(Hash) ? s["content"] : s
      if sc.is_a?(Array)
        chunks.concat(sc.compact)
      elsif sc.is_a?(String)
        chunks << sc
      end
    end
  end
  chunks.compact.map { |x| x.to_s.strip }.reject(&:empty?).join("\n\n")
end

def fill_notes(row, ao)
  (ao["notes"] || []).each do |note|
    type = note["type"] == 'materialspec' ? 'scopecontent' : note["type"]
    unless SUPPORTED_NOTE_TYPES.include?(type)
      warn "Warning: AO #{ao['uri']} has unsupported note type '#{type}' (ignored)"
      next
    end

    text = extract_note_text(note)
    publish_flag = note.key?("publish") ? (note["publish"] ? 1 : 0) : nil

    # n_ => note text; p_ => publish flag
    row["n_#{type}"] = [row["n_#{type}"], text].compact.reject(&:empty?).join("\n\n") unless text.to_s.strip.empty?
    row["p_#{type}"] = publish_flag if publish_flag
  end
end

# ------------------------------
# Build a full row for an AO
# ------------------------------
def build_row_from_ao(ao, collection_id, tc_query_O)
  row = Hash[HARVARD_HEADERS.map { |h| [h, nil] }]

  row["collection_id"]     = collection_id
  row["ead"]               = EAD_ID
  row["title"]             = ao["title"]
  row["unit_id"]           = ao["component_id"]
  row["hierarchy"]         = ao["ancestors"].length
  row["level"]             = ao["level"]
  row["other_level"]       = ao["other_level"]
  row["publish"]           = ao["publish"] ? 1 : 0
  row["restrictions_flag"] = ao["restrictions"] ? 1 : 0

  fill_dates(row, ao)
  fill_extents(row, ao)
  fill_instances(row, ao, tc_query_O)
  fill_notes(row, ao)

  row
end


# ------------------------------
# Main
# ------------------------------
SESSION  = aspace_login
aspace_O = ASpace.new
rep_O = Repository.new( aspace_O, 2 )
res_O = Resource.new( rep_O, RESOURCE_ID )
resource = fetch_resource()
collection_id = resource_identifier_string(resource)
res_query_O = AO_Query_of_Resource.new( res_O, true )
tc_query_O = TC_Query_of_Resource.new( res_query_O )
rows = []
res_query_O.record_H_A.each do | ao |
    rows << build_row_from_ao(ao, collection_id, tc_query_O)
end

CSV.open(OUTPUT_CSV, "w", write_headers: true, headers: HARVARD_HEADERS) do |csv|
  rows.each { |row| csv << HARVARD_HEADERS.map { |h| row[h] } }
end

puts "Export complete: #{OUTPUT_CSV} (#{rows.size} rows)"
