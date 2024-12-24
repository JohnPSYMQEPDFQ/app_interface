=begin

    Display a selection of AS record types.

=end

require 'optparse'
require 'class.Archivesspace.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.Location.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option = { :rep_num => 2  ,
                 :res_num => nil  ,
                 :filter => false }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} --res-num n [res] [(res|ao|tc|loc|index) n,n,...]..."
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )" ) do |opt_arg|
        cmdln_option[ :res_num ] = opt_arg
    end
    option.on( "--filter", "Apply read filter" ) do |opt_arg|
        cmdln_option[ :filter ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered

aspace_O = ASpace.new
 
record_filter_B = cmdln_option[ :filter ] 
if ( cmdln_option[ :rep_num ] ) then
    rep_num = cmdln_option[ :rep_num ]
    rep_O = Repository.new( aspace_O, rep_num )
else
    SE.puts "The --rep-num option is required."
    raise
end
if ( cmdln_option[ :res_num ] ) then
    res_num = cmdln_option[ :res_num ]
    res_O = Resource.new( rep_O, res_num )
    res_buf_O = res_O.new_buffer.read( record_filter_B )
end

#SE.pom(rep_O)
#SE.pov(rep_O)

res_query_O = nil
current_record_type = K.undefined
ARGV.push('res') if (ARGV.empty?)
ARGV.each do | element | 
    if ( element.in? [ 'res', 'ao', 'tc', 'index' ]) then
        if ( not res_buf_O ) then
            SE.puts "The --res-num option is required."
            raise
        end
        current_record_type = element
        next if ( element != 'res' )
    end
    if ( element == 'loc' ) then
        current_record_type = element
        next
    end
    if ( current_record_type == K.undefined ) then
        SE.puts "No record_type specified"
        raise
    end
    case current_record_type
    when 'res' 
        puts "Resource: #{res_num}:"
        puts res_buf_O.record_H.ai
    when 'ao'
        puts "Archival_Object: #{element}:"
        ao_buf_O = Archival_Object.new( res_buf_O, element ).new_buffer.read( record_filter_B )
        puts ao_buf_O.record_H.ai
    when 'index'
        puts "Index for: #{element}:"
        if ( res_query_O.nil? ) then
            res_query_O = Resource_Query.new( res_O )
        end
        puts res_query_O.get_record_H_of_uri_num( element ).ai
    when 'tc'
        puts "Top_Container: #{element}:"
        tc_buf_O = Top_Container.new( res_buf_O, element ).new_buffer.read( record_filter_B )
        puts tc_buf_O.record_H.ai
    when 'loc'
        puts "Location: #{element}:"
        loc_buf_O = Location.new( aspace_O, element ).new_buffer.read( record_filter_B )
        puts loc_buf_O.record_H.ai
    else
        puts "Unknown record_type: #{current_record_type}"
    end 
end

