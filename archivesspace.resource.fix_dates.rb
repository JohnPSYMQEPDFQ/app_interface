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
api_uri_base = "http://localhost:8089"

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
aspace_O.allow_updates = cmdln_option[ :update ]
aspace_O.api_uri_base  = api_uri_base
aspace_O.login( "admin", "admin" )

rep_O = Repository.new( aspace_O, rep_num )
res_O = Resource.new( rep_O, res_num )
cnt = 0; Resource_Query.new( res_O ).record_H_A.each do | record_H |
    if ( ! ( record_H.key?( K.dates ) and record_H[ K.dates ].length > 0 )) then
        next
    end
    fix = false
    record_H[ K.dates ].each do | date |
        fix = true if ( date[ K.label ] != K.creation ) 
        fix = true if ( date.key?( K.expression ) and ! date[ K.expression ].in?( [ "", "undated" ] ) )
        fix = true if ( date.key?( K.begin ) and date[ K.begin ] != "" and date[ K.begin ] == date[ K.end ] )
    end
    next if ( ! fix )
    cnt += 1
    print "#{cnt} "
    print "#{record_H[ K.uri ].sub( /.*\//, "")} "
    print "#{record_H[ K.title ]} "
    print record_H[ K.dates ].join( " " )
    print "\n"

    ao_buf_O = Archival_Object.new(res_O, record_H[ K.uri ] ).new_buffer.read( )
    print "#{cnt} "
    print "#{record_H[ K.uri ].sub( /.*\//, "")} "
    print "#{record_H[ K.title ]} "
    puts ao_buf_O.record_H[ K.dates ].join( " " )
   
    changed = false
    ao_buf_O.record_H[ K.dates ].each_index do | idx |
        if ( ao_buf_O.record_H[ K.dates ][ idx][ K.label ] != K.creation ) then
            ao_buf_O.record_H[ K.dates ][ idx][ K.label ] = K.creation
            changed= true
        end
        if (    ao_buf_O.record_H[ K.dates ][ idx].key?( K.begin ) and
                ao_buf_O.record_H[ K.dates ][ idx][ K.begin] != "" and
                ao_buf_O.record_H[ K.dates ][ idx][ K.begin ] == ao_buf_O.record_H[ K.dates ][ idx][ K.end ] 
            ) then
            ao_buf_O.record_H[ K.dates ][ idx][ K.date_type ]  = K.single
            ao_buf_O.record_H[ K.dates ][ idx].delete ( K.end )
            changed = true
        end
        if (    ao_buf_O.record_H[ K.dates ][ idx].key?( K.begin ) and
                ao_buf_O.record_H[ K.dates ][ idx][ K.begin] == ao_buf_O.record_H[ K.dates ][ idx][ K.expression ] 
            ) then
            ao_buf_O.record_H[ K.dates ][ idx][ K.expression ] = ""
            changed = true
        end
        if (    ao_buf_O.record_H[ K.dates ][ idx].key?( K.begin ) and
                ao_buf_O.record_H[ K.dates ][ idx].key?( K.end )
                "#{ao_buf_O.record_H[ K.dates ][ idx][ K.begin ]}-#{ao_buf_O.record_H[ K.dates ][ idx][ K.end ]}" == ao_buf_O.record_H[ K.dates ][ idx][ K.expression ] 
            ) then
            ao_buf_O.record_H[ K.dates ][ idx][ K.expression ] = ""
            changed = true
        end
    end
    raise "Nothing changed" if ( ! changed )
    print "#{cnt} "
    print "#{record_H[ K.uri ].sub( /.*\//, "")} "
    print "#{record_H[ K.title ]} "
    puts ao_buf_O.record_H[ K.dates ].join( " " )
    puts    
    ao_buf_O.store
end


