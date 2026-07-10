

require 'optparse'
require 'class.Archivesspace.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.ArchivalObject.rb'

BEGIN {}
END {}

binding.pry if ( respond_to? :pry )
myself_name = File.basename( $0 )

cmdln_option_H = { :rep_num => 2,
                   :res_num => nil,
                  }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( default is all resources )." ) do | opt_arg |
        cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#p cmdln_option_H
#p ARGV
if ( ! cmdln_option_H[ :rep_num ] ) then
    SE.puts "The --rep-num option is required."
    raise
end

def print_oddity( hash, what_am_i )
    return if hash.empty?
    puts "#{what_am_i}:"
    hash.sort.to_h.each_pair do | res_num, tc_list_A |
        resource_lit = ' ' * 100
        if ( res_num != 0 ) then
            resource_lit.prepend( "Resource #{res_num}:" )  
        end
        tc_list_A.sort.each_slice( 6 ) do | tc_sub_list_A |
            print resource_lit[ 0, 20 ]
            puts  tc_sub_list_A.join( ', ' )
            resource_lit[ 0, 20 ] = ' ' * 20
        end
        puts ''
        puts ''
    end
    puts ''
    puts ''
    puts ''
end    
aspace_O = ASpace.new
rep_O = Repository.new( aspace_O, cmdln_option_H[ :rep_num ] )

SE.puts "Finding Top_Containers (which takes some time) ..."
time_begin = Time.now
if ( cmdln_option_H[ :res_num ].nil? ) then
    SE.puts "Getting TC's ..."
    tc_record_H_A = rep_O.query( TOP_CONTAINERS ).record_H_A
else
    res_O         = Resource.new( rep_O, cmdln_option_H.fetch( :res_num ) )
    SE.puts "Getting AO's ..."
    ao_QO         = AO_Query__of_Resource.new( res_O: res_O, get_full_ao_record_TF: true )
    SE.puts "Getting TC's ..."
    tc_QO         = TC_Query__of_Resource.new( ao_QO )
    tc_record_H_A = tc_QO.record_H_A
end
elapsed_seconds = Time.now - time_begin
SE.puts "Elapsed seconds = #{elapsed_seconds}"

SE.puts "#{tc_record_H_A.length} Top Containers."

blank_tc_type__tc_list_A__BY_resource_num = {}
multiple_collections__tc_list_A__BY_nothing = {}  # __BY_nothing is just to have a common print routine
single_series__tc_list_A__BY_resource_num = {}
multiple_series__tc_list_A__BY_resource_num = {}
multiple_locations__tc_list_A__BY_resource_num = {}

tc_record_H_A.each_with_index do | tc_record_H, idx |
    if ( tc_record_H.fetch( K.collection ).empty? ) then
        next
    end  
   #SE.q {'tc_record_H.fetch( K.collection )'} if idx == 1
    collection_H_A = tc_record_H.fetch( K.collection )
    resource_num   = collection_H_A.first[ K.ref ].trailing_digits.to_i
    
    type           = tc_record_H.fetch( K.type, '' )
    indicator      = tc_record_H.fetch( K.indicator, '' ) 
    tc_num         = tc_record_H.fetch( K.uri ).trailing_digits    
    tc_label       = "#{type} #{indicator} `#{tc_num}`"
    
    if ( type.blank? ) then
        blank_tc_type__tc_list_A__BY_resource_num[ resource_num ] ||= []
        blank_tc_type__tc_list_A__BY_resource_num[ resource_num ] << tc_label
    end
    if ( collection_H_A.length > 1 ) then
        multiple_collections__tc_list_A__BY_nothing[ 0 ] ||= []
        multiple_collections__tc_list_A__BY_nothing[ 0 ] << tc_label
    end
    if ( tc_record_H.fetch( K.series ).length == 1 ) then
        single_series__tc_list_A__BY_resource_num[ resource_num ] ||= []
        single_series__tc_list_A__BY_resource_num[ resource_num ] << "#{tc_label}"
    end
    if ( tc_record_H.fetch( K.series ).length > 1 ) then
        multiple_series__tc_list_A__BY_resource_num[ resource_num ] ||= []
        multiple_series__tc_list_A__BY_resource_num[ resource_num ] << "#{tc_label} (#{tc_record_H.fetch( K.series ).length})"
    end
    if ( tc_record_H.fetch( K.container_locations ).length > 1 ) then
        multiple_locations__tc_list_A__BY_resource_num[ resource_num ] ||= []
        multiple_locations__tc_list_A__BY_resource_num[ resource_num ] << "#{tc_label} (#{tc_record_H.fetch( K.container_locations ).length})"
    end

end

print_oddity( blank_tc_type__tc_list_A__BY_resource_num, "TC's with a BLANK type" )
print_oddity( multiple_collections__tc_list_A__BY_nothing, "TC's with multiple collections" )
print_oddity( single_series__tc_list_A__BY_resource_num, "TC's with single series" )
print_oddity( multiple_series__tc_list_A__BY_resource_num, "TC's with multiple series" )
print_oddity( multiple_locations__tc_list_A__BY_resource_num, "TC's with multiple locations" )










