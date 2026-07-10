

require 'optparse'
require 'class.Archivesspace.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.ArchivalObject.rb'

module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :keys_to_delete_A
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

BEGIN {}
END {}

binding.pry if ( respond_to? :pry )
myself_name = File.basename( $0 )

cmdln_option_H = { :rep_num         => 2,
                   :res_num         => nil,
                   :res_faft        => nil,
                   :update          => false,
                  }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )" ) do |opt_arg|
        cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( Required )." ) do | opt_arg |
        cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "--res-faft x", "Resource's K.Filing_Aid_Filing_Title ( required )" ) do | opt_arg |
        cmdln_option_H[ :res_faft ] = opt_arg.strip.downcase
    end
    option.on( "--update", "Do updates." ) do | opt_arg |
        cmdln_option_H[ :update ] = true
    end
    option.on( "--do-only n", OptionParser::DecimalInteger, "Stop after n TC's are 'stored', --update needs to set to actually update." ) do | opt_arg |
        cmdln_option_H[ :do_only_n ] = opt_arg.to_i
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
if ( ! cmdln_option_H[ :res_num ] ) then
    SE.puts "The --res-num option is required."
    raise
end
if ( cmdln_option_H[ :res_faft ].nil? ) then
    SE.puts "The --res-faft option is required."
    raise
end

self.keys_to_delete_A = [ K.component_id, 
                          K.external_ids,             # This doesn't seem to hurt anything.
                          K.external_documents,
                          K.series,
                         ]
                    
SE.q {'cmdln_option_H'}

aspace_O = ASpace.new
aspace_O.allow_updates = cmdln_option_H.fetch( :update )
rep_O  = Repository.new( aspace_O, cmdln_option_H[ :rep_num ] )
res_O  = Resource.new( rep_O, cmdln_option_H.fetch( :res_num ) )
res_BO = res_O.new_buffer.read( filter_record_TF: false )
aspace_O.validate_resource_faft( res_BO, cmdln_option_H[ :res_faft ] )

SE.puts "Finding Top_Containers (which takes some time) ..."

time_begin = Time.now

SE.puts "Getting AO's ..."
ao_QO = AO_Query__of_Resource.new( res_O: res_O, get_full_ao_record_TF: true )
SE.puts "#{ao_QO.record_H_A.length} AO's."
elapsed_seconds = Time.now - time_begin
SE.puts "Elapsed seconds = #{elapsed_seconds}"

SE.puts "Getting TC's ..."                                         
tc_QO = TC_Query__of_Resource.new( ao_QO )
SE.puts "#{tc_QO.record_H_A.length} TC's, and " +
        "#{tc_QO.record_H_A.sum{ | tc_record_H | tc_QO.ao_data_H_A__OF_tc_uri( tc_record_H[ K.uri ] ).length }} related AO's"

elapsed_seconds = Time.now - time_begin
SE.puts "Elapsed seconds = #{elapsed_seconds}"

def delete_stuff( record_H )
    record_H.deep_yield do | y |
        next y if y.is_not_a?( Hash )
        y.delete_if do | key, value | 
            next false if key.not_in?( self.keys_to_delete_A )
            next false if value.empty?
SE.q {'key'}
            next true
        end
        next y
    end
end

=begin
#   The 'external_ids' field gets deleted, but then put back.   It doesn't seem to hurt anything.

fixed_record_H = delete_stuff( res_BO.record_H )
if ( fixed_record_H != res_BO.record_H )
    res_BO.load( fixed_record_H, filter_record_TF: false )
    res_BO.store
end
=end

tc_QO.record_H_A.each do | q_tc_record_H |
    fixed_record_H = delete_stuff( q_tc_record_H )
    if ( fixed_record_H != q_tc_record_H )  
        tc_BO = Top_Container.new( res_O, fixed_record_H[ K.uri] ).new_buffer
                                                                  .load( fixed_record_H, filter_record_TF: false )  
        tc_BO.store
    end
end
ao_QO.record_H_A.each do | q_ao_record_H |
    fixed_record_H = delete_stuff( q_ao_record_H )
    if ( fixed_record_H != q_ao_record_H )  
        ao_BO = Archival_Object.new( res_O, fixed_record_H[ K.uri] ).new_buffer
                                                                    .load( fixed_record_H, filter_record_TF: false )  
        ao_BO.store
    end
end

    
    
