# frozen_string_literal: true

=begin

    Loop through all the dates of a given resource and change specific errors.
    BTW, the "expression" field is filled-in by AS someplace...
    
=end

require 'json'
require 'optparse'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option = { :rep_num => 2  ,
                 :res_num => nil ,
                 :update => false ,
                }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )" ) do |opt_arg|
        cmdln_option[ :res_num ] = opt_arg
    end
    option.on( "--update", "Do updates" ) do |opt_arg|
        cmdln_option[ :update ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV
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

aspace_O = ASpace.new
aspace_O.date_expression_format    = 'mmmddyyyy'
aspace_O.date_expression_separator = ' - '
aspace_O.allow_updates             = cmdln_option[ :update ]

rep_O = Repository.new( aspace_O, rep_num )
res_O = Resource.new( rep_O, res_num )

update_cnt = 0
record_cnt = 0
date_cnt = 0    
AO_Query_of_Resource.new( res_O ).index_H_A.each do | index_H |
    record_cnt += 1
    if ( ! ( index_H.key?( K.dates ) and index_H[ K.dates ].length > 0 )) then
        next
    end

    before_image = +''
    before_image << "#{index_H[ K.uri ].trailing_digits} "
    before_image << "#{index_H[ K.title ]} "
    
    after_image = before_image + ''

    ao_buf_O = nil
    index_H[ K.dates ].tap do | ao_dates_A |
        ao_dates_A.each_index do | idx |
            date_cnt += 1
            ao_dates_A[ idx ].tap do | ao_date |
                if ( ao_date.has_no_key?( K.begin ) ) then
                    puts "#{update_cnt},#{date_cnt},#{record_cnt}:#{before_image}: No 'begin' date: #{ao_date}"
                end                   
                change_type = [ ' ',' ',' ',' ' ]
                if ( ao_date[ K.label ] != K.creation ) then
                    ao_buf_O = Archival_Object.new(res_O, index_H[ K.uri ] ).new_buffer.read if ( ao_buf_O.nil? )
                    before_image << "|#{change_type.join(' ')}| #{ao_buf_O.record_H[ K.dates ][ idx ]}"
                    ao_buf_O.record_H[ K.dates ][ idx ][ K.label ] = K.creation
                    change_type[ 0 ] = "C"
                end
                if ( ao_date[ K.type ] == K.single and ao_date.key?( K.begin ) ) then    # It's K.type in the INDEX but K.date_type in the AO record!!
                    ao_buf_O = Archival_Object.new(res_O, index_H[ K.uri ] ).new_buffer.read if ( ao_buf_O.nil? )
                    before_image << "|#{change_type.join(' ')}| #{ao_buf_O.record_H[ K.dates ][ idx ]}"
                    ao_buf_O.record_H[ K.dates ][ idx ][ K.date_type ]  = K.inclusive
                    ao_buf_O.record_H[ K.dates ][ idx ][ K.end ]        = ao_buf_O.record_H[ K.dates ][ idx ][ K.begin ]
                    stringer = aspace_O.format_date_expression( from_date: ao_buf_O.record_H[ K.dates ][ idx ][ K.begin ],
                                                                thru_date: ao_buf_O.record_H[ K.dates ][ idx ][ K.end ],
                                                                certainty: ao_buf_O.record_H[ K.dates ][ idx ][ K.certainty ] )
                    ao_buf_O.record_H[ K.dates ][ idx ][ K.expression ] = stringer
                    change_type[ 1 ] = "S"
                elsif ( ao_date.key?( K.begin ) and ao_date.key?( K.end ) ) then
                    stringer = aspace_O.format_date_expression( from_date: ao_date[ K.begin ], 
                                                                thru_date: ao_date[ K.end ],
                                                                certainty: '' )   # index_H doesn't have K.certainty !!
                    if  (ao_date.key?( K.expression ) and ao_date[ K.expression].not_blank? ) then
                        if  (ao_date[ K.expression ] != stringer) then
                            ao_buf_O = Archival_Object.new(res_O, index_H[ K.uri ] ).new_buffer.read if ( ao_buf_O.nil? )
                            before_image << "|#{change_type.join(' ')}| #{ao_buf_O.record_H[ K.dates ][ idx ]}"
                            stringer = aspace_O.format_date_expression( from_date: ao_buf_O.record_H[ K.dates ][ idx ][ K.begin ], 
                                                                        thru_date: ao_buf_O.record_H[ K.dates ][ idx ][ K.end ],
                                                                        certainty: ao_buf_O.record_H[ K.dates ][ idx ][ K.certainty ] )  
                            ao_buf_O.record_H[ K.dates ][ idx ][ K.expression ] = stringer
#                           ao_buf_O.record_H[ K.dates ][ idx ][ K.date_type ]  = K.inclusive  THIS WIPES OUT BULK!! 
                            change_type[ 2 ] = "E"    
                        end
                    else
                        ao_buf_O = Archival_Object.new(res_O, index_H[ K.uri ] ).new_buffer.read if ( ao_buf_O.nil? )
                        before_image << "|#{change_type.join(' ')}| #{ao_buf_O.record_H[ K.dates ][ idx ]}"
                        stringer = aspace_O.format_date_expression( from_date: ao_buf_O.record_H[ K.dates ][ idx ][ K.begin ], 
                                                                    thru_date: ao_buf_O.record_H[ K.dates ][ idx ][ K.end ],
                                                                    certainty: ao_buf_O.record_H[ K.dates ][ idx ][ K.certainty ] )  
                        ao_buf_O.record_H[ K.dates ][ idx ][ K.expression ] = stringer
#                       ao_buf_O.record_H[ K.dates ][ idx ][ K.date_type ]  = K.inclusive   THIS WIPES OUT BULK!! 
                        change_type[ 3 ] = "B"
                    end
                end
                after_image  << "|#{change_type.join(' ')}| #{ao_buf_O.record_H[ K.dates ][ idx ]}" if ( ao_buf_O.not_nil? )
            end
        end
    end
    next if ( ao_buf_O.nil? )

#   SE.puts "URI=#{index_H[ K.uri ]}" 
    update_cnt += 1
        
    puts "#{update_cnt},#{date_cnt},#{record_cnt}:#{before_image}"
    puts "#{update_cnt},#{date_cnt},#{record_cnt}:#{after_image}"
    puts ''
    ao_buf_O.store
end
SE.q {['record_cnt', 'update_cnt' ]}


