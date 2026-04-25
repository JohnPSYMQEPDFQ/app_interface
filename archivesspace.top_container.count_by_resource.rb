

require 'optparse'
require 'class.Archivesspace.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.ArchivalObject.rb'

BEGIN {}
END {}

binding.pry if ( respond_to? :pry )
myself_name = File.basename( $0 )

cmdln_option_H = { :rep_num => 2,
                   :res_num => nil,
                  }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( default is all resources )." ) do | opt_arg |
        cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option_H
#p ARGV
if ( ! cmdln_option_H[ :rep_num ] ) then
    SE.puts "The --rep-num option is required."
    raise
end

LOCATION_CNT_TYPE_A = %W[ TOTAL_TOP_CONTAINERS WITHOUT_ASSIGNED_LOCATIONS WITH_ASSIGNED_LOCATIONS TOTAL_ASSIGNED_LOCATIONS MANUALLY_ASSIGNED_LOCATIONS
                          ALA_ASSIGNED_LOCATIONS ALA_NO_LOCATIONS ALA_INVALID_LOCATIONS ALA_DUPLICATE_LOCATIONS ALA_SMCC_LOCATIONS ]
LOCATION_CNT_TYPE_A.each do | location_cnt_type | 
    Object.const_set( location_cnt_type, location_cnt_type ) 
end
    
aspace_O = ASpace.new
rep_O = Repository.new( aspace_O, cmdln_option_H[ :rep_num ] )

SE.puts "Finding Top_Containers (which takes some time) ..."
time_begin = Time.now
if ( cmdln_option_H[ :res_num ].nil? ) then
    SE.puts "Getting TC's ..."
    tc_record_H_A = rep_O.query( TOP_CONTAINERS ).record_H_A__all.result_A
else
    res_O         = Resource.new( rep_O, cmdln_option_H.fetch( :res_num ) )
    SE.puts "Getting AO's ..."
    ao_query_O    = AO_Query_of_Resource.new( resource_O: res_O, get_full_ao_record_TF: true )
    SE.puts "Getting TC's ..."
    tc_query_O    = TC_Query_of_Resource.new( ao_query_O )
    tc_record_H_A = tc_query_O.record_H_A
end
elapsed_seconds = Time.now - time_begin
SE.puts "Elapsed seconds = #{elapsed_seconds}"

SE.puts "#{tc_record_H_A.length} Top Containers."

collection_H__by_collection_num = {}
tc_location_cnt_H__by_collection_num = {}
tc_record_H_A.each_with_index do | tc_record_H, idx |
    if ( tc_record_H.fetch( K.collection ).empty? ) then
        next
    end  
   #SE.q {'tc_record_H.fetch( K.collection )'} if idx == 1
    collection_A = tc_record_H.fetch( K.collection )
    type         = tc_record_H.fetch( K.type, '' )
    indicator    = tc_record_H.fetch( K.indicator, '' ) 
    tc_uri       = tc_record_H.fetch( K.uri )
    if ( type.blank? ) then
        SE.print "Warning: type=`#{type}`, indicator=`#{indicator}`, uri=`#{tc_uri.trailing_digits}`, "
        SE.puts  "blank type or indicator."
#       SE.q {'tc_record_H.fetch( K.collection )'}
    end
    if ( collection_A.length > 1 ) then
        SE.puts "Warning: type=`#{type}`, indicator=`#{indicator}`, uri=`#{tc_uri.trailing_digits}`, "
        SE.puts "is part of #{collection_A.length} collections."
        SE.q {'collection_A'}
    end
    tc_record_H[ K.collection ].each do | collection_H |
        raise 'if ( collection_H.empty? )' if ( collection_H.empty? )  
        collection_num = collection_H.fetch( K.ref ).trailing_digits.to_i
        collection_H__by_collection_num[ collection_num ] ||= collection_H
        tc_location_cnt_H__by_collection_num[ collection_num ] ||= Hash.new { | hash, key | hash[ key ] = 0 }
        tc_location_cnt_H__by_collection_num[ collection_num ][ TOTAL_TOP_CONTAINERS ] += 1
        container_loc_A = tc_record_H.fetch( K.container_locations )
        if ( container_loc_A.empty? ) then
            tc_location_cnt_H__by_collection_num[ collection_num ][ WITHOUT_ASSIGNED_LOCATIONS ] += 1
            next
        end
        tc_location_cnt_H__by_collection_num[ collection_num ].tap do | tc_location_cnt_H |
            tc_location_cnt_H[ WITH_ASSIGNED_LOCATIONS ]  += 1 
            tc_location_cnt_H[ TOTAL_ASSIGNED_LOCATIONS ] += container_loc_A.length
            
            cnt = container_loc_A.count { | cl | cl[ K.note ].to_s.not_match?( /^#{ALA_NOTE_MARKER}/i ) }
            tc_location_cnt_H[ MANUALLY_ASSIGNED_LOCATIONS ] += cnt
            
            cnt = container_loc_A.count { | cl | cl[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER}/i ) }
            tc_location_cnt_H[ ALA_ASSIGNED_LOCATIONS ] += cnt
            
            cnt = container_loc_A.count { | cl | cl[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER} #{NO_LOCATION}/i ) } 
            tc_location_cnt_H[ ALA_NO_LOCATIONS ] += cnt
            if ( cnt > 1 ) then
                SE.puts "#{SE.lineno}: Warning: #{type} #{indicator} `#{tc_uri.trailing_digits}` has more than one NO_LOCATION"
            end
            
            cnt = container_loc_A.count { | cl | cl[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER} #{INVALID_LOCATION}/i ) } 
            tc_location_cnt_H[ ALA_INVALID_LOCATIONS ] += cnt
            if ( cnt > 1 ) then
                SE.puts "#{SE.lineno}: Warning: #{type} #{indicator} `#{tc_uri.trailing_digits}` has more than one INVALID_LOCATION"
            end
            
            cnt = container_loc_A.count { | cl | cl[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER} #{DUPLICATE_LOCATIONS}/i ) } 
            tc_location_cnt_H[ ALA_DUPLICATE_LOCATIONS ] += cnt
            if ( cnt > 1 ) then
                SE.puts "#{SE.lineno}: Warning: #{type} #{indicator} `#{tc_uri.trailing_digits}` has more than one DUPLICATE_LOCATIONS"
            end
            
            cnt = container_loc_A.count { | cl | cl[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER} #{K.smcc_loc_id_RES}/i ) } 
            tc_location_cnt_H[ ALA_SMCC_LOCATIONS ] += cnt    
            
            if ( tc_location_cnt_H[ TOTAL_ASSIGNED_LOCATIONS ] != tc_location_cnt_H[ MANUALLY_ASSIGNED_LOCATIONS ] + 
                                                                  tc_location_cnt_H[ ALA_ASSIGNED_LOCATIONS ] ) then
                SE.puts "#{SE.lineno} Bad counts."
                SE.puts 'tc_location_cnt_H[ TOTAL_ASSIGNED_LOCATIONS ] != tc_location_cnt_H[ MANUALLY_ASSIGNED_LOCATIONS ] + tc_location_cnt_H[ ALA_ASSIGNED_LOCATIONS ]'
                SE.q {'tc_location_cnt_H__by_collection_num[ collection_num ]'}
                SE.q {'tc_record_H'}
                raise
            end
            if ( tc_location_cnt_H[ ALA_ASSIGNED_LOCATIONS ] != tc_location_cnt_H[ ALA_NO_LOCATIONS ] + tc_location_cnt_H[ ALA_INVALID_LOCATIONS ] + 
                                                                tc_location_cnt_H[ ALA_DUPLICATE_LOCATIONS ] + tc_location_cnt_H[ ALA_SMCC_LOCATIONS ] ) then
                SE.puts "#{SE.lineno} Bad counts."
                SE.puts 'tc_location_cnt_H[ ALA_ASSIGNED_LOCATIONS ] != tc_location_cnt_H[ ALA_NO_LOCATIONS ] + tc_location_cnt_H[ ALA_INVALID_LOCATIONS ] +'
                SE.puts '                                               tc_location_cnt_H[ ALA_DUPLICATE_LOCATIONS ] + tc_location_cnt_H[ ALA_SMCC_LOCATIONS ]'
                SE.q {'tc_location_cnt_H__by_collection_num[ collection_num ]'}
                SE.q {'tc_record_H'}
                raise
            end
        end
    end 
end
print '"NUM","ID","Name",'
print '"', LOCATION_CNT_TYPE_A.map { | str | str.tr('_', ' ') }.join( '","' ), '"'
puts ''
tc_location_cnt_H__by_collection_num.each_pair
                                    .sort_by { | collection_num, tc_location_cnt_H | 0 - tc_location_cnt_H[ TOTAL_TOP_CONTAINERS ] }
                                    .to_h.each_pair do | collection_num, tc_location_cnt_H |
    print %Q`#{collection_num},`
    print %Q`"#{collection_H__by_collection_num.fetch( collection_num ).fetch( K.identifier )}",`
    print %Q`"#{collection_H__by_collection_num.fetch( collection_num ).fetch( K.display_string )[ 0, 40 ]}",`
    print LOCATION_CNT_TYPE_A.map { | type | tc_location_cnt_H[ type ] }.join( ',' )
    puts ''
end






