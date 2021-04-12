=begin

Abbreviations,  AO = archival object (Everything's an AO, but there's also uri "archive_objects". It's confusing...)
                AS = ArchivesSpace
                IT = instance type
                TC = top container
                SC = Sub-container
                _H = Hash
                _A = Array
                _I = Index(of Array)
                _O = Object
               _0R = Zero Relative


=end

require 'json'
require 'pp'
require 'optparse'

require 'class.Array.extend.rb'
require 'class.String.extend.rb'
require 'class.Hash.extend.rb'
require 'module.SE.rb'
require 'class.Archivesspace.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.Location.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )
api_uri_base = "http://localhost:8089"

cmdln_option = { :repository_num => 2  ,
                 :resource_num => nil  ,
                 :filter => false }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} --res-num n [res] [(ao|tc) n,n,...]..."
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ :repository_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )" ) do |opt_arg|
        cmdln_option[ :resource_num ] = opt_arg
    end
    option.on( "--filter", "apply-read-filter" ) do |opt_arg|
        cmdln_option[ :filter ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )
#SE.pom(aspace_O)
#SE.pov(aspace_O)
 
record_filter_B = cmdln_option[ :filter ] 
if ( cmdln_option[ :repository_num ] ) then
    repository_num = cmdln_option[ :repository_num ]
    rep_O = Repository.new( aspace_O, repository_num )
else
    SE.puts "The --rep-num option is required."
    raise
end
if ( cmdln_option[ :resource_num ] ) then
    resource_num = cmdln_option[ :resource_num ]
    res_buf_O = Resource.new( rep_O, resource_num ).new_buffer.read ( record_filter_B )
end

#SE.pom(rep_O)
#SE.pov(rep_O)

current_record_type = K.undefined
ARGV.push('res') if (ARGV.empty?)
ARGV.each do | element | 
    if ( element.in? [ 'ao', 'tc' ]) then
        if ( not res_buf_O ) then
            SE.puts "The --res-num option is required."
            raise
        end
        current_record_type = element
        next
    end
    if ( element == 'res' ) then
        if ( not res_buf_O ) then
            SE.puts "The --res-num option is required."
            raise
        end
        current_record_type = element
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
        puts "Resource: #{resource_num}:"
        puts res_buf_O.record_H.ai
    when 'ao'
        puts "Archival_Object: #{element}:"
        ao_buf_O = Archival_Object.new( res_buf_O, element ).new_buffer.read( record_filter_B )
        puts ao_buf_O.record_H.ai
    when 'tc'
        puts "Top_Container: #{element}:"
        tc_buf_O = Top_Container.new( res_buf_O, element ).new_buffer.read( record_filter_B )
        puts tc_buf_O.record_H.ai
    when 'loc'
        puts "Location: #{element}:"
        ao_buf_O = Location.new( aspace_O, element ).new_buffer.read( record_filter_B )
        puts ao_buf_O.record_H.ai
    else
        puts "Unknown record_type: #{current_record_type}"
    end 
end

