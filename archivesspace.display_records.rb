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

cmdln_option_H = { :rep_num => 2  ,
                 :res_num => nil  ,
                 :filter => false ,
                 :flattened => false }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} --res-num n [res] [(res|ao|tc|loc|index) n,n,...]..."
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number" ) do |opt_arg|
        cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "--filter", "Apply read filter" ) do |opt_arg|
        cmdln_option_H[ :filter ] = true
    end
    option.on( "--flattened", "--flatten", "Flatten the record and ap(awesome-print) it." ) do |opt_arg|
        cmdln_option_H[ :flattened ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered

aspace_O = ASpace.new
 
if ( cmdln_option_H[ :rep_num ] ) then
    rep_num = cmdln_option_H[ :rep_num ]
    rep_O = Repository.new( aspace_O, rep_num )
else
    SE.puts "The --rep-num option is required."
    raise
end
if ( cmdln_option_H[ :res_num ] ) then
    res_num = cmdln_option_H[ :res_num ]
    res_O = Resource.new( rep_O, res_num )
    res_BO = res_O.new_buffer.read( filter_record_TF: cmdln_option_H[ :filter ] )
end


print_LP = lambda{ | thingy | 
    if ( cmdln_option_H[ :flattened ] ) then
        thingy = thingy.to_CKA_h 
    end
    puts thingy.ai
}

ao_QO = nil
current_record_type = UNDEFINED
ARGV.push('res') if (ARGV.empty?)
ARGV.each do | element | 
    if ( element.in? [ 'res', 'ao', 'index' ]) then
        if ( not res_BO ) then
            SE.puts "The --res-num option is required."
            raise
        end
        current_record_type = element
        next if ( element != 'res' )
    end
    if ( element.in?( 'tc', 'loc' ) ) then
        current_record_type = element
        next
    end
    if ( current_record_type == UNDEFINED ) then
        SE.puts "No record_type specified"
        raise
    end
    case current_record_type
    when 'res' 
        puts "Resource: #{res_num}:"
        print_LP.( res_BO.record_H )
    when 'ao'
        puts "Archival_Object: #{element}:"
        ao_BO = Archival_Object.new( res_BO, element )
                               .new_buffer
                               .read( filter_record_TF: cmdln_option_H[ :filter ] )
        print_LP.( ao_BO.record_H )
    when 'index' 
        puts "Index for Archival_Object: #{element}:"
        if ( ao_QO.nil? ) then
            ao_QO = AO_Query__of_Resource.new( res_O: res_O )
        end
        print_LP.( ao_QO.index_H__OF_uri( element ) )
    when 'tc'
        puts "Top_Container: #{element}:"
        tc_BO = Top_Container.new(  res_O.nil? ? rep_O : res_O , element )
                             .new_buffer
                             .read( filter_record_TF: cmdln_option_H[ :filter ] )
        print_LP.( tc_BO.record_H )
    when 'loc'
        puts "Location: #{element}:"
        loc_BO = Location.new( aspace_O, element )
                         .new_buffer
                         .read( filter_record_TF: cmdln_option_H[ :filter ] )
        print_LP.( loc_BO.record_H )
    else
        puts "Unknown record_type: #{current_record_type}"
    end 
end

