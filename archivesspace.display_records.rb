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
require 'module.Se.rb'
require 'class.Archivesspace.rb'
require 'class.ArchivesSpace.http_calls.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )
api_uri_base = "http://localhost:8089"

cmdln_option = { "repository-num" => 2  ,
                 "resource-num" => nil  ,
                 "filter" => false }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ] --resource-num n [res] [(ao|tc) n,n,...]..."
    option.on( "--repository-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option[ 'repository-num' ] = opt_arg
    end
    option.on( "--resource-num n", OptionParser::DecimalInteger, "Resource number ( required )" ) do |opt_arg|
        cmdln_option[ 'resource-num' ] = opt_arg
    end
    option.on( "--filter", "apply-read-filter" ) do |opt_arg|
        cmdln_option[ 'filter' ] = true
    end
    option.on( "-h","--help" ) do
        Se.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option
#p ARGV
if ( cmdln_option[ 'repository-num' ] ) then
    repository_num = cmdln_option[ 'repository-num' ]
else
    Se.puts "The --repository-num option is required."
    raise
end
if ( cmdln_option[ 'resource-num' ] ) then
    resource_num = cmdln_option[ 'resource-num' ]
else
    Se.puts "The --resource-num option is required."
    raise
end
record_filter_B = cmdln_option[ 'filter' ] 

aspace_O = ASpace.new
aspace_O.api_uri_base = api_uri_base
aspace_O.login( "admin", "admin" )
#Se.pom(aspace_O)
#Se.pov(aspace_O)
rep_O = Repository.new( aspace_O, repository_num )
#Se.pom(rep_O)
#Se.pov(rep_O)
res_buf_O = Resource.new( rep_O, resource_num ).make_buffer.read

current_record_type = K.undefined
ARGV.push('res') if (ARGV.empty?)
ARGV.each do | element | 
    if ( element.in? [ 'ao', 'tc' ]) then
        current_record_type = element
        next
    end
    if ( element == 'res' ) then
         current_record_type = element
    end
    if ( current_record_type == K.undefined ) then
        Se.puts "No record_type specified"
        raise
    end
    case current_record_type
    when 'ao'
        puts "Archival_Object: #{element}:"
        ao_buf_O = Archival_Object.new(res_buf_O, element ).make_buffer.read( record_filter_B )
        pp ao_buf_O.record_H
    when 'res' 
        puts "Resource: #{resource_num}:"
        pp res_buf_O.record_H
    when 'tc'
        puts "Top_Container: #{element}:"
        tc_buf_O = Top_Container.new(res_buf_O, element ).make_buffer.read( record_filter_B )
        pp tc_buf_O.record_H
    else
        puts "Unknown record_type: #{current_record_type}"
    end 
end

