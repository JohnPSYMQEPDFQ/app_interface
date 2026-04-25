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
        attr_accessor :myself_name, :cmdln_option_H, :ala_id_0,
                      :rep_O, :res_O, :res_buf_O
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...


def get_location_title( loc_data_H )
    loc_id = loc_data_H.fetch( LOC_ID )    
    if ( loc_id.in?( NO_LOCATION, INVALID_LOCATION, DUPLICATE_LOCATIONS ) )
        stringer = "#{ALA_PROBLEMS} [#{self.ala_id_0}, #{ERROR_LABEL}: #{loc_id}"
        if ( loc_data_H.has_key?( INVALID_LOCATION_A ) ) then            
            if ( loc_data_H[ INVALID_LOCATION_A ].is_not_a?( Array ) || loc_data_H[ INVALID_LOCATION_A ].length > 2 ) then
                SE.puts "#{SE.lineno}: =============================="
                SE.puts 'loc_data_H[ INVALID_LOCATION_A ].is_not_a?( Array ) || loc_data_H[ INVALID_LOCATION_A ].length > 2'
                SE.q {'loc_data_H[ INVALID_LOCATION_A ]'}
                SE.q {'loc_id'}
                raise
            end
            if ( loc_data_H[ INVALID_LOCATION_A ].not_empty? ) then
                stringer << ", #{loc_data_H[ INVALID_LOCATION_A ].fetch( 0 )}:"
                stringer << " #{loc_data_H[ INVALID_LOCATION_A ].fetch( 1, '!' )}"
            end
        end
        stringer << ']'
        return stringer
    end

    smcc_loc_O = loc_id.match( /#{K.smcc_loc_id_RES}/i )
    if ( smcc_loc_O.nil? ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "loc_id.match( /#{K.smcc_loc_id_RES}/i ) == nil"
        SE.q {'loc_id'}
        raise
    end
    xyz_A = []
    xyz_A << smcc_loc_O[ :XYZ_1 ]
    xyz_A << smcc_loc_O[ :XYZ_2 ]
    xyz_A << smcc_loc_O[ :XYZ_3 ]
    xyz_A << smcc_loc_O[ :XYZ_4 ]
    xyz_A.compact!
    if ( xyz_A.maxindex.not_between?( 2, 3 ) ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "xyz_A.maxindex.not_between?( 2, 3 )"
        SE.q {'loc_id'}
        SE.q {'xyz_A'}
        raise
    end
    xyz_letter_A = []
    xyz_number_A = []   
    xyz_A.each_with_index do | xyz, idx |
        if idx == 1 then
            xyz_number_A << xyz.to_i
            xyz_letter_A << K.undefined   
        else
            xyz_number_A << xyz.trailing_digits.to_i
            xyz_letter_A << xyz.first( 1 ).upcase      
        end
    end
    
    xyz_number_A.compact!
    if ( xyz_number_A.maxindex.not_between?( 2, 3 ) ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "xyz_number_A.maxindex.not_between?( 2, 3 )"
        SE.q {'loc_id'}
        SE.q {'xyz_A'}
        SE.q {'xyz_number_A'}
        raise
    end
    xyz_letter_A.compact!
    if ( xyz_letter_A.maxindex.not_between?( 2, 3 ) ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "xyz_letter_A.maxindex.not_between?( 2, 3 )"
        SE.q {'loc_id'}
        SE.q {'xyz_A'}
        SE.q {'xyz_letter_A'}
        raise
    end
    
    stringer = "smcc, #{xyz_letter_A[ 0 ]} bay, area #{xyz_number_A[ 0 ]} " +
               "[range: #{xyz_A[ 1 ]}, column: #{xyz_letter_A[ 2 ]}, shelf: #{xyz_number_A[ 2 ]}"
    if ( xyz_A.maxindex == 3 ) then
        case true
        when ( xyz_letter_A[ 2 ] == xyz_letter_A[ 3 ] ) 
            stringer.concat( "-#{xyz_number_A[ 3 ]}" )
        when ( xyz_letter_A[ 2 ].next == xyz_letter_A[ 3 ] )
            stringer.concat( "-#{xyz_A[ 3 ]}" )
        else
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "xyz_letter_A[ 2 ] != xyz_letter_A[ 3 ]"
            SE.q {'loc_id'}
            SE.q {'xyz_A'}
            SE.q {'xyz_letter_A'}
            raise            
        end
    end
    stringer.concat( ']' )
    return stringer
end

def set_location( loc_data_H, loc_uri_by_title_H )
    location_title = get_location_title( loc_data_H ) 
    loc_data_H[ CONTAINER_LOC_TITLE ] = location_title
    if ( loc_uri_by_title_H.has_key?( location_title ) ) then
        loc_data_H[ CONTAINER_LOC_URI ] = loc_uri_by_title_H[ location_title ].dup
        return                            loc_uri_by_title_H[ location_title ].dup
    else
        search_text = %Q|title:"#{location_title}"|         # Note field-name and quotes in text
        loc_record_H_A = self.rep_O.search( record_type_A: [ K.location ], search_text: search_text ).result_A
        if ( loc_record_H_A.nil? || loc_record_H_A.empty? ) then
            loc_data_H[ CONTAINER_LOC_URI ]      = CREATE_ALA_LOCATION
            loc_uri_by_title_H[ location_title ] = CREATE_ALA_LOCATION           
            return                                 CREATE_ALA_LOCATION
        end
    end

    if ( loc_record_H_A.length == 1 && 
         loc_record_H_A.first[ K.title].downcase == location_title.downcase 
         ) then
        loc_record_H = loc_record_H_A.first
    else
        arr = loc_record_H_A.select { | loc_record_H | 
                                        loc_record_H[ K.title].downcase == location_title.downcase }
        if ( arr.length != 1 )
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "Probably a duplicate Location record: 'loc_record_H_A.length' > 1 and 'arr.length' != 1"
            SE.q {'location_title'}
            SE.q {'arr'}
            SE.q {'loc_record_H_A'}
            SE.q {'loc_data_H'}
            raise
        end
        loc_record_H = arr.first
        raise "I thought this problem went away!"
    end

    if ( loc_record_H.fetch( K.id ) != loc_record_H.fetch( K.uri ) ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "loc_record_H.fetch( K.id ) != loc_record_H.fetch( K.uri )"
        SE.q {'loc_record_H'}
        raise
    end
    loc_uri_by_title_H[ location_title ] = loc_record_H.fetch( K.uri ).dup
    loc_data_H[ CONTAINER_LOC_URI ]      = loc_uri_by_title_H[ location_title ].dup
    return                                 loc_uri_by_title_H[ location_title ].dup
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


def print__aoz_having_locations( source_data_H_H )
    captured_stringer = capture_stdout do
        puts ''
        puts "AO's having locations:"
        source_data_H_H.each_pair do | _, source_data_H |
            puts "#{source_data_H.fetch( K.level )}: #{source_data_H.fetch( K.title )[ 0,60 ]} " +
                 "`#{source_data_H.fetch( K.uri ).trailing_digits}` " +
                 ''                   
            puts "        Text: #{source_data_H.fetch( LOC_DATA_H ).fetch( TEXT_H ).fetch( TEXT_VALUE )}"       
            source_data_H.fetch( LOC_DATA_H ).fetch( LOC_ID_n_RANGE_H_A )
                             .each do | loc_id_n_range_H | 
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

def print__aoz_with_unused_locations( source_data_H_H, unused_ao_location_A )
    captured_stringer = capture_stdout do
        puts ''
        puts "AO's having locations that were never used:"
        unused_ao_location_A.each do | unused_uri |
            source_data_H = source_data_H_H.fetch( unused_uri )
            puts "#{source_data_H.fetch( K.level )}: #{source_data_H.fetch( K.title )[ 0,60 ]} " +
                 "`#{source_data_H.fetch( K.uri ).trailing_digits}` " +
                 ''             
            puts "        Text: #{source_data_H.fetch( LOC_DATA_H ).fetch( TEXT_H ).fetch( TEXT_VALUE )}"
            source_data_H.fetch( LOC_DATA_H ).fetch( LOC_ID_n_RANGE_H_A ).each do | loc_id_n_range_H | 
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

def print__tcz_locations( tc_data_H_H, tc_query_O, ao_query_O )    
    cnt_of_bad_locations = 0
    puts ''
    puts "TC's assigned locations:"
    tc_data_H_H.each_pair do | tc_uri, tc_data_H |
        print "#{tc_data_H.fetch( K.type )} #{tc_data_H.fetch( K.indicator )} `#{tc_uri.trailing_digits}` "
        arr = tc_data_H_H.fetch( tc_uri ).fetch( PICKED_DATA_H_A )
            .map { | picked_data_H |  picked_data_H.fetch( LOC_DATA_H ).fetch( LOC_ID ) } 
            .uniq
        if arr.length > 1 then
            print "<<<<< WARNING: TC has more than 1 location!"
        end
        puts ''

        container_loc_note_A = [ ]    
        tc_data_H.fetch( PICKED_DATA_H_A ).each do | picked_data_H |            
            loc_data_H = picked_data_H.fetch( LOC_DATA_H )
            loc_id = loc_data_H.fetch( LOC_ID )
            if ( loc_id.in?( NO_LOCATION, INVALID_LOCATION ) ) then
                cnt_of_bad_locations += 1
            end
            puts "    Location: #{loc_id} `#{loc_data_H.fetch( CONTAINER_LOC_TITLE )}`"
            if ( loc_data_H.has_key?( INVALID_LOCATION_ERROR_NOTE ) ) then
                error_note = loc_data_H.fetch( INVALID_LOCATION_ERROR_NOTE )
                if ( error_note.not_blank? ) then
                    puts "    Note: #{error_note}"
                end
            end
            picked_data_H[ PICKED_DATA_H__CHILD_H_A ].each_pair do | picked_uri, child_H_A |            
                if ( child_H_A.length == 1 && child_H_A.first.fetch( K.uri ) == picked_uri ) then
                    stringer = "        Self Source:"
                    print_children = false
                else
                    stringer = "        Source:"
                    print_children = true
                end
                if ( loc_id.in?( NO_LOCATION, INVALID_LOCATION ) ) then
                    print_children = true
                else
                    if ( picked_uri == self.res_buf_O.record_H.fetch( K.uri ) ) then
                        ao_record_H = self.res_buf_O.record_H
                    else
                        ao_record_H = ao_query_O.record_H__of_uri( picked_uri )
                    end
                    text = "#{stringer} `#{picked_uri.trailing_digits}`" +
                   #       ' ' + "#{ao_record_H.fetch( K.level )}: #{ao_record_H.fetch( K.title )[ 0,60 ]}" + 
                           ''
                    puts text
                   #if ( container_loc_note_A.include?( text.lstrip ) ) then
                       #SE.q {'picked_uri'}
                       #SE.q {'ao_record_H[ K.uri ]'}
                       #SE.q {'text.lstrip'}
                       #SE.q {'container_loc_note_A'}
                       #SE.q {'picked_data_H[ PICKED_DATA_H__CHILD_H_A ].keys'}
                       #SE.q {'tc_data_H'}
                       #raise
                   #end
                    container_loc_note_A << text.lstrip
                end
                next if print_children == false
                puts "        AO Refs: "
                child_H_A.each do | child_H |
                    ao_uri = child_H.fetch( K.uri ) 
                    ao_record_H = ao_query_O.record_H__of_uri( ao_uri )
                    puts "            `#{ao_uri.trailing_digits}/#{child_H.fetch( K.instance )}`" +
                         ' ' + "#{ao_record_H.fetch( K.level )}: #{ao_record_H.fetch( K.title )[ 0,60 ]}" 
                         ' '      
                end
            end
            tc_data_H[ CONTAINER_LOC_NOTE ] = container_loc_note_A.join( '; ' )
            puts ' '
            puts ''     
        end   
    end

    tc_missing_A = tc_query_O.record_H_A.map{ | record_H | record_H.fetch( K.uri ) } - tc_data_H_H.keys
    if ( tc_missing_A.empty? ) then
        SE.puts "#{tc_data_H_H.keys.length} TC's have locations."
        SE.puts "#{cnt_of_bad_locations} TC's have bad locations."
        return
    end
    
    SE.puts "#{tc_missing_A.length} TC's don't have locations."
    raise
end

def expand_boxes( input_str )  
    expanded_box_A = []
    
    arr = input_str.downcase.split( /#{K.valid_container_types_RES}/ ).reject( &:blank? )
    if ( arr.length % 2 != 0 ) then
        SE.puts "#{SE.lineno} I was expecting an even length array."
        SE.q {['input_str']}
        SE.q {['arr']}
        raise              
    end
    arr.each_slice( 2 ) do | type, numbers |
        if ( type.not_match?( /#{K.valid_container_types_RES}/ ) ) then
            SE.puts "#{SE.lineno} I was expecting the type to match `#{K.valid_container_types_RES}`"
            SE.q {['input_str']}
            SE.q {['type']}
            SE.q {['numbers']}
            raise 
        end
        number_A = numbers.split( ',' ).map( &:strip )           
        number_A.each do | number |
            if number.include?( '-' )
                range_A = number.split( '-' )
                if range_A.length != 2 then
                    SE.puts "#{SE.lineno} I was expecting a length of two for the range, not `#{range_A.length}`"
                    SE.q {['input_str']}
                    SE.q {['number_A']}
                    SE.q {['number', 'range_A']}
                    raise
                end
                if ( range_A.first.not_integer? || range_A.last.not_integer? ) then
                    SE.puts "#{SE.lineno} I was expecting two integers for the range, not `#{range_A.join( '` ' )}`"
                    SE.q {['input_str']}
                    SE.q {['number_A']}
                    SE.q {['number', 'range_A']}
                    raise               
                end                
            else
                if ( number.not_integer? ) then
                    SE.puts "#{SE.lineno} I was expecting an integer, not `#{number}`"
                    SE.q {['input_str']}
                    SE.q {['number_A']}
                    raise               
                end          
            end
            expanded_box_A << "#{type} #{number}"
        end
    end
    expanded_box_A.join(', ')
end


def strip_off_more_noise( param_1 )
    result = param_1.to_s.dup
    result.sub!( /\A(\s*[[:punct:]])+/, ' ' )
    result.sub!( /\A(\s*\(.*\))+/, ' ' )
    result.sub!( /\A(\s+ID\s+\d+)/, ' ' )
    result.sub!( /\A(shelf)/i, ' ' )
    result.sub!( /\A\s*((SMCC|Statewide\s+Museum\s+Collections?\s+Center)[,;:]?\s*(rg\s+\d+\s+series\s+\d+\s+)?)+\s*/i, ' ' )
    result.strip!
    return result
end

def get_loc_from_ao( record_H )
    loc_RE   = /(?<PRECEDING_TEXT>^.*?)#{K.smcc_loc_id_RES}(?<TRAILING_TEXT>.*$)/i                  
    source_data_H_A = []     
    record_H.to_composite_key_h.each_pair do | composite_key_A, source_text_value |
        source_data_H = {}
        next if ( source_text_value.is_not_a?( String ) )
        composite_key_A.freeze
        source_text_value_WO_CRLF = source_text_value.gsub(/([\r]*[\n])+/, " | ")
        source_text_value_WO_CRLF.freeze                # for coding safety
        location_FOOD = source_text_value_WO_CRLF.dup   # '_FOOD' meaning: a string to search/replace consume until empty        
        location_FOOD.gsub!( /#{ALA_NOTE_MARKER}.*?\s*\|/, '' )
        location_FOOD.gsub!( %r'(<p>|</p>)', '' )
        location_FOOD.sub!( /^\<physloc\>: /, '' )
        ld_1 = SE::Loop_detector.new( 100 )
        loop do   
            location_FOOD = strip_off_more_noise( location_FOOD )
            location_FOOD.sub!( loc_RE, '' )
            loc_MO = $~ 
            if loc_MO.nil? 
                break 
            end                 
            ld_1.loop( loc_MO )    
        
            if source_data_H.empty? then
               source_data_H[ LOC_ID_n_RANGE_H_A ] = [ ]
               source_data_H[ TEXT_H ]  = { TEXT_KEY_CKA => composite_key_A.freeze,
                                            TEXT_VALUE   => source_text_value_WO_CRLF.dup }
            end
                                              
            loc_MO__preceding_text = strip_off_more_noise( loc_MO[ :PRECEDING_TEXT ] )
            loc_MO__trailing_text  = strip_off_more_noise( loc_MO[ :TRAILING_TEXT ] )
            case true
            when ( loc_MO__preceding_text.not_blank? )    # .blank does a .to_s which converts nil to ''
                container_FOOD = loc_MO__preceding_text
                location_FOOD  = strip_off_more_noise( loc_MO[ :TRAILING_TEXT ] )
            when ( loc_MO__trailing_text.not_blank? ) 
                stringer = loc_MO__trailing_text.sub( loc_RE, '' )
                next_loc_MO = $~
                if next_loc_MO.nil? 
                    container_FOOD = strip_off_more_noise( stringer )
                    location_FOOD  = ''.dup
                else
                    container_FOOD = strip_off_more_noise( next_loc_MO[ :PRECEDING_TEXT ] )
                    location_FOOD  = next_loc_MO[ :SMCC_LOC_ID ] + ' ' + strip_off_more_noise( next_loc_MO[ :TRAILING_TEXT ] )
                end                 
            else
                                          # No data on either side of the location.
                container_FOOD = ''.dup
                location_FOOD  = ''.dup
            end
           #SE.q {'loc_MO.named_captures'}
           #SE.q {['location_FOOD','container_FOOD']}
            
            loc_id_n_range_H = {}
            loc_id_n_range_H[ LOC_ID ]        = loc_MO[ :SMCC_LOC_ID ] 
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
                    SE.q {'source_text_value_WO_CRLF'}
                    SE.q {'container_FOOD'}
                    raise
                end
                container_type  = container_MO[ :container_type ].downcase.sub( /(es|s)$/,'' ).strip
                container_num_A = container_MO[ :container_num ].split( ',' ).map( &:downcase ).map( &:strip )
                container_num_A.each do | container_num |
                    if ( container_num.match?( /^ov\s*\d+/i ) ) then
                        container_num = 'ov ' + container_num.trailing_digits
                    end
                    range_A = container_num.split( '-' ).map( &:strip )
                    range = nil
                    if ( range_A.length.between?( 1, 2 ) )  
                        if ( container_type.downcase == 'ov' ) then
                            range_A.each do | range | 
                                next if ( range.begin_with?( 'ov' ) )
                                range.prepend( 'ov ' )
                            end
                        end
                        case true
                        when ( range_A.first.integer? && range_A.last.integer? ) 
                            range = range_A.first.to_i .. range_A.last.to_i
                        when ( range_A.first.not_integer? && range_A.last.not_integer? )
                            range = range_A.first .. range_A.last
                        else
                            SE.puts "#{SE.lineno} range_A is neither all integer or all NOT integer."
                        end
                    else
                        SE.puts "#{SE.lineno} range_A.length not 1 or 2"
                    end
                    if range.nil? 
                        SE.puts "#{SE.lineno} I got a bad container range."
                        SE.q {'container_MO'}
                        SE.q {'record_H.fetch( K.title )'}
                        SE.q {"composite_key_A.join( ',' )"}
                        SE.q {'source_text_value_WO_CRLF'}
                        SE.q {'container_MO[ :container_num ]'}
                        SE.q {'stringer'}
                        SE.q {'container_num_A'}
                        SE.q {'container_num'}
                        SE.q {'range_A'}
                        raise
                    end      
                    loc_id_n_range_H[ LOC_RANGE_H_A ] << { container_type => range }
                end
                SE.q {'loc_id_n_range_H'} if ( $DEBUG )
            end

            loc_id_n_range_H_A = source_data_H.fetch( LOC_ID_n_RANGE_H_A )
                                              .select { | hash | hash[ LOC_ID ] == loc_id_n_range_H.fetch( LOC_ID ) }
            if ( loc_id_n_range_H_A.length > 2 ) then
                SE.puts "#{SE.lineno} Found more than 2 `#{loc_id_n_range_H.fetch( LOC_ID )}` locations in `source_data_H`"
                SE.q {'loc_id_n_range_H_A'}
                SE.q {'source_data_H'}
                raise
            end
            if ( loc_id_n_range_H_A.count { | hash | hash.fetch( LOC_RANGE_H_A ).empty? } > 1 ) then
                SE.puts "#{SE.lineno} `loc_id_n_range_H_A.count { | hash | hash.fetch( LOC_RANGE_H_A ).empty? } > 1`"
                SE.q {'loc_id_n_range_H_A'}
                SE.q {'source_data_H'}
                raise
            end
            if ( loc_id_n_range_H_A.count { | hash | hash.fetch( LOC_RANGE_H_A ).not_empty? } > 1 ) then
                SE.puts "#{SE.lineno} `loc_id_n_range_H_A.count { | hash | hash.fetch( LOC_RANGE_H_A ).empty? } > 1`"
                SE.q {'loc_id_n_range_H_A'}
                SE.q {'source_data_H'}
                raise
            end
            if ( loc_id_n_range_H_A.empty? )     
                source_data_H[ LOC_ID_n_RANGE_H_A ] << loc_id_n_range_H   # This would be the first entry
            else
                if ( loc_id_n_range_H.fetch( LOC_RANGE_H_A ).empty? ) then  
                    if ( loc_id_n_range_H_A.none? { | hash | hash.fetch( LOC_RANGE_H_A ).empty? } ) then
                        source_data_H[ LOC_ID_n_RANGE_H_A ] << loc_id_n_range_H   # There are no loc's with an 
                                                                                      # empty range, so add it.
                    else
                        # Do nothing because there's already a loc with a empty range in there.
                    end
                else
                    if ( loc_id_n_range_H_A.none? { | hash | hash.fetch( LOC_RANGE_H_A ).not_empty? } ) then
                        source_data_H[ LOC_ID_n_RANGE_H_A ] << loc_id_n_range_H   # There are no loc's with a 
                                                                                      # range, so add it.
                    else  
                        loc_id_n_range_H_A.each do | hash |
                            next if ( hash.fetch( LOC_RANGE_H_A ).empty? )
                            hash[ LOC_RANGE_H_A ].concat( loc_id_n_range_H.fetch( LOC_RANGE_H_A ) ).uniq!
                        end
                    end
                end
            end
 
            container_FOOD = strip_off_more_noise( container_FOOD )
            if container_FOOD.not_blank? then                       
                SE.puts "#{SE.lineno} I've got unknown data in 'container_FOOD'"
                SE.q {'record_H.fetch( K.title )'}
                SE.q {"composite_key_A.join( ',' )"}
                SE.q {'source_text_value_WO_CRLF'}
                SE.q {'container_FOOD'}
                SE.q {'location_FOOD'}
                SE.q {'source_data_H'}
                next  
            end
        end
        next if source_data_H.empty?    
        
        if location_FOOD.not_blank? then
            SE.puts "#{SE.lineno} I've got unknown data in 'location_FOOD'"
            SE.q {'record_H.fetch( K.title )'}
            SE.q {"composite_key_A.join( ',' )"}
            SE.q {'source_text_value_WO_CRLF'}
            SE.q {'location_FOOD'}
            SE.q {'source_data_H'}
            next 
        end

        source_data_H_A << source_data_H 

    end

    if ( source_data_H_A.empty? ) then
        return {}
    end
    if ( source_data_H_A.length > 1 ) then
        puts "#{SE.lineno}: =============================="
        puts 'More than one location source found for record:'
        puts "#{record_H.fetch( K.level )}: #{record_H.fetch( K.title )} " +
             "`#{record_H.fetch( K.uri ).trailing_digits}` " +
             ''    
       #SE.q {'source_data_H_A'}
       #SE.q {'source_data_H'}
       #SE.q {'record_H'}
        puts 'Record skipped.'
        puts ''
        return {}
    end
    
    source_data_H = source_data_H_A.first
    cnt = source_data_H_A.first.fetch( LOC_ID_n_RANGE_H_A ).count { |arr| arr[ LOC_RANGE_H_A ].empty? }
    if cnt > 1 then
        puts 'More than one location without a range found for record:'
        puts "#{record_H.fetch( K.level )}: #{record_H.fetch( K.title )} " +
             "`#{record_H.fetch( K.uri ).trailing_digits}` " +
             ''
        arr = source_data_H_A.first.fetch( LOC_ID_n_RANGE_H_A ).map { | hash | hash[ LOC_ID ] }
        puts "Locations: #{arr.join( ', ')}" +
             ''    
       #SE.q {'source_data_H_A.first'}
       #SE.q {'source_data_H'}
       #SE.q {'record_H'}
        puts 'Record skipped.'
        puts ''
        return {}
    end    
    
    source_data_H_A.first.fetch( LOC_ID_n_RANGE_H_A ).sort_by! do | hash |
        empty_sort_key  = hash.fetch( LOC_RANGE_H_A ).empty? ? 1 : 0 # empty last
        length_sort_key = hash.fetch( LOC_RANGE_H_A ).length         # but non_empty small to big
        [ empty_sort_key, length_sort_key ]
    end

    source_data_H = {}  
    source_data_H[ LOC_DATA_H ] = source_data_H_A.first
    source_data_H[ K.title ]    = record_H.fetch( K.title )
    source_data_H[ K.level ]    = record_H.fetch( K.level )
    source_data_H[ K.uri ]      = record_H.fetch( K.uri )   
   #SE.q {'source_data_H'}
    return source_data_H
end

# puts "#{$stderr.class}"
# puts "#{$stdout.class}"
BEGIN {    

    CONTAINER_LOC_NOTE           = 'CONTAINER_LOC_NOTE'
    CONTAINER_LOC_TITLE          = 'CONTAINER_LOC_TITLE'
    CONTAINER_LOC_URI            = 'CONTAINER_LOC_URI'                
    CREATE_ALA_LOCATION          = 'CREATE_ALA_LOCATION'
    INVALID_LOCATION_ERROR_NOTE  = 'INVALID_LOCATION_ERROR_NOTE'
    LOC_DATA_H                   = 'LOC_DATA_H'
    LOC_ID                       = 'LOC_ID'
    LOC_ID_n_RANGE_H_A           = 'LOC_ID_n_RANGE_H_A'
    LOC_RANGE_H                  = 'LOC_RANGE_H'
    LOC_RANGE_H_A                = 'LOC_RANGE_H_A'
    PICKED_DATA_H_A              = 'PICKED_DATA_H_A'
    PICKED_DATA_H__CHILD_H_A     = 'PICKED_DATA_H__CHILD_H_A'
    TEXT_H                       = 'TEXT_H'    
    TEXT_KEY_CKA                 = 'TEXT_KEY_CKA'                    # CKA = Composite Key Array
    TEXT_VALUE                   = 'TEXT_VALUE'
      
}
END {}


self.myself_name = File.basename( $0 )

self.cmdln_option_H = { :rep_num           => 2,
                        :res_num           => nil,
                        :res_faft          => nil,
                        :update            => false,
                        :do_only_n         => nil,
                     }
OptionParser.new do | option |
    option.banner = "Usage: #{self.myself_name} [ options ]"
    option.on( "--location-title x", "ONLY display the AS Location Title using the InMagic Location 'x'" ) do | opt_arg |
        puts get_location_title( { 'LOC_ID' => opt_arg } )
        exit
    end
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do | opt_arg |
        self.cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )." ) do | opt_arg |
        self.cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "--res-faft x", "Resource's K.Filing_Aid_Filing_Title ( required )" ) do | opt_arg |
        cmdln_option_H[ :res_faft ] = opt_arg.strip.downcase
    end
    option.on( "--update", "Do updates." ) do | opt_arg |
        self.cmdln_option_H[ :update ] = true
    end
    option.on( "--do_only n", OptionParser::DecimalInteger, "Stop after n TC's are 'stored', --update needs to set to actually update." ) do | opt_arg |
        self.cmdln_option_H[ :do_only_n ] = opt_arg.to_i
    end
    option.on( "-1", "Stop after 1 TC's is 'stored', --update needs to set to actually update." ) do | opt_arg |
        self.cmdln_option_H[ :do_only_n ] = 1
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
if ( self.cmdln_option_H[ :res_faft ].nil? ) then
    SE.puts "The --res-faft option is required."
    raise
end

aspace_O = ASpace.new
aspace_O.allow_updates=self.cmdln_option_H.fetch( :update )
self.rep_O     = Repository.new( aspace_O, self.cmdln_option_H.fetch( :rep_num ) )
self.res_O     = Resource.new( self.rep_O, self.cmdln_option_H.fetch( :res_num ) )
self.res_buf_O = self.res_O.new_buffer.read
aspace_O.validate_resource_faft( self.res_buf_O, self.cmdln_option_H[ :res_faft ] )

#    The 'source_data...' variables hold all the AO that contain locations.  
source_data_H_H = {}   # Indexed by the AO URI.

self.ala_id_0 = "_#{self.res_buf_O.record_H.fetch( K.id_0 ).sub( /^inmagic /i, '' ).gsub( /\s+/, '_' )}_"
source_data_H = get_loc_from_ao( self.res_buf_O.record_H )
if ( source_data_H.not_empty? ) then
    source_data_H_H[ self.res_buf_O.record_H.fetch( K.uri ) ] = source_data_H
end

ao_query_O = AO_Query_of_Resource.new( resource_O: self.res_O, get_full_ao_record_TF: true )
ao_query_O.record_H_A.each do | record_H |
    source_data_H = get_loc_from_ao( record_H )
    if ( source_data_H.not_empty? ) then
        source_data_H_H[ record_H.fetch( K.uri ) ] = source_data_H
    end
end
SE.q {'source_data_H_H.length'}

SE.puts "#{source_data_H_H.length} AO's with locations."
if ( source_data_H_H.empty? ) then
    puts "Nothing to do."
    exit
end

print__aoz_having_locations( source_data_H_H )
#SE.q {'source_data_H_H'}

tc_query_O = TC_Query_of_Resource.new( ao_query_O )
tc_data_H_H = {}
#    The 'picked_data...' variables hold all the specific AO that were used.  There's a hierarchy of AO's, so 
#    a TC might match multiple source AO, but only the closest one (up the hierarchy chain) will be used.
picked_data_H_A_H = {}        # Also indexed by AO URI.
container_loc_uri__by_title_H = {}
ao_query_O.record_H_A.each do | ao_record_H |
    instance_H_A = ao_record_H.fetch( K.instances )
    next if instance_H_A.nil? || instance_H_A.empty?        # No top container for ao

    picked_data_H_A_H[ ao_record_H.fetch( K.uri ) ] = 
        Array.new( instance_H_A.length ) { K.undefined }    # Array of instances
    
    ao_uri = ao_record_H.fetch( K.uri )
    hierarchy_uri_A = [ ao_uri ]     # <<< Include current record
    ao_record_H.fetch( K.ancestors ).each do | ancestor | 
        ref = ancestor[ K.ref ]
        hierarchy_uri_A.push( ref )
    end
    SE.q {'hierarchy_uri_A'} if ( $DEBUG )
    instance_H_A.each_with_index do | instance_H, instance_idx |
        next if ( instance_H.has_no_key?( K.sub_container ) ) #Digital objects don't have sub-containers...
        tc_uri = instance_H.fetch( K.sub_container ).fetch( K.top_container).fetch( K.ref )
        tc_record_H = tc_query_O.record_H__of_uri( tc_uri )
        raise "tc_record_H.nil?" if tc_record_H.nil?
        type_indicator_lit = "#{tc_record_H.fetch( K.type )} #{tc_record_H.fetch( K.indicator )}"         
        picked_data_H = {}
        picked_data_H[ LOC_DATA_H ] = {}
        catch( :done ) do
            throw :done if ( tc_record_H.fetch( K.indicator ).downcase == 'unk' ) 
            hierarchy_uri_A.each do | hierarchy_uri |     
                SE.q {'hierarchy_uri'} if ( $DEBUG )
                if source_data_H_H.has_key?( hierarchy_uri ) 
                    SE.q {'picked_data_H'} if ( $DEBUG )
                    source_data_H      = source_data_H_H.fetch( hierarchy_uri )
                    loc_id_n_range_H_A = source_data_H.fetch( LOC_DATA_H ).fetch( LOC_ID_n_RANGE_H_A )
                    loc_id_n_range_H_A.each do | loc_id_n_range_H | 
                        SE.q {'loc_id_n_range_H'} if ( $DEBUG )           
                        loc_range_H_A = loc_id_n_range_H.fetch( LOC_RANGE_H_A )
                        if ( loc_range_H_A.empty? ) then
                            range_H_A = nil
                        else
                            indicator = tc_record_H.fetch( K.indicator ).strip.downcase 
                            indicator.sub!( /\s+\[.*?\]$/, '' )     # Skip the resource locations if
                            indicator_MO = $~                       # the TC's indicator has the RGn:Sn qualifiers
                                                                    # as the RG record or Series record should have
                                                                    # the location data.
                            next if ( indicator_MO && source_data_H.fetch( K.uri ).include?( "/#{RESOURCES}/" ) )
                            case true
                            when ( indicator.count( '-' ) == 1 )
                                arr = indicator.split( '-' ).map( &:strip )
                                if ( arr.length == 2 && arr[ 0 ].integer? && arr[ 1 ].integer? ) then
                                    indicator_as_range = arr[ 0 ].to_i .. arr[ 1 ].to_i
                                else
                                    indicator_as_range = arr[ 0 ] .. arr[ 1 ]
                                end
                            when ( indicator.integer? ) 
                                indicator_as_range = indicator.to_i .. indicator.to_i
                            else
                                indicator_as_range = indicator .. indicator
                            end
                            container_type = tc_record_H.fetch( K.type ).downcase
                            range_H_A = loc_range_H_A.select { | range_H | 
                                                                 range_H.has_key?( container_type ) && 
                                                                 range_H.fetch( container_type )
                                                                        .cover?( indicator_as_range ) }

                        end
                        SE.q {'picked_data_H'} if ( $DEBUG )
                        if ( picked_data_H.fetch( LOC_DATA_H ).empty? ) then
                            picked_data_H[ TEXT_H ] = source_data_H.fetch( LOC_DATA_H ).fetch( TEXT_H )
                            picked_data_H[ K.uri ]  = hierarchy_uri
                            case
                            when ( range_H_A.nil? )       # This means there was NO range.
                                picked_data_H[ LOC_DATA_H ][ LOC_ID ]                      = loc_id_n_range_H.fetch( LOC_ID )
                                picked_data_H[ LOC_DATA_H ][ LOC_RANGE_H ]                 = {}   
                                picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_ERROR_NOTE ] = ''.dup
                                picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_A ]          = [] 
                            when ( range_H_A.empty? )     # This means there was a range, but NO match.
                                next
                            when ( range_H_A.not_empty?)  # This means there was a match on the range.
                                picked_data_H[ LOC_DATA_H ][ LOC_ID ]                      = loc_id_n_range_H.fetch( LOC_ID )
                                picked_data_H[ LOC_DATA_H ][ LOC_RANGE_H ]                 = range_H_A.first.cbv
                                picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_ERROR_NOTE ] = ''.dup
                                picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_A ]          = []                                
                            else
                                raise "I should never be here..."
                            end
                            SE.q {'picked_data_H'} if ( $DEBUG )
                        else                            
                           #SE.q {'picked_data_H'} if ( $DEBUG )
                            if ( picked_data_H[ LOC_DATA_H ].has_no_key?( LOC_ID ) )  then
                                raise "picked_data_H[ LOC_DATA_H ].has_no_key?( LOC_ID )"
                            end     
                            if ( picked_data_H[ LOC_DATA_H ][ LOC_ID ] == loc_id_n_range_H.fetch( LOC_ID ) ) then                                
                                next   # This is a hit on the same location that already exists, so ignore it..
                            end
                            if ( picked_data_H.fetch( LOC_DATA_H ).fetch( LOC_RANGE_H ).not_empty? &&
                               ( range_H_A.nil? || range_H_A.empty? ) ) then
                                next   # If we already HAVE a range location, then a non range location can be ignored.
                            end
                            
                            error_note = picked_data_H.fetch( LOC_DATA_H ).fetch( INVALID_LOCATION_ERROR_NOTE )                                                     
                            if ( picked_data_H[ LOC_DATA_H ][ LOC_ID ] == INVALID_LOCATION ) then
                                if ( range_H_A.nil? || range_H_A.empty? ) then
                                    next
                                end
                            else    
                                # Save the original location, the rest of the hits go into the error_note
                                loc_id = picked_data_H[ LOC_DATA_H ][ LOC_ID ]  
                                error_note << "Multiple matches: #{loc_id}"
                                if ( picked_data_H.fetch( LOC_DATA_H ).fetch( LOC_RANGE_H ).not_empty? ) then
                                    loc_range = picked_data_H[ LOC_DATA_H ][ LOC_RANGE_H ]                                            
                                    error_note << " #{loc_range}"
                                    picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_A ] = [ MULTIPLE_MATCHES, DUPLICATE_RANGES ]
                                else
                                    picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_A ] = [ MULTIPLE_MATCHES, DUPLICATE_LOCATIONS ]
                                end
                                picked_data_H[ LOC_DATA_H ][ LOC_ID ]           = INVALID_LOCATION
                                picked_data_H[ LOC_DATA_H ][ LOC_RANGE_H ]      = {}
                            end
                                                                                    
                            loc_id = loc_id_n_range_H.fetch( LOC_ID )
                            error_note << "; #{loc_id}"
                            if ( range_H_A.not_nil? && range_H_A.not_empty? ) then
                                error_note << " #{range_H_A.join( ',' )}"
                            end

                            puts "#{SE.lineno}: =============================="
                            print "ERROR: #{INVALID_LOCATION} "
                            print "#{picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_A ].join( ', ' )}"
                            puts ''
                            print "       "
                            print "AO URI: #{ao_uri.trailing_digits}, "
                            print "SOURCE AO URI: #{picked_data_H.fetch( K.uri ).trailing_digits}, "
                            print "TC URI: #{tc_record_H.fetch( K.uri ).trailing_digits}, `#{type_indicator_lit}`"
                            puts ''
                            puts "   Note: #{error_note}"
                            puts ''
                           #SE.q {'picked_data_H'} if ( $DEBUG )
                            throw :done 
                        end # of if                   
                    end # each range                
                end # of if           
            end # of hierarchy loop
            SE.q {'picked_data_H'} if ( $DEBUG )            
        end
     
        raise "picked_data_H.has_no_key?( LOC_DATA_H )" if ( picked_data_H.has_no_key?( LOC_DATA_H ) )
 
        if ( picked_data_H[ LOC_DATA_H ].empty? )
            picked_data_H[ LOC_DATA_H ][ LOC_ID ]      = NO_LOCATION
            picked_data_H[ LOC_DATA_H ][ LOC_RANGE_H ] = {}  
            picked_data_H[ TEXT_H ]                    = {}
            picked_data_H[ K.uri ]                     = ao_uri               
        end

#                                              [ CONTAINER_LOC_TITLE ] & [ CONTAINER_LOC_URI ] are set    
        loc_uri   = set_location( picked_data_H[ LOC_DATA_H ], container_loc_uri__by_title_H )    
        
        loc_id    = picked_data_H[ LOC_DATA_H ].fetch( LOC_ID ).cbv
        loc_range = picked_data_H[ LOC_DATA_H ].fetch( LOC_RANGE_H ).cbv
        if ( loc_uri == CREATE_ALA_LOCATION ) then
            case true         
            when loc_id.match?( /#{K.smcc_loc_id_RES}/i )  # This won't match NO_LOCATION or INVALID_LOCATION
                error_note = picked_data_H.fetch( LOC_DATA_H ).fetch( INVALID_LOCATION_ERROR_NOTE )
                if ( loc_id.include?( '-' ) ) then                                                                                                           
                    error_note << "Range location:"                    
                    picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_A ] = [ RANGE_LOCATION, loc_id ].cbv
                else
                    error_note << "Missing location:"                    
                    picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_A ] = [ MISSING_LOCATION, loc_id ].cbv
                end
                error_note << " #{loc_id}"
                if ( loc_range.not_empty? ) then                                       
                    error_note << " #{loc_range}"
                end
                picked_data_H[ LOC_DATA_H ][ LOC_ID ]      = INVALID_LOCATION
                picked_data_H[ LOC_DATA_H ][ LOC_RANGE_H ] = {}                  

                puts "#{SE.lineno}: =============================="
                print "ERROR: #{INVALID_LOCATION} "
                print "#{picked_data_H[ LOC_DATA_H ][ INVALID_LOCATION_A ].join( ', ' )}"
                puts ''
                print "       "
                print "AO URI: #{ao_uri.trailing_digits}, "
                print "SOURCE AO URI: #{picked_data_H.fetch( K.uri ).trailing_digits}, "
                print "TC URI: #{tc_record_H.fetch( K.uri ).trailing_digits}, `#{type_indicator_lit}`"
                puts ''
                puts "   Note: #{error_note}"
                puts ''
                
                set_location( picked_data_H[ LOC_DATA_H ], container_loc_uri__by_title_H ) 
                
            when picked_data_H[ LOC_DATA_H ][ LOC_ID ].not_in?( NO_LOCATION, INVALID_LOCATION ) 
                SE.puts "#{SE.lineno}: =============================="
                SE.puts "Not sure how I'm here..."
                SE.q {'loc_id'}
                SE.q {'picked_data_H'}
                raise
            end
        end
        SE.q {'picked_data_H'} if ( $DEBUG )
        tc_data_H = tc_data_H_H[ tc_uri ] ||= { K.type              => tc_record_H.fetch( K.type ).downcase,
                                                K.indicator         => tc_record_H.fetch( K.indicator ),
                                                PICKED_DATA_H_A     => [ ],
                                               }.cbv
        tc_data_H__picked_data_H = tc_data_H.fetch( PICKED_DATA_H_A ).find { | already_picked_data_H | 
            already_picked_data_H.fetch( LOC_DATA_H ) == picked_data_H.fetch( LOC_DATA_H ) } || begin                               
                if ( picked_data_H.has_no_key?( TEXT_H ) ) then
                    SE.puts "#{SE.lineno}: =============================="
                    SE.puts "picked_data_H.has_no_key?( TEXT_H )"
                    SE.q {'picked_data_H'}
                    SE.q {'tc_data_H'}
                    raise
                end
                tc_data_H[ PICKED_DATA_H_A ] << { LOC_DATA_H               => picked_data_H.fetch( LOC_DATA_H ),
                                                  PICKED_DATA_H__CHILD_H_A => {}, 
                                                  TEXT_H                   => picked_data_H.fetch( TEXT_H )
                                                  }                                                           
                tc_data_H.fetch( PICKED_DATA_H_A ).last    # This is needed because the '<<' OR '.push" returns the entire array                                          
            end
        SE.q {'tc_data_H__picked_data_H'} if ( $DEBUG )
        if ( picked_data_H.fetch( K.uri ).blank? ) then
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "picked_data_H.fetch( K.uri ).blank?" 
            SE.q {'picked_data_H'}
            raise
        end
        SE.q {'picked_data_H.fetch( K.uri )'} if ( $DEBUG )
        tc_data_H__picked_data_H[ PICKED_DATA_H__CHILD_H_A ][ picked_data_H.fetch( K.uri ) ] ||= []
                 
        new_child_H = { K.uri      => ao_uri,
                        K.instance => instance_idx,
                       }.cbv
        picked_data_H_A_H[ ao_uri ][ instance_idx ] = picked_data_H    
        bool = tc_data_H__picked_data_H.fetch( PICKED_DATA_H__CHILD_H_A )
                                       .fetch( picked_data_H.fetch( K.uri ) ).find { | child_H | 
            child_H.fetch( K.uri ) == new_child_H.fetch( K.uri ) } 
        if bool then 
            puts "#{SE.lineno}: =============================="
            puts "WARNING: AO has more than one reference to TC: #{tc_data_H.fetch( K.type )} #{tc_data_H.fetch( K.indicator )} "
            puts "Offending AO: uri=#{new_child_H.fetch( K.uri ).trailing_digits}, instance_idx=#{new_child_H.fetch( K.instance )}" 
            puts ''
        end 
        tc_data_H__picked_data_H[ PICKED_DATA_H__CHILD_H_A ][ picked_data_H.fetch( K.uri )] << new_child_H   

    SE.q {'tc_data_H'} if ( $DEBUG )             
    end
end

SE.puts "#{tc_data_H_H.length} TC records."
print__tcz_locations( tc_data_H_H, tc_query_O, ao_query_O )
#SE.q {'tc_data_H_H'}

tc_to_skip_A = []
tc_data_H_H.each_pair do | tc_uri, tc_data_H |
    picked_data_H_A = tc_data_H.fetch( PICKED_DATA_H_A )
    if ( picked_data_H_A.empty? ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "tc_data_H.fetch( PICKED_DATA_H_A ).empty?"
        SE.q {['tc_uri', 'tc_data_H']}
        raise
    end

    cnt = picked_data_H_A.count { | picked_data_H | 
                                    picked_data_H.fetch( LOC_DATA_H )
                                                 .fetch( LOC_ID )
                                                 .not_in?( NO_LOCATION, DUPLICATE_LOCATIONS, INVALID_LOCATION ) }
    if ( cnt > 0 ) then #We have an actual location, so delete the NO_LOCATION location.   A NO_LOCATION
                        #can get into the table if a box is located under two different hyerachies,
                        #one with a location and one with-out.   
        picked_data_H_A.map! do | picked_data_H |
            loc_id = picked_data_H.fetch( LOC_DATA_H ).fetch( LOC_ID )
            if ( loc_id.in?( NO_LOCATION ) ) then
               puts "#{tc_data_H.fetch( K.type )} #{tc_data_H.fetch( K.indicator )} `#{tc_uri.trailing_digits}` NO_LOCATION dropped."
               picked_data_H = {}     #THIS WORKS, ONLY because of 'next picked_data_H' below.
            end
            next picked_data_H        #map! is expecting something back for EACH iteration of the loop. 
                                      #Without 'next picked_data_H', the value of the last statement is the  
                                      #return value; which is the if statement IF IT'S FALSE.
        end
    end
    picked_data_H_A.delete_if { | picked_data_H | picked_data_H.empty? }
    next if ( picked_data_H_A.empty? )

    arr = tc_data_H_H.fetch( tc_uri ).fetch( PICKED_DATA_H_A )
                                     .map { | picked_data_H |  picked_data_H.fetch( LOC_DATA_H ).fetch( LOC_ID ) } 
                                     .uniq
    if ( arr.length > 1 ) then
        picked_data_H_A << { LOC_DATA_H => { LOC_ID      => DUPLICATE_LOCATIONS,      
                                             LOC_RANGE_H => {},
                                            },
                             PICKED_DATA_H__CHILD_H_A => {},              
                             TEXT_H                   => {},
                             K.uri                    => nil,                                            
                            }.cbv      
        set_location( picked_data_H_A.last[ LOC_DATA_H ], container_loc_uri__by_title_H ) 
        puts "#{tc_data_H.fetch( K.type )} #{tc_data_H.fetch( K.indicator )} `#{tc_uri.trailing_digits}` #{DUPLICATE_LOCATIONS}"
    end
    
    cnt = picked_data_H_A.count { | picked_data_H | picked_data_H.fetch( LOC_DATA_H ).fetch( LOC_ID ) == NO_LOCATION }                                                                           
    if ( cnt > 1 ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "count ( NO_LOCATION ) > 1"
        SE.q {['tc_uri', 'tc_data_H']}
        raise
    end
    cnt = picked_data_H_A.count { | picked_data_H | picked_data_H.fetch( LOC_DATA_H ).fetch( LOC_ID ) == INVALID_LOCATION }                                                                           
    if ( cnt > 1 ) then
       #SE.puts "#{SE.lineno}: =============================="
       #SE.puts "count ( INVALID_LOCATION ) > 1"
       #SE.q {['tc_uri', 'tc_data_H']}
       #raise
    end
    cnt = picked_data_H_A.count { | picked_data_H | picked_data_H.fetch( LOC_DATA_H ).fetch( LOC_ID ) == DUPLICATE_LOCATIONS }                                                                           
    if ( cnt > 1 ) then
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "count ( DUPLICATE_LOCATIONS ) > 1"
        SE.q {['tc_uri', 'tc_data_H']}
        raise
    end
        
end        

#   Loop TC's and verify we can find all the assigned locations

tc_to_update_A = []
picked_uri_A = []      # AO's actually used in TC's.
new_ALA_location_H__loc_data_H_A = {}
tc_data_H_H.each_pair do | tc_uri, tc_data_H |
    next if ( tc_data_H.fetch( PICKED_DATA_H_A ).empty? )
    tc_data_H.fetch( PICKED_DATA_H_A ).each do | picked_data_H |
        loc_data_H = picked_data_H.fetch( LOC_DATA_H )
        if (  loc_data_H.has_no_key?( CONTAINER_LOC_URI )   || loc_data_H.fetch( CONTAINER_LOC_URI ).blank? ||
              loc_data_H.has_no_key?( CONTAINER_LOC_TITLE ) || loc_data_H.fetch( CONTAINER_LOC_TITLE ).blank? ) then
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "loc_data_H.has_no_key?( CONTAINER_LOC_URI )   || loc_data_H.fetch( CONTAINER_LOC_URI ).blank? ||"
            SE.puts "loc_data_H.has_no_key?( CONTAINER_LOC_TITLE ) || loc_data_H.fetch( CONTAINER_LOC_TITLE ).blank?"
            SE.q {'loc_data_H'}
            SE.q {'picked_data_H'}
            SE.q {'tc_uri'}
            SE.q {'tc_data_H'}
            raise
        end
        if ( loc_data_H.fetch( CONTAINER_LOC_URI ) == CREATE_ALA_LOCATION ) then
            new_ALA_location_key_H = { LOC_ID             => loc_data_H.fetch( LOC_ID ), 
                                       INVALID_LOCATION_A => loc_data_H.fetch( INVALID_LOCATION_A, [] ),
                                      }         
            new_ALA_location_H__loc_data_H_A[ new_ALA_location_key_H ] ||= []            
            new_ALA_location_H__loc_data_H_A[ new_ALA_location_key_H ] << loc_data_H   
        end
        picked_uri_A.concat( picked_data_H.fetch( PICKED_DATA_H__CHILD_H_A ).keys )
        picked_uri_A.uniq!
        
        tc_record_H = tc_query_O.record_H__of_uri( tc_uri )  
        container_locations_H_A = tc_record_H.fetch( K.container_locations )
        cnt_of_non_ala_container_loc = container_locations_H_A.count {      
            | container_location | not ( container_location[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER}/i ) || 
                                         container_location[ K.start_date ].to_s == ALA_START_DATE ) } 
        if ( cnt_of_non_ala_container_loc > 0 ) then
            SE.puts "#{tc_record_H.fetch( K.type )} #{tc_record_H.fetch( K.indicator )} `#{tc_uri.trailing_digits}` Non ALA container_location found."
            tc_to_skip_A << tc_uri if ( tc_to_skip_A.not_include?( tc_uri ) )
            next
        end
        ala_container_loc_already_there = container_locations_H_A.any? { 
            | container_location | container_location.fetch( K.ref ) == loc_data_H.fetch( CONTAINER_LOC_URI ) }
        tc_to_update_A << tc_uri if ( ! ala_container_loc_already_there && tc_to_update_A.not_include?( tc_uri ) )
    end   
end

raise "tc_to_update_A.intersect?( tc_to_skip_A )" if tc_to_update_A.intersect?( tc_to_skip_A )
SE.q {['tc_data_H_H.length','tc_to_update_A.length','tc_to_skip_A.length']}
SE.q {'new_ALA_location_H__loc_data_H_A.length'}

if ( tc_to_update_A.empty? ) then
    SE.puts "Nothing to do."
    exit
end

unused_ao_location_A = source_data_H_H.keys - picked_uri_A
if ( unused_ao_location_A.not_empty? ) then
    print__aoz_with_unused_locations( source_data_H_H, unused_ao_location_A )
end

new_ALA_location_H__loc_data_H_A.each_pair do | new_ALA_location_key_H, loc_data_H_A | 
    record_H = Record_Format.new( :location ).record_H
    record_H[ K.building ]                   = ALA_PROBLEMS
    record_H[ K.classification ]             = self.ala_id_0
    record_H[ K.coordinate_1_label ]         = ERROR_LABEL 
    record_H[ K.coordinate_1_indicator ]     = new_ALA_location_key_H.fetch( LOC_ID )
    if ( new_ALA_location_key_H.fetch( LOC_ID ) == INVALID_LOCATION ) then
        if ( new_ALA_location_key_H.has_key?( INVALID_LOCATION_A ) and 
             new_ALA_location_key_H[ INVALID_LOCATION_A ].maxindex == 1 ) then
            record_H[ K.coordinate_2_label ]     = new_ALA_location_key_H[ INVALID_LOCATION_A ][ 0 ]
            record_H[ K.coordinate_2_indicator ] = new_ALA_location_key_H[ INVALID_LOCATION_A ][ 1 ]
        else
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "new_ALA_location_key_H[ INVALID_LOCATION_A ].maxindex != 1"
            SE.q {'new_ALA_location_key_H'}
            SE.q {'loc_data_H_A'}
            raise
        end
    end
    loc_buf_O = Location.new( self.rep_O ).new_buffer.create.load( record_H )
    loc_buf_O.store
    
    puts "Created location(#{loc_buf_O.uri_addr.trailing_digits})': #{get_location_title( new_ALA_location_key_H )}"
    if self.cmdln_option_H.fetch( :update )
        record_H = loc_buf_O.read.record_H
    end
        
    loc_data_H_A.each do | loc_data_H |
        raise "if ( loc_data_H.fetch( CONTAINER_LOC_URI ) != CREATE_ALA_LOCATION" if ( loc_data_H.fetch( CONTAINER_LOC_URI ) != CREATE_ALA_LOCATION )
        loc_data_H[ CONTAINER_LOC_URI ] = loc_buf_O.uri_addr
        if self.cmdln_option_H.fetch( :update ) then
            if record_H[ K.title ] != loc_data_H.fetch( CONTAINER_LOC_TITLE ) then
                SE.puts "#{SE.lineno}: =============================="
                SE.puts "record_H[ K.title ] != loc_data_H.fetch( CONTAINER_LOC_TITLE )"
                SE.q {'loc_data_H.fetch( CONTAINER_LOC_TITLE )'}
                SE.q {'record_H'}
                raise
            end
        end
    end
end

tc_to_update_A.each_with_index do | tc_uri, tc_uri_idx | 
    break if ( self.cmdln_option_H[ :do_only_n ].not_nil? && tc_uri_idx + 1 > self.cmdln_option_H[ :do_only_n ] )
    tc_data_H = tc_data_H_H.fetch( tc_uri )
    tc_buf_O__pre_AO_updates = Top_Container.new( self.res_O, tc_uri ).new_buffer.read
    raise "tc_buf_O__pre_AO_updates.nil?" if tc_buf_O__pre_AO_updates.nil?
    tc_record_H__pre_AO_updates = tc_buf_O__pre_AO_updates.record_H
    container_locations_H_A     = tc_record_H__pre_AO_updates.fetch( K.container_locations ).cbv  
    puts "TC: `#{tc_record_H__pre_AO_updates.fetch( K.uri ).trailing_digits}`, " +
         "#{tc_record_H__pre_AO_updates.fetch( K.type )} #{tc_record_H__pre_AO_updates.fetch( K.indicator )}"

#   Delete the NO_LOCATION link if present. If there's still no location, it will be added back.
    container_locations_H_A.delete_if { 
        | container_location_H | container_location_H[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER} #{NO_LOCATION}$/i ) || 
                                 container_location_H[ K.start_date ].to_s == ALA_START_DATE }                                      

    tc_data_H.fetch( PICKED_DATA_H_A ).each do | picked_data_H |  
        loc_data_H = picked_data_H.fetch( LOC_DATA_H )
        loc_id = loc_data_H.fetch( LOC_ID )
        container_location_note = "#{ALA_NOTE_MARKER} #{loc_id} "
        range = loc_data_H.fetch( LOC_RANGE_H )
        if ( range.not_empty? ) then
            container_location_note << " Range: #{range}"
        end

        if ( loc_data_H.fetch( INVALID_LOCATION_ERROR_NOTE, '' ).not_blank? ) then
            container_location_note << ": #{loc_data_H.fetch( INVALID_LOCATION_ERROR_NOTE )}"
        end
        
        if ( loc_id != NO_LOCATION ) then
            picked_note = "#{container_location_note} \n"
        end

        if ( tc_data_H.fetch( CONTAINER_LOC_NOTE, '' ).not_blank? ) then
            container_location_note << "; #{tc_data_H.fetch( CONTAINER_LOC_NOTE ) }"
        end
        
        if ( container_location_note.length > 250 ) then
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "container_location_note.length > 250"
            SE.puts "The database column is a varchar( 255 )"
            SE.puts ''
        end

        if loc_data_H.fetch( CONTAINER_LOC_URI ).in?( '', CREATE_ALA_LOCATION )
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "loc_data_H.fetch( CONTAINER_LOC_URI ).in?( '', CREATE_ALA_LOCATION )" 
            SE.q {'picked_data_H'}
            raise
        end
        cl_uri = loc_data_H.fetch( CONTAINER_LOC_URI )
        arr = container_locations_H_A.select { | cl_record_H | cl_record_H[ K.ref ] == cl_uri }
        case arr.length 
        when 0
            cl_record_H = Record_Format.new( :container_location ).record_H
            cl_record_H[ K.start_date ] = ALA_START_DATE
            cl_record_H[ K.ref ]        = cl_uri
            cl_record_H[ K.note ]       = container_location_note[ 0, 250 ]
            container_locations_H_A    << cl_record_H
        when 1
            cl_record_H           = arr.first  
            stringer              = "#{cl_record_H[ K.note ]} | #{container_location_note}" 
            cl_record_H[ K.note ] = stringer[ 0, 250 ]
        else
            SE.puts "#{SE.lineno}: =============================="
            SE.puts "container_locations_H_A.select { | cl_record_H | cl_record_H[ K.ref ] == cl_uri }.length > 1 }"
            SE.q {'tc_data_H'}
            SE.q {'tc_record_H__pre_AO_updates'}
            SE.q {'container_locations_H_A'}
            SE.q {'arr'}
            raise
        end    
     
        puts "CL: (#{container_locations_H_A.length}): Loc: `#{cl_uri.trailing_digits}`: #{container_location_note}"
        picked_data_H[ PICKED_DATA_H__CHILD_H_A ].each_key do | picked_uri |
            if ( picked_note.not_blank? && picked_uri[ 0 ] == '/' ) then
                if ( picked_uri == self.res_buf_O.record_H.fetch( K.uri ) ) then
                    ao_buf_O = self.res_buf_O.read   
                else
                    ao_buf_O = Archival_Object.new( self.res_O, picked_uri ).new_buffer.read
                end  
                picked_loc_text_CKA = picked_data_H.fetch( TEXT_H ).fetch( TEXT_KEY_CKA )
                picked_loc_text     = ao_buf_O.record_H.dig( *picked_loc_text_CKA )
                picked_loc_text.sub!( /^\<physloc\>: /, '' )              
                if ( picked_loc_text.not_include?( picked_note ) )
                    picked_loc_text.prepend( picked_note )       
                    ao_record_H = ao_buf_O.record_H
                    puts "AO: `#{ao_record_H.fetch( K.uri ).trailing_digits}` " + 
                         "#{ao_record_H.fetch( K.level )}: #{ao_record_H.fetch( K.title )[ 0,20 ]} " +
                         "#{ao_buf_O.record_H.dig( *picked_loc_text_CKA ).gsub(/([\r]*[\n])+/, " | ")}" +
                         ''  
                    ao_buf_O.store   #  THIS store changes the owning TC system-time !!!  
                                     #  which changes the 'lock_level'  
                end
            end
        end
    end 
    tc_buf_O__post_AO_updates = Top_Container.new( self.res_O, tc_uri ).new_buffer.read
    tc_record_H__post_AO_updates = tc_buf_O__post_AO_updates.record_H
    tc_record_H__post_AO_updates[ K.container_locations ] = container_locations_H_A
   #SE.q {'tc_record_H__post_AO_updates'}
    tc_buf_O__post_AO_updates.store
    puts ''
end











