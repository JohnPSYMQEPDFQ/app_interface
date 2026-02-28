=begin

    

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
end.parse!  
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
rep_O = Repository.new( aspace_O, rep_num )
res_O = Resource.new( rep_O, res_num )
cnt = 0; AO_Query_of_Resource.new( resource_O: res_O ).record_H_A.each do | query_record_H |
    if ( ! query_record_H[ K.level ].in?( [ K.recordgrp ] ) ) then
        next
    end

    ao_buf_O = Archival_Object.new( res_O, query_record_H[ K.uri ] ).new_buffer.read( )
    cnt += 1
    print "#{cnt} "
    print "ao #{ao_buf_O.record_H[ K.uri ].trailing_digits} "
    print "#{ao_buf_O.record_H[ K.ancestors ].length} "
    print "#{ao_buf_O.record_H[ K.level ]} "
    print "#{ao_buf_O.record_H[ K.title ]}, "
  
    if ( ao_buf_O.record_H[ K.ancestors ].length > 1 ) then
        ao_buf_O.record_H[ K.level ]       = K.otherlevel
        ao_buf_O.record_H[ K.other_level ] = K.group.capitalize
        ao_buf_O.store
    else
        print "SKIPPED\n"
    end
end


