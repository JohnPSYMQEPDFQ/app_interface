=begin

Reset the Series record sequence numbers.  

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
#SE.pom(aspace_O)
#SE.pov(aspace_O)
rep_O = Repository.new( aspace_O, rep_num )
#SE.pom(rep_O)
#SE.pov(rep_O)

res_O = Resource.new( rep_O, res_num )
series_uri_A = []
cnt = 0; Resource_Query.new( res_O ).record_H_A.each do | record_H |
    if ( ! record_H[ K.level ].in?( [ K.series, K.subseries ] ) ) then
        next
    end
    series_uri_A << record_H[ K.uri ]
    cnt += 1
    print "#{cnt} "
    print "#{record_H[ K.uri ]} "
    print "#{record_H[ K.position ]} "
    print "#{record_H[ K.level ]} "
    print "#{record_H[ K.title ]} "
    print "\n"
end

sequence_A = [ 0 ]
series_uri_A.each do | uri |
    puts ""
    ao_buf_O = Archival_Object.new(res_O, uri).new_buffer.read( )
    
    a1 = ao_buf_O.record_H[ K.title ].split( /^((Series|Subseries) \d+(\.\d+)* *: *)/i )
    if ( a1.maxindex == 0 ) then
        puts "Unable to find 'series' text in '#{ao_buf_O.record_H[ K.title]}'"
    end
    ancestors_maxindex = ao_buf_O.record_H[ K.ancestors ].maxindex
    until ( ancestors_maxindex == sequence_A.maxindex ) 
        if ( ancestors_maxindex > sequence_A.maxindex) then
            sequence_A << 0
        else
            sequence_A.pop( 1 )
        end
    end
    sequence_A[ ancestors_maxindex ] += 1
    
    old_title = ao_buf_O.record_H[ K.title ]

    stringer = ""
    case ao_buf_O.record_H[ K.level ] 
    when K.series
        stringer = "Series"
    when K.subseries
        stringer = "Subseries"
    else
        SE.puts "#{SE.lineno}: I shouldn't be here..."
        SE.pp ao_buf_O.record_H[ K.level ]
        raise
    end
    new_title = stringer + " " + sequence_A.join( '.' ) + ": " + a1[ a1.maxindex ] 

    puts "#{uri} #{ao_buf_O.record_H[ K.level ]}"
    if ( old_title == new_title ) then
        puts "Titles are the same, no change: '#{old_title}'"
        next
    end
#   SE.ap ao_buf_O.record_H
    puts "Old title: #{old_title}"
    ao_buf_O.record_H[ K.title] = new_title
    puts "New title: #{new_title}"
    ao_buf_O.store
end


