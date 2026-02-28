=begin

    Change this program.
    
=end

require 'json'
require 'optparse'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'



BEGIN {
    INMAGIC_LOC      = :INMAGIC_LOC
    INMAGIC_LOC_A    = :INMAGIC_LOC_A
    MATCHED_AO_H     = :MATCHED_AO_H
    MATCHED_AO_H_A   = :MATCHED_AO_H_A
    MATCHED_TEXT_H_A = :MATCHED_TEXT_H_A
    MATCHED_URI      = :MATCHED_URI
    MATCHED_TITLE    = :MATCHED_TITLE
    MATCHED_LEVEL    = :MATCHED_LEVEL
       }
END {}

myself_name = File.basename( $0 )

cmdln_option = { :rep_num => 2  ,
                 :res_num => nil  ,
                 :update => false ,
                }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do |opt_arg|
        cmdln_option[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )." ) do |opt_arg|
        cmdln_option[ :res_num ] = opt_arg
    end
    option.on( "--update", "Do updates." ) do |opt_arg|
        cmdln_option[ :update ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#SE.q { 'cmdln_option' }

if ( cmdln_option[ :rep_num ] ) then
    rep_num = cmdln_option[ :rep_num ]
else
    SE.puts "The --rep-num option is required."
    raise
end
if ( cmdln_option[ :res_num ] ) then
    res_num = cmdln_option[ :res_num ]
else
    SE.puts "The --res-num option is required."
    raise
end

def scan_for_inmagic_loc_A( record_H )
    location_regex = /(?<= |\p{P}|^)[A-Z]+\d+[.]\d+[.][A-Z]+\d+(?= |\p{P}|$)/
#
#   NOTE:   Putting additional (seamingly harmless) groups into the above expression
#           will change the resulting array!  For example:
#                   /(?<= |\p{P}|^)([GHI]\d+[.]\d+[.][A-Z]\d+)(?= |\p{P}|$)/
#                                  ( --- the extra group --- )
#                   returns an extra level in the array.
#           - OR -
#                   /(?<=( |\p{P}|^))[GHI]\d+[.]\d+[.][A-Z]\d+(?=( |\p{P}|$))/
#                        (extra grp )                            (extra grp )
#                   would also cause an extra level.
#
#           So, be careful!

#   location_regex = /I2.208.O1/

    ao_inmagic_loc_H = { INMAGIC_LOC  => '', 
                         MATCHED_AO_H => { MATCHED_TEXT_H_A => [ ],  
                                           MATCHED_URI => nil,
                                           MATCHED_TITLE => nil,
                                           MATCHED_LEVEL => nil,
                                           }                         
                        }
    
    inmagic_loc_A = [ ]
    record_H.deep_yield { | y | y.to_composite_key_h }.each_pair do | flattened_key_A, v |
        next if ( v.is_not_a?( String ) )
        arr = v.scan( location_regex )
        next if ( arr.empty? )
        ao_inmagic_loc_H[ MATCHED_AO_H ][ MATCHED_TEXT_H_A ] << { flattened_key_A => v } 
        inmagic_loc_A.concat( arr )
    end
    if ( inmagic_loc_A.not_empty? ) then
        inmagic_loc_A.sort!
        inmagic_loc_A.uniq!
        if ( inmagic_loc_A.length > 1 ) then
            SE.puts "#{SE.lineno}: =============================="
            SE.puts 'More than one location found for a record!'
            SE.q {'inmagic_loc_A'}
            SE.q {'ao_inmagic_loc_H'}
            SE.q {'record_H'}
            SE.puts "Can't continue..."
            exit
        end
        ao_inmagic_loc_H[ INMAGIC_LOC ]                    = inmagic_loc_A.first
        ao_inmagic_loc_H[ MATCHED_AO_H ][ MATCHED_URI ]    = record_H[ K.uri ]
        ao_inmagic_loc_H[ MATCHED_AO_H ][ MATCHED_TITLE ]  = record_H[ K.title ]
        ao_inmagic_loc_H[ MATCHED_AO_H ][ MATCHED_LEVEL ]  = record_H[ K.level ]
    end
    return ao_inmagic_loc_H
end

aspace_O = ASpace.new
rep_O = Repository.new( aspace_O, rep_num )
res_O = Resource.new( rep_O, res_num )

cnt = 0

ao_uri_xref_inmagic_loc_A_H = {}
resource_H = res_O.new_buffer.read( ).record_H
ao_inmagic_loc_H = scan_for_inmagic_loc_A( resource_H )
if ( ao_inmagic_loc_H[ INMAGIC_LOC ].not_blank? ) then
    ao_uri_xref_inmagic_loc_A_H[ resource_H[ K.uri ] ] = ao_inmagic_loc_H
    cnt += 1
#   SE.q { 'ao_inmagic_loc_H' } if ( ao_inmagic_loc_H[ INMAGIC_LOC ].not_empty? )
end

ao_query_O = AO_Query_of_Resource.new( res_O: res_O, get_full_ao_record_TF: true )
ao_query_O.record_H_A.each do | record_H |
    ao_inmagic_loc_H = scan_for_inmagic_loc_A( record_H )
    if ( ao_inmagic_loc_H[ INMAGIC_LOC ].not_blank? ) then
        ao_uri_xref_inmagic_loc_A_H[ record_H[ K.uri ] ] = ao_inmagic_loc_H
        cnt += 1
    end
#   SE.q { 'ao_inmagic_loc_H' } if ( ao_inmagic_loc_H[ INMAGIC_LOC ].not_empty? )
end
#SE.q {'ao_uri_xref_inmagic_loc_A_H'}
SE.puts "#{cnt} records."

tc_uri_xref_inmagic_loc_H = Hash.new { | h, k | h[ k ] = { INMAGIC_LOC_A => [ ],
                                                           MATCHED_AO_H_A => [ ],
                                                          } 
                                      } # Auto create 
ao_query_O.record_H_A.each do | record_H |
    instance_A = record_H.dig( K.instances )
    next if instance_A.nil?
    instance_A.each do | instance |       
        tc_uri = instance.dig( K.sub_container, K.top_container, K.ref )
        raise if tc_uri.nil?
       #SE.q {'record_H[ K.uri ]'}
        hierarchy_uri_A = [ record_H[ K.uri ] ]
        record_H[ K.ancestors ].each do | ancestor | 
            ref = ancestor[ K.ref ]
            hierarchy_uri_A.push( ref )
        end

        hierarchy_uri_A.each do | hierarchy_uri |
            next  if ( ao_uri_xref_inmagic_loc_A_H.has_no_key?( hierarchy_uri ) )
         
            break if ( tc_uri_xref_inmagic_loc_H[ tc_uri ].not_empty? &&
                       ao_uri_xref_inmagic_loc_A_H.dig( hierarchy_uri, MATCHED_AO_H,  MATCHED_LEVEL )
                                                  .in?( K.collection, K.recordgrp ) )    
                   
            if ( ao_uri_xref_inmagic_loc_A_H.dig( hierarchy_uri, INMAGIC_LOC )
                                            .not_in?( tc_uri_xref_inmagic_loc_H.dig( tc_uri, INMAGIC_LOC_A ) ) ) then
                tc_uri_xref_inmagic_loc_H[ tc_uri ][ INMAGIC_LOC_A ] << ao_uri_xref_inmagic_loc_A_H.dig( hierarchy_uri, INMAGIC_LOC )
            end
            tc_uri_xref_inmagic_loc_H[ tc_uri ][ MATCHED_AO_H_A ] << ao_uri_xref_inmagic_loc_A_H.dig( hierarchy_uri, MATCHED_AO_H )

        end
    end
end
#SE.q {'tc_uri_xref_inmagic_loc_H'}
tc_uri_xref_inmagic_loc_H.each_key do | tc_uri |
    if tc_uri_xref_inmagic_loc_H[ tc_uri ][ INMAGIC_LOC_A ].length > 1 then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "Warning: More than 1 location:"
        SE.q {'tc_uri'}
        SE.q {'tc_uri_xref_inmagic_loc_H[ tc_uri ]'}
    end           
end

=begin
           I2.200.G11           search: "smcc, i bay, 2 [range: 200, column: g, shelf: 11]"
           I2.200.I10           search: "smcc, i bay, 2 [range: 200, column: i, shelf: 10]"
=end

tc_uri_xref_inmagic_loc_H.each_key do | tc_uri |
    tc_O = Top_Container.new( rep_O, tc_uri ).new_buffer.read
    SE.q { ['tc_uri', 'tc_O']}
    exit
end
