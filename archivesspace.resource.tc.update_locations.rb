require 'optparse'
require 'stringio'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.Location.rb'

module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :cmdln_option_H, :location_classification,
                      :res_buf_O
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...


def get_location_title( loc_id )

    if ( loc_id.in?( NO_LOCATION, INVALID_LOCATION, DUPLICATE_LOCATIONS ) )
        stringer = "#{ALA_PROBLEMS} [#{self.location_classification}, #{ERROR_LABEL}: #{loc_id}]"
        return stringer
    end

    xyz_letter_A = []
    xyz_number_A = []
    xyz_A = loc_id.split( '.' )
    xyz_A.compact!
    if ( xyz_A.length != 3 ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "xyz_A not length 3"
        SE.q {'loc_id'}
        SE.q {'xyz_A'}
        raise
    end
    
    xyz_A.each_with_index do | xyz, idx |
        if idx == 1 then
            xyz_number_A << xyz.to_i
            xyz_letter_A << K.undefined   
        else
            xyz_number_A << xyz.trailing_digits.to_i
            xyz_letter_A << xyz.first( 1 )      
        end
    end
    
    xyz_number_A.compact!
    if ( xyz_number_A.length != 3 ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "xyz_number_A not length 3"
        SE.q {'loc_id'}
        SE.q {'xyz_A'}
        SE.q {'xyz_number_A'}
        raise
    end
    xyz_letter_A.compact!
    if ( xyz_letter_A.length != 3 ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "xyz_letter_A not length 3"
        SE.q {'loc_id'}
        SE.q {'xyz_A'}
        SE.q {'xyz_letter_A'}
        raise
    end
    
    stringer = "smcc, #{xyz_letter_A[ 0 ]} bay, area #{xyz_number_A[ 0 ]} " +
               "[range: #{xyz_A[ 1 ]}, column: #{xyz_letter_A[ 2 ]}, shelf: #{xyz_number_A[ 2 ]}]"
    return stringer
end

def capture_stdout
    # Store original $stdout
    original_stdout = $stdout
    # Create a new StringIO object
    $stdout = StringIO.new
    begin
        # Execute the code block
        yield           ##  !!!!  A break in the yielded-to-code will result in the captured string being nil!!!!!
        # Return the captured string
        $stdout.string
    ensure
        # Restore original $stdout, even if an exception occurred
        $stdout = original_stdout
    end
end


def print__aoz_having_locations( ao_loc_n_source_H_H )
    captured_stringer = capture_stdout do
        puts ''
        puts "AO's having locations:"
        ao_loc_n_source_H_H.each_pair do | _, ao_loc_n_source_H |
            puts "#{ao_loc_n_source_H.fetch( K.level )}: #{ao_loc_n_source_H.fetch( K.title )[ 0,60 ]} " +
                 "'#{ao_loc_n_source_H.fetch( K.uri ).trailing_digits}' " +
                 ''                   
            puts "        Text: #{ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( ORIG_LOC_TEXT_H ).fetch( ORIG_LOC_TEXT_VALUE )}"
            ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_ID_n_RANGE_H_A ).each do | loc_id_n_range_H | 
                print "    Location: #{loc_id_n_range_H.fetch( LOC_ID )} "
                loc_id_n_range_H.fetch( LOC_RANGE_H_A ).each do | loc_range_H |
                    print "#{loc_range_H} "
                end
                puts ' '
            end
            puts ''
            puts ''
        end
        puts ''
    end
    puts captured_stringer
    return captured_stringer
end

def print__aoz_with_unused_locations( ao_loc_n_source_H_H, ao_source_uri_A )
    unused_ao_location_A = ao_loc_n_source_H_H.keys - ao_source_uri_A
    if ( unused_ao_location_A.empty? ) then
        return ''
    end

    captured_stringer = capture_stdout do
        puts ''
        puts "AO's having locations that were never used:"
        unused_ao_location_A = ao_loc_n_source_H_H.keys - ao_source_uri_A
        unused_ao_location_A.each do | unused_uri |
            ao_loc_n_source_H = ao_loc_n_source_H_H.fetch( unused_uri )
            puts "#{ao_loc_n_source_H.fetch( K.level )}: #{ao_loc_n_source_H.fetch( K.title )[ 0,60 ]} " +
                 "'#{ao_loc_n_source_H.fetch( K.uri ).trailing_digits}' " +
                 ''             
            puts "        Text: #{ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( ORIG_LOC_TEXT_H ).fetch( ORIG_LOC_TEXT_VALUE )}"
            ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_ID_n_RANGE_H_A ).each do | loc_id_n_range_H | 
                print "    Location: #{loc_id_n_range_H.fetch( LOC_ID )} "
                loc_id_n_range_H.fetch( LOC_RANGE_H_A ).each do | loc_range_H |
                    print "#{loc_range_H} "
                end
                puts ''
            end
            puts ''
        end
        puts ''
    end
    puts captured_stringer
    return captured_stringer
end

def print__tcz_locations( tc_data_H_H, tc_query_O, ao_loc_n_source_H_H, ao_query_O )    
    puts ''
    puts "TC's assigned locations:"
    tc_data_H_H.each_pair do | tc_uri, tc_data_H |
        print "#{tc_data_H.fetch( K.type )}-#{tc_data_H.fetch( K.indicator )} '#{tc_uri.trailing_digits}' "
        if tc_data_H_H.fetch( tc_uri ).fetch( AO_LOC_n_SOURCE_H_A ).length > 1 then
            print "<<<<< WARNING: TC has more than 1 location!"
        end
        puts ''

        ao_source_note_A = [ ]    
        tc_data_H.fetch( AO_LOC_n_SOURCE_H_A ).each do | ao_loc_n_source_H |            
            loc_data_H = ao_loc_n_source_H.fetch( LOC_DATA_H )
            loc_id = loc_data_H.fetch( LOC_ID )
            puts "    Location: #{loc_id} '#{get_location_title( loc_id )}'"
            if ( loc_data_H.has_key?( LOC_NOTE ) ) then
                loc_note = loc_data_H.fetch( LOC_NOTE )
                if ( loc_note.not_blank? ) then
                    puts "    Note: #{loc_note}"
                end
            end
            ao_loc_n_source_H[ AO_SOURCE_H_A_H ].each_pair do | ao_loc_source_uri, ao_list_H_A |            
                if ( ao_list_H_A.length == 1 and ao_list_H_A.first.fetch( K.uri ) == ao_loc_source_uri ) then
                    stringer = "   Self Source:"
                    ao_detail = false
                else
                    stringer = "        Source:"
                    ao_detail = true
                end
                if ( loc_id.in?( NO_LOCATION, INVALID_LOCATION ) ) then
                    ao_detail = true
                else
                    if ( ao_loc_source_uri == self.res_buf_O.record_H.fetch( K.uri ) ) then
                        ao_record_H = self.res_buf_O.record_H
                    else
                        ao_record_H = ao_query_O.record_H__of_uri( ao_loc_source_uri )
                    end
                    text = "#{stringer} '#{ao_loc_source_uri.trailing_digits}'" +
                           ' ' + "#{ao_record_H.fetch( K.level )}: #{ao_record_H.fetch( K.title )[ 0,60 ]}" 
                    puts text
                    if ( ao_source_note_A.include?( text.lstrip ) ) then
                        SE.q {'ao_loc_source_uri'}
                        SE.q {'ao_record_H[ K.uri ]'}
                        SE.q {'text.lstrip'}
                        SE.q {'ao_source_note_A'}
                        SE.q {'ao_loc_n_source_H[ AO_SOURCE_H_A_H ].keys'}
                        raise
                    end
                    ao_source_note_A << text.lstrip
                end
                next if ao_detail == false
                puts "        AO Refs: "
                ao_list_H_A.each do | ao_list_H |
                    ao_uri = ao_list_H.fetch( K.uri ) 
                    ao_record_H = ao_query_O.record_H__of_uri( ao_uri )
                    puts "            '#{ao_uri.trailing_digits}/#{ao_list_H.fetch( K.instance )}'" +
                         ' ' + "#{ao_record_H.fetch( K.level )}: #{ao_record_H.fetch( K.title )[ 0,60 ]}" 
                         ' '      
                end
            end
            tc_data_H[ AO_SOURCE_NOTE ] = ao_source_note_A.join( '; ' )
            puts ' '
            puts ''     
        end   
    end

    tc_missing_A = tc_query_O.record_H_A.map{ | record_H | record_H.fetch( K.uri ) } - tc_data_H_H.keys
    if ( tc_missing_A.empty? ) then
        SE.puts "All TC's have locations."
        return
    end
    
    SE.puts "#{tc_missing_A.length} TC's don't have locations."
    raise
end

def get_loc_from_ao( record_H )
    loc_RE   = /(?<preceding_text>^.*?)(?<loc_id>(?<xyz_1>[A-Z]+\d+)[.](?<xyz_2>\d+)[.](?<xyz_3>[A-Z]+\d+))(?<trailing_text>.*$)/
    noise_RE = /^\s*((SMCC|Statewide\s+Museum\s+Collections?\s+Center)[,;:]?\s*)+\s*/i
    ao_loc_n_source_H = {}                   
    loc_data_source_H_A = []     # There should only be ONE!   
    record_H.to_composite_key_h.each_pair do | composite_key_A, orig_loc_text_value |
        loc_data_source_H = {}
        next if ( orig_loc_text_value.is_not_a?( String ) )
        composite_key_A.freeze
        orig_loc_text_value_WO_CRLF = orig_loc_text_value.gsub(/([\r]*[\n])+/, " | ")
        orig_loc_text_value_WO_CRLF.freeze                # for coding safety
        location_FOOD = orig_loc_text_value_WO_CRLF.dup   # '_FOOD' meaning: a string to search/replace consume until empty    
        location_FOOD.gsub!( /[\[\]]/, ' ')
        ld = SE::Loop_detector.new
        loop do   
            location_FOOD.gsub!( /#{ALA_NOTE_MARKER}.*?;\s*\|/, '' )
            location_FOOD.sub!( /^\<physloc\>: /, '' )
            location_FOOD.sub!( noise_RE, '' )  
            location_FOOD.sub!( loc_RE, '' )
            loc_MO = $~ 
            if loc_MO.nil? 
                break 
            end            
            ld.loop( loc_MO )    
            if loc_data_source_H.empty? then
               loc_data_source_H[ LOC_ID_n_RANGE_H_A ] = [ ]
               loc_data_source_H[ ORIG_LOC_TEXT_H ]  = { ORIG_LOC_TEXT_KEY_CKA   => composite_key_A.freeze,
                                                         ORIG_LOC_TEXT_VALUE => orig_loc_text_value_WO_CRLF.dup }
            end
            
            case true
            when ( loc_MO[ :preceding_text ].not_blank? )    # .blank does a .to_s which converts nil to ''
                container_FOOD = loc_MO[ :preceding_text ]
                location_FOOD  = loc_MO[ :trailing_text ].to_s.sub(/\A(\s*[[:punct:]])+/, '').strip
            when ( loc_MO[ :trailing_text ].not_blank? ) 
                stringer = loc_MO[ :trailing_text ].to_s.sub(/\A(\s*[[:punct:]])+/, '').strip
                stringer.sub!( loc_RE, '' )
                next_loc_MO = $~
                if next_loc_MO.nil? 
                    container_FOOD = stringer
                    location_FOOD  = ''.dup
                else
                    container_FOOD = next_loc_MO[ :preceding_text ]
                    location_FOOD  = next_loc_MO[ :loc_id ] + next_loc_MO[ :trailing_text ]
                end   
                container_FOOD.sub!( noise_RE, '' )                
            else
                                          # No data on either side of the location.
                container_FOOD = ''.dup
                location_FOOD  = ''.dup
            end
           #SE.q {'loc_MO.named_captures'}
           #SE.q {['location_FOOD','container_FOOD']}
            
            loc_id_n_range_H = {}
            loc_id_n_range_H[ LOC_ID ]        = loc_MO[ :loc_id ] 
            loc_id_n_range_H[ LOC_RANGE_H_A ] = [ ]     
            loop do 
               #SE.q {'container_FOOD'}
                container_FOOD.sub!( K.container_and_child_types_RE, '' )
                container_MO = $~
                if container_MO.nil? then # No container found
                    break
                end     
               #SE.q {'container_MO.named_captures'}  
               #SE.q {['location_FOOD','container_FOOD']}       
                
                if ( container_MO[ :container_type_modifier ].not_nil? || 
                     container_MO[ :child_type ].not_nil? || 
                     container_MO[ :grandchild_type ].not_nil? ) then
                    SE.puts "#{SE.lineno} I got some container stuff I'm not equipped to deal with."
                    SE.q {'container_MO[ :container_type_modifier ].not_nil?'}
                    SE.q {'container_MO[ :child_type ].not_nil?'}
                    SE.q {'container_MO[ :grandchild_type ].not_nil?'}
                    SE.q {'container_MO'}
                    SE.q {'record_H.fetch( K.title )'}
                    SE.q {"composite_key_A.join( ',' )"}
                    SE.q {'orig_loc_text_value_WO_CRLF'}
                    SE.q {'container_FOOD'}
                    raise
                end
                arr = container_MO[ :container_num ].split( '-' ).map( &:to_i )
                case arr.length
                when 1
                    range = Range.new( arr.first, arr.first )
                when 2
                    range = Range.new( *arr )
                else
                    SE.puts "#{SE.lineno} I got a bad container range."
                    SE.q {'container_MO'}
                    SE.q {'record_H.fetch( K.title )'}
                    SE.q {"composite_key_A.join( ',' )"}
                    SE.q {"composite_key_A.join( ',' )"}
                    SE.q {'orig_loc_text_value_WO_CRLF'}
                    SE.q {'container_MO[ :container_num ]'}
                    SE.q {'arr'}
                    raise
                end
                
                loc_id_n_range_H[ LOC_RANGE_H_A ] << { container_MO[ :container_type ].downcase.sub( /(es|s)$/,'' ) => range }   
               #SE.q {'loc_id_n_range_H'}
            end

            if ( loc_data_source_H.fetch( LOC_ID_n_RANGE_H_A ).none? { | hash | 
                hash[ LOC_ID ]       == loc_id_n_range_H.fetch( LOC_ID ) &&
                hash[ LOC_RANGE_H_A] == loc_id_n_range_H.fetch( LOC_RANGE_H_A ) 
                                                                   } 
                ) then
                loc_data_source_H[ LOC_ID_n_RANGE_H_A ] << loc_id_n_range_H
            end     
            
            container_FOOD.sub!(/\A(\s*[[:punct:]])+/, '')
            container_FOOD.sub!( noise_RE, '' ) 
            if container_FOOD.not_blank? then                       
                SE.puts "#{SE.lineno} I've got unknown data in 'container_FOOD'"
                SE.q {'record_H.fetch( K.title )'}
                SE.q {"composite_key_A.join( ',' )"}
                SE.q {'orig_loc_text_value_WO_CRLF'}
                SE.q {'container_FOOD'}
                SE.q {'location_FOOD'}
                SE.q {'loc_data_source_H'}
                raise  
            end
        end
        next if loc_data_source_H.empty?    
        
        if location_FOOD.not_blank? then
            SE.puts "#{SE.lineno} I've got unknown data in 'location_FOOD'"
            SE.q {'record_H.fetch( K.title )'}
            SE.q {"composite_key_A.join( ',' )"}
            SE.q {'orig_loc_text_value_WO_CRLF'}
            SE.q {'location_FOOD'}
            SE.q {'loc_data_source_H'}
            raise 
        end

        loc_data_source_H_A << loc_data_source_H 

    end

    if ( loc_data_source_H_A.empty? ) then
        return {}
    end
    if ( loc_data_source_H_A.length > 1 ) then
        puts "#{SE.lineno}: =============================="
        puts 'More than one location source found for record:'
        puts "#{record_H.fetch( K.level )}: #{record_H.fetch( K.title )} " +
             "'#{record_H.fetch( K.uri ).trailing_digits}' " +
             ''    
       #SE.q {'loc_data_source_H_A'}
       #SE.q {'ao_loc_n_source_H'}
       #SE.q {'record_H'}
        puts 'Record skipped.'
        puts ''
        return {}
    end
    
    loc_data_source_H = loc_data_source_H_A.first
    cnt = loc_data_source_H.fetch( LOC_ID_n_RANGE_H_A ).count { |arr| arr[ LOC_RANGE_H_A ].empty? }
    if cnt > 1 then
        puts 'More than one location without a range found for record:'
        puts "#{record_H.fetch( K.level )}: #{record_H.fetch( K.title )} " +
             "'#{record_H.fetch( K.uri ).trailing_digits}' " +
             ''
        arr = loc_data_source_H.fetch( LOC_ID_n_RANGE_H_A ).map { | hash | hash[ LOC_ID ] }
        puts "Locations: #{arr.join( ', ')}" +
             ''    
       #SE.q {'loc_data_source_H'}
       #SE.q {'ao_loc_n_source_H'}
       #SE.q {'record_H'}
        puts 'Record skipped.'
        puts ''
        return {}
    end    
    
    loc_data_source_H.fetch( LOC_ID_n_RANGE_H_A ).sort_by! do | hash |
        empty_sort_key = hash.fetch( "LOC_RANGE_H_A" ).empty? ? 1 : 0 # empty last
       length_sort_key = hash.fetch( "LOC_RANGE_H_A" ).length         # but non_empty small to big
       [ empty_sort_key, length_sort_key ]
    end
 
    ao_loc_n_source_H[ LOC_DATA_H ] = loc_data_source_H
    ao_loc_n_source_H[ K.title ]    = record_H.fetch( K.title )
    ao_loc_n_source_H[ K.level ]    = record_H.fetch( K.level )
    ao_loc_n_source_H[ K.uri ]      = record_H.fetch( K.uri )   
        
    return ao_loc_n_source_H
end

# puts "#{$stderr.class}"
# puts "#{$stdout.class}"
BEGIN {    

    AO_LOC_n_SOURCE_H_A        = 'AO_LOC_n_SOURCE_H_A'
    AO_SOURCE_H_A_H            = 'AO_SOURCE_H_A_H'
    AO_SOURCE_NOTE             = 'AO_SOURCE_NOTE'
    LOC_DATA_H                 = 'LOC_DATA_H'
    LOC_ID                     = 'LOC_ID'
    LOC_ID_n_RANGE_H_A         = 'LOC_ID_n_RANGE_H_A'
    LOC_NOTE                   = 'LOC_NOTE'
    LOC_RANGE_H                = 'LOC_RANGE_H'
    LOC_RANGE_H_A              = 'LOC_RANGE_H_A'
    ORIG_LOC_TEXT_H            = 'ORIG_LOC_TEXT_H'    
    ORIG_LOC_TEXT_KEY_CKA      = 'ORIG_LOC_TEXT_KEY_CKA'                    # CKA = Composite Key Array
    ORIG_LOC_TEXT_VALUE        = 'ORIG_LOC_TEXT_VALUE'
    CREATE_ALA_LOCATION        = 'CREATE_ALA_LOCATION'
    
    ALA_NOTE_MARKER            = '_ALA_'
    ALA_PROBLEMS               = '_ALA_PROBLEMS_'                            # Value for 'building'      
    ALA_START_DATE             = '19810502'
    ERROR_LABEL                = 'ERROR'                                     # Value for 'coordinate_1_label'
    NO_LOCATION                = 'NO_LOCATION'                               # Value for 'coordinate_1_indicator' 
    INVALID_LOCATION           = 'INVALID_LOCATION'                          # Value for 'coordinate_1_indicator'
    DUPLICATE_LOCATIONS        = 'DUPLICATE_LOCATIONS'                       # Value for 'coordinate_1_indicator'
#   Search string: '_ALA_PROBLEMS_ [_MS_634_, ERROR: NO_LOCATION]'
#   ALA = Automated Location Assignment
   
}
END {}


self.myself_name = File.basename( $0 )

self.cmdln_option_H = { :rep_num           => 2,
                        :res_num           => nil,
                        :res_title         => nil,
                        :rm_ala_locations  => false,
                        :update            => false,
                        :do_only_n         => nil,
                     }
OptionParser.new do | option |
    option.banner = "Usage: #{self.myself_name} [ options ]"
    option.on( "--location-title x", "ONLY display the AS Location Title using the InMagic Location (x)" ) do | opt_arg |
        puts get_location_title( opt_arg )
        exit
    end
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do | opt_arg |
        self.cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )." ) do | opt_arg |
        self.cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "--res-title x", "Resource Title ( required )" ) do | opt_arg |
        cmdln_option_H[ :res_title ] = opt_arg.strip
    end
    option.on( "--rm_ala_tc_locations", "Remove all the existing _ALA_ TC locations before applying new ones." ) do | opt_arg |
        self.cmdln_option_H[ :rm_ala_locations ] = true
    end
    option.on( "--update", "Do updates." ) do | opt_arg |
        self.cmdln_option_H[ :update ] = true
    end
    option.on( "--do_only n", OptionParser::DecimalInteger, "Stop after n TC's are 'stored', --update needs to set to actually update." ) do | opt_arg |
        self.cmdln_option_H[ :do_only_n ] = opt_arg.to_i
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#SE.q { 'self.cmdln_option_H' }

if ( self.cmdln_option_H.fetch( :rep_num ).nil? ) then
    SE.puts "The --rep-num option is required."
    raise
end
if ( self.cmdln_option_H.fetch( :res_num ).nil? ) then
    SE.puts "The --res-num option is required."
    raise
end
if ( self.cmdln_option_H[ :res_title ].blank? ) then
    SE.puts "The --res-title option is required."
    raise
end

aspace_O = ASpace.new
aspace_O.allow_updates=self.cmdln_option_H.fetch( :update )
rep_O = Repository.new( aspace_O, self.cmdln_option_H.fetch( :rep_num ) )
res_O = Resource.new( rep_O, self.cmdln_option_H.fetch( :res_num ) )

ao_loc_n_source_H_H = {}   # Indexed by K.uri
self.res_buf_O = res_O.new_buffer.read
res_title = res_buf_O.record_H[ K.title ]
if ( cmdln_option_H[ :res_title ].downcase != res_title.downcase[ 0, cmdln_option_H[ :res_title ].length ] ) then
    SE.puts "#{SE.lineno}: The --res-title value must start with the title of --res-num #{cmdln_option_H[ :res_num ]}. They don't:"
    SE.q {[ 'cmdln_option_H[ :res_title ]' ]}
    SE.q {[ 'res_title' ]}
    raise
end
search_text = %Q|title:"#{cmdln_option_H[ :res_title ]}"|
res_search_H_A = rep_O.search( record_type: K.resource, search_text: search_text, result_field_A: [ K.title ] ).result_A
raise "res_search_H_A.empty?" if res_search_H_A.empty?
if ( res_search_H_A.length > 1 ) then
    multiple_titles_A = res_search_H_A.map{ | res_search_H | res_search_H.fetch( K.title ) }
    cnt = multiple_titles_A.count { | title | title == "#{cmdln_option_H[ :res_title ]}" and
                                              title == res_title }
    if ( cnt != 1 ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "Multiple Resource titles found for option: --res_title '#{cmdln_option_H[ :res_title ]}'"
        SE.q {'multiple_titles_A'}
        raise
    end
end
raise "res_search_H_A.empty?" if ( res_search_H_A.empty? )
if ( res_search_H_A.first.fetch( K.title ) != res_title ) then
    SE.puts "#{SE.lineno}: =============================="
    SE.puts "res_search_H_A.first.fetch( K.title ) != res_title"
    SE.q {'res_search_H_A.first.fetch( K.title )'}
    SE.q {'res_title'}
    raise 
end
self.location_classification = "_#{self.res_buf_O.record_H.fetch( K.id_0 ).sub( /inmagic /, '' ).gsub( /\s+/, '_' )}_"
ao_loc_n_source_H = get_loc_from_ao( self.res_buf_O.record_H )
if ( ao_loc_n_source_H.not_empty? ) then
    ao_loc_n_source_H_H[ self.res_buf_O.record_H.fetch( K.uri ) ] = ao_loc_n_source_H
end

ao_query_O = AO_Query_of_Resource.new( resource_O: res_O, get_full_ao_record_TF: true )
ao_query_O.record_H_A.each do | record_H |
    ao_loc_n_source_H = get_loc_from_ao( record_H )
    if ( ao_loc_n_source_H.not_empty? ) then
        ao_loc_n_source_H_H[ record_H.fetch( K.uri ) ] = ao_loc_n_source_H
    end
end

SE.puts "#{ao_loc_n_source_H_H.length} AO's with locations."
if ( ao_loc_n_source_H_H.empty? ) then
    puts "Nothing to do."
    exit
end

print__aoz_having_locations( ao_loc_n_source_H_H )
#SE.q {'ao_loc_n_source_H_H'}

tc_query_O = TC_Query_of_Resource.new( ao_query_O )

tc_data_H_H = {}
ao_loc_data_picked_H_A_H = {}
ao_query_O.record_H_A.each do | ao_record_H |
    instance_H_A = ao_record_H.fetch( K.instances )
    next if instance_H_A.nil? || instance_H_A.empty?        # No top container for ao

    ao_loc_data_picked_H_A_H[ ao_record_H.fetch( K.uri ) ] = 
        Array.new( instance_H_A.length ) { K.undefined }    # Array of instances
        
    ao_hierarchy_uri_A = [ ao_record_H.fetch( K.uri ) ]     # <<< Include current record
    ao_record_H.fetch( K.ancestors ).each do | ancestor | 
        ref = ancestor[ K.ref ]
        ao_hierarchy_uri_A.push( ref )
    end    
      
    instance_H_A.each_with_index do | instance_H, instance_idx |
        tc_uri = instance_H.fetch( K.sub_container ).fetch( K.top_container).fetch( K.ref )
        tc_record_H = tc_query_O.record_H__of_uri( tc_uri )
        raise "tc_record_H.nil?" if tc_record_H.nil?
        
        ao_loc_data_picked_H = { LOC_DATA_H => {} } 
        catch( :done ) do
            ao_hierarchy_uri_A.each do | ao_hierarchy_uri |    
                if ao_loc_n_source_H_H.has_key?( ao_hierarchy_uri ) 
                    ao_loc_n_source_H = ao_loc_n_source_H_H.fetch( ao_hierarchy_uri )
                    ao_loc_data_picked_H[ ORIG_LOC_TEXT_H] = ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( ORIG_LOC_TEXT_H )
                    ao_loc_data_picked_H[ K.uri ]          = ao_hierarchy_uri
                    loc_id_n_range_H_A = ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_ID_n_RANGE_H_A )
                    loc_id_n_range_H_A.each do | loc_id_n_range_H |
                        loc_range_H_A = loc_id_n_range_H.fetch( LOC_RANGE_H_A )
                        if ( loc_range_H_A.empty? ) then
                            range_H_A = nil
                        else
                            range_H_A = loc_range_H_A.select { | range_H | 
                                                                 range_H.has_key?( tc_record_H.fetch( K.type ) ) && 
                                                                 range_H.fetch( tc_record_H.fetch( K.type ) )
                                                                        .include?( tc_record_H.fetch( K.indicator ).to_i ) 
                                                                 }
                        end
                        
                        if ( ao_loc_data_picked_H.fetch( LOC_DATA_H ).empty? ) then
                            case
                            when ( range_H_A.nil? )  
                                ao_loc_data_picked_H[ LOC_DATA_H ][ LOC_ID ]      = loc_id_n_range_H.fetch( LOC_ID )
                                ao_loc_data_picked_H[ LOC_DATA_H ][ LOC_RANGE_H ] = {}                                
                            when ( range_H_A.empty? )
                                next
                            else#( range_H_A.not_empty?)
                                ao_loc_data_picked_H[ LOC_DATA_H ][ LOC_ID ]      = loc_id_n_range_H.fetch( LOC_ID )
                                ao_loc_data_picked_H[ LOC_DATA_H ][ LOC_RANGE_H ] = range_H_A.first  
                            end
                        else
                           #SE.q {'range_H_A'}
                           #SE.q {'ao_loc_data_picked_H'}
                            if (  ao_loc_data_picked_H[ LOC_DATA_H ][ LOC_RANGE_H ].not_empty? &&
                                  ( range_H_A.nil? || range_H_A.empty? ) ) then
                                next    # If we already HAVE a range location, then a non range location can be ignored.
                            end
                            loc_note = ao_loc_data_picked_H.fetch( LOC_DATA_H ).fetch( LOC_NOTE, ''.dup )
                            if ( ao_loc_data_picked_H.fetch( LOC_DATA_H ).has_key?( LOC_ID ) ) then
                                loc_id = ao_loc_data_picked_H.fetch( LOC_DATA_H ).delete( LOC_ID )
                                loc_note << "Duplicate locations: #{loc_id}"
                                if ( ao_loc_data_picked_H.fetch( LOC_DATA_H ).fetch( LOC_RANGE_H ).not_empty? ) then
                                    range = ao_loc_data_picked_H.fetch( LOC_DATA_H ).delete( LOC_RANGE_H )
                                    loc_note << " (#{range})"
                                end
                            end
                            loc_id = loc_id_n_range_H.fetch( LOC_ID )
                            loc_note << "; #{loc_id}"
                            if ( range_H_A.not_nil? && range_H_A.length > 1 ) then
                                loc_note << "(Duplicate range: #{range_H_A})"
                            end
                            ao_loc_data_picked_H[ LOC_DATA_H ] = { LOC_NOTE => loc_note }.cbv
                            puts "#{SE.lineno}: =============================="
                            puts "WARNING: #{loc_note}"
                            puts "        AO URI: #{ao_record_H.fetch( K.uri )}"
                            puts " SOURCE AO URI: #{ao_loc_data_picked_H.fetch( K.uri )}"
                            puts "        TC URI: #{tc_record_H.fetch( K.uri )}, #{tc_record_H.fetch( K.type )}-#{tc_record_H.fetch( K.indicator )}"
                            puts ''
                        end                        
                    end                    
                end
                throw :done if ( ao_loc_data_picked_H.fetch( LOC_DATA_H ).not_empty? )
            end
        end
        case true
        when ao_loc_data_picked_H.fetch( LOC_DATA_H ).empty? 
            ao_loc_data_picked_H[ LOC_DATA_H ]      = { LOC_ID      => NO_LOCATION,
                                                        LOC_RANGE_H => {}, 
                                                       }                                                  
            ao_loc_data_picked_H[ K.uri ]           = NO_LOCATION
            ao_loc_data_picked_H[ ORIG_LOC_TEXT_H ] = ''
        when ao_loc_data_picked_H.fetch( LOC_DATA_H ).has_no_key?( LOC_ID )
            ao_loc_data_picked_H[ LOC_DATA_H ]      = { LOC_ID      => INVALID_LOCATION,
                                                        LOC_RANGE_H => {}, 
                                                       }    
            ao_loc_data_picked_H[ K.uri ]           = INVALID_LOCATION  
            ao_loc_data_picked_H[ ORIG_LOC_TEXT_H ] = ''            
        end

        tc_data_H = tc_data_H_H[ tc_uri ] ||= { K.type              => tc_record_H.fetch( K.type ),
                                                K.indicator         => tc_record_H.fetch( K.indicator ),
                                                AO_LOC_n_SOURCE_H_A => [ ],
                                               }.cbv
        tc__ao_loc_n_source_H = tc_data_H.fetch( AO_LOC_n_SOURCE_H_A ).find { | ao_loc_n_source_H | 
            ao_loc_n_source_H.fetch( LOC_DATA_H ) == ao_loc_data_picked_H.fetch( LOC_DATA_H ) } || begin
                tc_data_H[ AO_LOC_n_SOURCE_H_A ] << { LOC_DATA_H      => ao_loc_data_picked_H.fetch( LOC_DATA_H ),
                                                      AO_SOURCE_H_A_H => {}, 
                                                      ORIG_LOC_TEXT_H => ao_loc_data_picked_H.fetch( ORIG_LOC_TEXT_H )
                                                     }                                                           
                tc_data_H.fetch( AO_LOC_n_SOURCE_H_A ).last    # This is needed because the '<<' OR '.push" returns the entire array                                          
            end
        tc__ao_loc_n_source_H[ AO_SOURCE_H_A_H ][ ao_loc_data_picked_H.fetch( K.uri ) ] ||= []
                 
        ao_ref__uri_n_instance_idx__H = { K.uri      => ao_record_H.fetch( K.uri ),
                                          K.instance => instance_idx,
                                         }.cbv
        ao_loc_data_picked_H_A_H[ ao_record_H.fetch( K.uri ) ][ instance_idx ] = ao_loc_data_picked_H    
        bool = tc__ao_loc_n_source_H.fetch( AO_SOURCE_H_A_H ).fetch( ao_loc_data_picked_H.fetch( K.uri ) ).find { | ao_list_H | 
            ao_list_H.fetch( K.uri ) == ao_ref__uri_n_instance_idx__H.fetch( K.uri ) } 
        if bool then 
            puts "#{SE.lineno}: =============================="
            puts "WARNING: AO has more than one reference to TC: #{tc_data_H.fetch( K.type )}-#{tc_data_H.fetch( K.indicator )} "
            puts "Offending AO: #{ao_ref__uri_n_instance_idx__H.fetch( K.level )}: #{ao_ref__uri_n_instance_idx__H.fetch( K.title )} '#{ao_ref__uri_n_instance_idx__H.fetch( K.uri ).trailing_digits}' " 
            puts ''
        end 
        tc__ao_loc_n_source_H[ AO_SOURCE_H_A_H ][ ao_loc_data_picked_H.fetch( K.uri )] << ao_ref__uri_n_instance_idx__H   
                          
    end
end

SE.puts "#{tc_data_H_H.length} TC records."
print__tcz_locations( tc_data_H_H, tc_query_O, ao_loc_n_source_H_H, ao_query_O )
#SE.q {'tc_data_H_H'}

tc_data_H_H.each_pair do | tc_uri, tc_data_H |
    ao_loc_n_source_H_A = tc_data_H.fetch( AO_LOC_n_SOURCE_H_A )
    if ( ao_loc_n_source_H_A.empty? ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "tc_data_H.fetch( AO_LOC_n_SOURCE_H_A ).empty?"
        SE.q {['tc_uri', 'tc_data_H']}
        raise
    end

    ao_loc_n_source_H_A.map! do | ao_loc_n_source_H |
        loc_id = ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_ID )
        if ( loc_id.in?( NO_LOCATION, INVALID_LOCATION ) ) then
            if ( tc_data_H.fetch( K.indicator )[ 0, 3 ].upcase == 'UNK' ) then
                puts "UNK TC skipped due to '#{loc_id}': #{tc_data_H.fetch( K.type )}-#{tc_data_H.fetch( K.indicator )} #{tc_uri}"
                ao_loc_n_source_H = {}     #THIS WORKS, ONLY because of 'next ao_loc_n_source_H' below.
            end
            if ( tc_data_H.fetch( K.type ).upcase != 'BOX' ) then
                puts "Non-BOX TC skipped due to '#{loc_id}': #{tc_data_H.fetch( K.type )}-#{tc_data_H.fetch( K.indicator )} #{tc_uri}"
                ao_loc_n_source_H = {}  
            end
        end
        next ao_loc_n_source_H              #map! is expecting something back for EACH iteration of the loop. 
                                            #Without next ao_loc_n_source_H, the value of the last statement is return 
                                            #which is the if statement IF IT'S FALSE.
    end
    ao_loc_n_source_H_A.delete_if { | ao_loc_n_source_H | ao_loc_n_source_H.empty? }
    next if ( ao_loc_n_source_H_A.empty? )

    cnt = ao_loc_n_source_H_A.count { | ao_loc_n_source_H | ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_ID ) == NO_LOCATION }                                                                           
    if ( cnt > 1 ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "count ( NO_LOCATION ) > 1"
        SE.q {['tc_uri', 'tc_data_H']}
        raise
    end
    cnt = ao_loc_n_source_H_A.count { | ao_loc_n_source_H | ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_ID ) == INVALID_LOCATION }                                                                           
    if ( cnt > 1 ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "count ( INVALID_LOCATION ) > 1"
        SE.q {['tc_uri', 'tc_data_H']}
        raise
    end
    cnt = ao_loc_n_source_H_A.count { | ao_loc_n_source_H | ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_ID ) == DUPLICATE_LOCATIONS }                                                                           
    if ( cnt > 1 ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "count ( DUPLICATE_LOCATIONS ) > 1"
        SE.q {['tc_uri', 'tc_data_H']}
        raise
    end
    if ( ao_loc_n_source_H_A.length > 1 ) then
        ao_loc_n_source_H_A << { LOC_DATA_H      => { LOC_ID      => DUPLICATE_LOCATIONS,      
                                                      LOC_RANGE_H => {},
                                                     },
                                 AO_SOURCE_H_A_H => {},                    
                                }.cbv      
        puts "#{tc_data_H.fetch( K.type )}-#{tc_data_H.fetch( K.indicator )} '#{tc_uri.trailing_digits}' #{DUPLICATE_LOCATIONS}"
    end
        
end        

#   Loop TC's and verify we can find all the assigned locations

tc_to_update_A = []
ao_source_uri_A = []
loc_id_H_H = {}
tc_data_H_H.each_pair do | tc_uri, tc_data_H |
    next if ( tc_data_H.fetch( AO_LOC_n_SOURCE_H_A ).empty? )
    tc_data_H.fetch( AO_LOC_n_SOURCE_H_A ).each do | ao_loc_n_source_H |
        loc_id = ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_ID )
        location_title = get_location_title( loc_id )
        loc_id_H = loc_id_H_H[ loc_id ] ||= { :loc_id_cnt => 0, :location_title => location_title, K.uri => '' }.cbv
        loc_id_H[ :loc_id_cnt ] += 1
        if ( loc_id_H.fetch( K.uri ).blank? ) then
            search_text = %Q|title:"#{location_title}"|
            location_search_H_A = rep_O.search( record_type: K.location, search_text: search_text ).result_A
            if ( location_search_H_A.nil? || location_search_H_A.empty? )
                                loc_id_H[ K.uri ] = CREATE_ALA_LOCATION
            else
                if ( location_search_H_A.length == 1 and 
                     location_search_H_A.first[ K.title].downcase == location_title.downcase 
                     ) then
                    location_search_H = location_search_H_A.first
                else
                    arr = location_search_H_A.select { | location_search_H | 
                                                         location_search_H[ K.title].downcase == location_title.downcase }
                    if ( arr.length != 1 )
                        SE.puts "#{SE.lineno}: =============================="
                        SE.puts "Invalid Location search result: 'location_search_H_A.length' > 1 but 'arr.length' != 1"
                        SE.q {'location_title'}
                        SE.q {'arr'}
                        SE.q {'location_search_H_A'}
                        SE.q {'loc_id'}
                        SE.q {'tc_data_H'}
                        raise
                    end
                    location_search_H = arr.first
                    raise "I thought this problem went away!"
                end

                if ( location_search_H.fetch( K.id ) != location_search_H.fetch( K.uri ) ) then
                    SE.puts "#{SE.lineno}: =============================="
                    SE.puts "location_search_H.fetch( K.id ) != location_search_H.fetch( K.uri )"
                    SE.q {'location_search_H'}
                    raise
                end
                loc_id_H[ K.uri ] = location_search_H.fetch( K.uri )
            end
        end

        ao_source_uri_A.concat( ao_loc_n_source_H.fetch( AO_SOURCE_H_A_H ).keys )
        ao_source_uri_A.uniq!
        
        tc_record_H = tc_query_O.record_H__of_uri( tc_uri )  
        non_ala_container_loc_found = not tc_record_H.fetch( K.container_locations ).all? {      
            | container_location | container_location[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER}/i ) or 
                                   container_location[ K.start_date ].to_s == ALA_START_DATE }   
        if ( non_ala_container_loc_found ) then
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "Non ALA container_location found for TC, I can' deal with this complexity!"
            SE.q {'tc_record_H[ K.container_locations ]'}
            raise
        end
        if ( self.cmdln_option_H.fetch( :rm_ala_locations ) ) then
            ala_container_loc_already_there = false
        else
            ala_container_loc_already_there = tc_record_H.fetch( K.container_locations ).any? { 
                | container_location | container_location.fetch( K.ref ) == loc_id_H.fetch( K.uri ) }
        end
        tc_to_update_A << tc_uri if ( ! ala_container_loc_already_there && tc_to_update_A.not_include?( tc_uri ) )
    end   
end

print__aoz_with_unused_locations( ao_loc_n_source_H_H, ao_source_uri_A )

SE.q {['tc_data_H_H.length','tc_to_update_A.length']}
SE.q {'loc_id_H_H.length'}

if ( tc_to_update_A.empty? ) then
    puts "Nothing to do."
    exit
end

loc_id_H_H.each_pair do | loc_id, loc_id_H | 
    raise "loc_id_H.fetch( K.uri ).blank?" if ( loc_id_H.fetch( K.uri ).blank? )
    next if ( loc_id_H.fetch( K.uri ) != CREATE_ALA_LOCATION )
    record_H = Record_Format.new( :location ).record_H
    record_H[ K.building ]               = ALA_PROBLEMS
    record_H[ K.classification ]         = self.location_classification
    record_H[ K.coordinate_1_indicator ] = loc_id
    record_H[ K.coordinate_1_label ]     = ERROR_LABEL
    loc_buf_O = Location.new( rep_O ).new_buffer.create.load( record_H )
    loc_buf_O.store
    loc_id_H[ K.uri ] = loc_buf_O.uri_addr
    puts "Created location(#{loc_buf_O.uri_addr.trailing_digits})': '#{get_location_title( loc_id )}'"
end

tc_to_update_A.each_with_index do | tc_uri, tc_uri_idx | 
    break if ( self.cmdln_option_H[ :do_only_n ].not_nil? && tc_uri_idx + 1 > self.cmdln_option_H[ :do_only_n ] )
    tc_data_H = tc_data_H_H.fetch( tc_uri )
    tc_buf_O = Top_Container.new( res_O, tc_uri ).new_buffer.read
    raise "tc_buf_O.nil?" if tc_buf_O.nil?
    tc_record_H = tc_buf_O.record_H
    puts "TC: '#{tc_record_H.fetch( K.uri ).trailing_digits}', #{tc_record_H.fetch( K.type )}-#{tc_record_H.fetch( K.indicator )}"

    if ( self.cmdln_option_H.fetch( :rm_ala_locations ) ) then
        tc_record_H.fetch( K.container_locations ).delete_if { 
                | container_location | container_location[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER}/i ) or 
                                       container_location[ K.start_date ].to_s == ALA_START_DATE }
        raise "tc_record_H.fetch( K.container_locations ).not_empty?" if ( tc_record_H.fetch( K.container_locations ).not_empty? )
    end

    tc_data_H.fetch( AO_LOC_n_SOURCE_H_A ).each do | ao_loc_n_source_H |  
        loc_id = ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_ID )
        location_uri = loc_id_H_H.fetch( loc_id ).fetch( K.uri )
        cl_record_H = Record_Format.new( :container_location ).record_H
        cl_record_H[ K.start_date ] = ALA_START_DATE
        cl_record_H[ K.ref ]        = location_uri
        note_for_container_location = "#{ALA_NOTE_MARKER} #{loc_id}"
        range = ao_loc_n_source_H.fetch( LOC_DATA_H ).fetch( LOC_RANGE_H )
        if ( range.not_empty? ) then
            note_for_container_location << " Range: #{range}"
        end
        note_for_ao_orig_loc_note = "#{note_for_container_location.strip}; \n"             # <<<<<<<<<<<<<<<<
      
        if ( tc_data_H.fetch( AO_SOURCE_NOTE, '' ).not_blank? ) then
            note_for_container_location << "; #{tc_data_H.fetch( AO_SOURCE_NOTE ) }"
        end
        if ( ao_loc_n_source_H.fetch( LOC_NOTE, '' ).not_blank? ) then
            note_for_container_location << "; #{ao_loc_n_source_H.fetch( LOC_NOTE )}"
        end
        if ( note_for_container_location.length > 250 ) then
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "note_for_container_location.length > 250"
            SE.puts "The database column is a varchar( 255 )"
            SE.q {'note_for_container_location'}
            raise
        end
        cl_record_H[ K.note ] = note_for_container_location
                
        tc_record_H[ K.container_locations ] << cl_record_H
        puts "CL: #{tc_record_H[ K.container_locations ].length}: Loc: '#{location_uri.trailing_digits}': #{note_for_container_location}"
        ao_loc_n_source_H[ AO_SOURCE_H_A_H ].each_key do | ao_loc_source_uri |
            if ( ao_loc_source_uri[ 0 ] == '/' ) then
                if ( ao_loc_source_uri == self.res_buf_O.record_H.fetch( K.uri ) ) then
                    ao_buf_O = self.res_buf_O = res_O.new_buffer.read
                else
                    ao_buf_O = Archival_Object.new( res_O, ao_loc_source_uri ).new_buffer.read
                end           
                orig_loc_note_CKA = ao_loc_n_source_H.fetch( ORIG_LOC_TEXT_H ).fetch( ORIG_LOC_TEXT_KEY_CKA )
                orig_loc_text     = ao_buf_O.record_H.dig( *orig_loc_note_CKA )
                orig_loc_text.sub!( /^\<physloc\>: /, '' )              
                if ( orig_loc_text.not_include?( note_for_ao_orig_loc_note ) )
                    orig_loc_text.prepend( note_for_ao_orig_loc_note )       
                    ao_record_H = ao_buf_O.record_H
                    puts "AO: '#{ao_record_H.fetch( K.uri ).trailing_digits}' " + 
                         "#{ao_record_H.fetch( K.level )}: #{ao_record_H.fetch( K.title )[ 0,20 ]} " +
                         "#{ao_buf_O.record_H.dig( *orig_loc_note_CKA )}" +
                         ''  
                    ao_buf_O.store                     
                end
            end
        end
    end 
    tc_buf_O.store
    puts ''
end









