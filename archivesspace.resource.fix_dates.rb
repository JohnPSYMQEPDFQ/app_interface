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

raise "Add 'circa' logic to dates"

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
AO_Query_of_Resource.new( res_O ).record_H_A.each do | record_H |
    record_cnt += 1
    if ( ! ( record_H.key?( K.dates ) and record_H[ K.dates ].length > 0 )) then
        next
    end

    index_image =  ""
    index_image += "#{record_H[ K.uri ].sub( /.*\//, "")} "
    index_image += "#{record_H[ K.title ]} "

    ao_buf_O = Archival_Object.new(res_O, record_H[ K.uri ] ).new_buffer.read( )
#   SE.puts "URI=#{record_H[ K.uri ]}" 

    before_image = ""
    before_image += "#{record_H[ K.uri ].sub( /.*\//, "")} "
    before_image += "#{record_H[ K.title ]} "
    
    after_image = before_image + ""
    
    changed = false
    date_cnt = 0
    ao_buf_O.record_H[ K.dates ].each_index do | idx |
        date_cnt += 1
        change_type = [ " "," "," "," " ]
        before_image += "#{change_type.join(" ")} #{ao_buf_O.record_H[ K.dates ][ idx]}"
        if ( ao_buf_O.record_H[ K.dates ][ idx][ K.label ] != K.creation ) then
            ao_buf_O.record_H[ K.dates ][ idx][ K.label ] = K.creation
            changed= true
            change_type[ 0 ] = "0"
        end
        if (    ao_buf_O.record_H[ K.dates ][ idx].key?( K.begin ) and
                ao_buf_O.record_H[ K.dates ][ idx][ K.begin] != "" and
                ao_buf_O.record_H[ K.dates ][ idx][ K.date_type ] == K.single
            ) then
            ao_buf_O.record_H[ K.dates ][ idx][ K.date_type ]  = K.inclusive
            ao_buf_O.record_H[ K.dates ][ idx][ K.end ] = ao_buf_O.record_H[ K.dates ][ idx][ K.begin ]
            ao_buf_O.record_H[ K.dates ][ idx][ K.expression ] = aspace_O.format_date_expression( ao_buf_O.record_H[ K.dates ][ idx][ K.begin ] )
            changed = true
            change_type[ 1 ] = "1"
        elsif ( ao_buf_O.record_H[ K.dates ][ idx].key?( K.begin ) and ao_buf_O.record_H[ K.dates ][ idx].key?( K.end ) ) then
            stringer = aspace_O.format_date_expression( ao_buf_O.record_H[ K.dates ][ idx][ K.begin ], ao_buf_O.record_H[ K.dates ][ idx][ K.end ] )
            if  (ao_buf_O.record_H[ K.dates ][ idx].key?( K.expression )) then
                if  (ao_buf_O.record_H[ K.dates ][ idx][ K.expression ] != stringer) then
                    ao_buf_O.record_H[ K.dates ][ idx][ K.expression ] = stringer
                    ao_buf_O.record_H[ K.dates ][ idx][ K.date_type ]  = K.inclusive
                    changed = true
                    change_type[ 2 ] = "2"    
                end
            else
                ao_buf_O.record_H[ K.dates ][ idx][ K.expression ] = stringer
                ao_buf_O.record_H[ K.dates ][ idx][ K.date_type ]  = K.inclusive
                changed = true
                change_type[ 3 ] = "3"
            end
        end
        after_image  += "#{change_type.join(" ")} #{ao_buf_O.record_H[ K.dates ][ idx]}"
    end
    next if ( ! changed )

    update_cnt += 1
        
#   puts "#{update_cnt} #{date_cnt} #{record_cnt} #{index_image}"
    puts "#{update_cnt} #{date_cnt} #{record_cnt} #{before_image}"
    puts "#{update_cnt} #{date_cnt} #{record_cnt} #{after_image}"
    puts ""
    ao_buf_O.store
end


