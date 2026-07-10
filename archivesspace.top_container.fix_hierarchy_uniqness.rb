

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

cmdln_option_H = { :rep_num         => 2,
                   :res_num         => nil,
                   :res_faft        => nil,
                   :update          => false,
                   :do_only_n       => nil,
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
    option.on( "--do-only n", OptionParser::DecimalInteger, "Stop after N existing TC's is fully processed." ) do | opt_arg |
        cmdln_option_H[ :do_only_n ] = opt_arg.to_i
    end
    option.on( "-1", "Like --do-only, with n = 1" ) do | opt_arg |
        cmdln_option_H[ :do_only_n ] = 1
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

SE.q {'cmdln_option_H'}

aspace_O = ASpace.new
aspace_O.allow_updates = cmdln_option_H.fetch( :update )
rep_O  = Repository.new( aspace_O, cmdln_option_H[ :rep_num ] )
res_O  = Resource.new( rep_O, cmdln_option_H.fetch( :res_num ) )
res_BO = res_O.new_buffer.read
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


tc_data_H__BY_type_N_indicator_CKA = {}
tc_QO.record_H_A.each_with_index do | tc_record_H, idx |
    type                         = tc_record_H.fetch( K.type, '' ).downcase
    indicator                    = tc_record_H.fetch( K.indicator, '' ) 
    current_type_N_indicator_CKA = [ type, indicator ]
    tc_uri                       = tc_record_H.fetch( K.uri )
    ancestor_H_A_A               = tc_QO.ao_data_H_A__OF_tc_uri( tc_uri ).map
                                                                         .each{ | ao_data_H | ao_data_H.fetch( K.ancestors).freeze 
                                                                               }.uniq
    if ( tc_data_H__BY_type_N_indicator_CKA.has_key?( current_type_N_indicator_CKA ) )
        SE.puts "#{SE.lineno}: =============================="
        SE.puts "Found duplicate type/indicator, type=#{type}, indicator=#{indicator}, new tc_uri=#{tc_uri}" +
                ", existing tc_uri's=#{tc_data_H__BY_type_N_indicator_CKA[ current_type_N_indicator_CKA ][ :CURRENT ][ :tc_uri_A ]}"
    else
        tc_data_H__BY_type_N_indicator_CKA[ current_type_N_indicator_CKA ] = { :ancestor_H_A_A => [],
                                                                               :CURRENT => {
                                                                                             :tc_uri_A => [],
                                                                                            },
                                                                            
                                                                               :NEW => {
                                                                                         :indicator_A => [],                                                                           
                                                                                         :tc_uri_A    => [],
                                                                                        },
                                                                            
                                                                               }
    end
    tc_data_H__BY_type_N_indicator_CKA[ current_type_N_indicator_CKA ].yield_self do | tc_data_H |
        tc_data_H[ :ancestor_H_A_A ].concat( ancestor_H_A_A ).uniq!
        tc_data_H[ :CURRENT ][ :tc_uri_A ] << tc_uri
    end
#   arr.tally.select { |item, count| count > 1 }.keys
    
#   puts "#{type} #{indicator}, `#{tc_uri.trailing_digits}`, ancestors = #{ancestor_H_A_A.length} related AO's = #{tc_QO.ao_data_H_A__OF_tc_uri( tc_record_H[ K.uri ] ).length}"

end


#  Create new indicator suffixes

regex = /^\s*#{K.any_fmtr_group_record_RES}\s*(\d+(?:\.\d+)*[.:])/i

tc_data_H__BY_type_N_indicator_CKA.each_pair do | current_type_N_indicator_CKA, tc_data_H |   
    current_tc_indicator = current_type_N_indicator_CKA.last    # The array is [ type, indicator ]
    tc_data_H__BY_type_N_indicator_CKA[ current_type_N_indicator_CKA ].yield_self do | tc_data_H |
        tc_data_H[ :ancestor_H_A_A ].each_with_index do | ancestor_H_A |
            indicator_suffix_A = []
            ancestor_H_A.each do | ancestor_H |
                next if ( ancestor_H.fetch( K.level ) == K.collection )
                ao_record_H = ao_QO.record_H__OF_uri( ancestor_H.fetch( K.ref ) )
                m_O = ao_record_H.fetch( K.title ).match( regex )
                if m_O.nil?
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Don't know what to do with title: '#{ao_record_H.fetch( K.title )}'"
                    SE.puts "m_O is nil"
                    SE.q {'m_O'}
                    raise
                end                              
                level_num  = m_O[ 2 ].sub( /[.:]$/, '' )
                case m_O[ 1 ].strip.downcase
                when 'record group'
                    indicator_suffix_A << "RG#{level_num}"
                when 'series'
                    indicator_suffix_A << "S#{level_num}"
                when 'subseries', 'sub-series'
                    indicator_suffix_A << "ss#{level_num}"
                else
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Don't know what to do with title: '#{ao_record_H.fetch( K.title )}'"
                    SE.puts "Unrecognized group-type: '#{m_O[ 1 ].strip.downcase}'"
                    SE.q {'m_O'}
                    raise
                end
            end
            indicator_suffix = indicator_suffix_A.reverse.join( ':' )
            if indicator_suffix.blank?
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Don't know what to do with title: '#{ao_record_H.fetch( K.title )}'"
                SE.puts "Resulting new_indicator_suffix is blank."
                SE.q {'m_O'}
                raise
            end
            stringer = "[#{indicator_suffix}]"
            if current_tc_indicator.end_with?( stringer )
                tc_data_H[ :NEW ][ :indicator_A ] << :SKIP
            else
                tc_data_H[ :NEW ][ :indicator_A ] << "#{current_tc_indicator} #{stringer}" 
            end
        end
        count_skips = tc_data_H[ :NEW ][ :indicator_A ].count( :SKIP )
        if ( count_skips.not_in?( 0, tc_data_H[ :ancestor_H_A_A ].length ) )
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts "count of :SKIP's != tc_data_H[ :ancestor_H_A_A ].length (it should be all or none)."
            SE.q {['count_skips','tc_data_H[ :ancestor_H_A_A ].length']}
            SE.q {'tc_data_H'}
            raise
        end
        if ( tc_data_H[ :ancestor_H_A_A ].length != tc_data_H[ :NEW ][ :indicator_A ].length )
            SE.puts "#{SE.lineno}: =============================================="
            SE.puts 'tc_data_H[ :ancestor_H_A_A ].length != tc_data_H[ :indicator_A ].length'
            SE.q {'tc_data_H'}
            raise
        end
    end
end
#SE.q {'tc_data_H__BY_type_N_indicator_CKA.first'}

count_of_H = { :current_tcz_processed  => 0,
               :current_tcz_updated    => 0,
               :aoz_not_needing_update => 0,
               :new_tcz_added          => 0,
               :aoz_updated            => 0,
             }
            
tc_data_H__BY_type_N_indicator_CKA.each_pair do | current_type_N_indicator_CKA, tc_data_H  |
    break if ( cmdln_option_H[ :do_only_n ].not_nil? && 
               count_of_H[ :current_tcz_processed ] >= cmdln_option_H[ :do_only_n ] )
    tc_data_H__BY_type_N_indicator_CKA[ current_type_N_indicator_CKA ].yield_self do | tc_data_H |
        tc_data_H[ :CURRENT ][ :tc_uri_A ].each_with_index do | current_tc_uri, current_tc_uri_idx |
            SE.raise if ( tc_data_H[ :ancestor_H_A_A ].empty? )
            current_tc_record_H = tc_QO.record_H__OF_uri( current_tc_uri )
            if tc_data_H[ :ancestor_H_A_A ].maxindex == 0 && 
               tc_data_H[ :CURRENT ][ :tc_uri_A ].maxindex == 0  # If there's more than 1 TC with the same Box Indicator #
                                                                 # it's easier to create a new TC, which will then get the
                                                                 # AO attacted to each current one reassigned to the new one.
            then
                ancestor_idx = 0
                count_of_H[ :current_tcz_updated ]   += 1
                count_of_H[ :aoz_not_needing_update] += tc_QO.ao_data_H_A__OF_tc_uri( current_tc_uri ).length
                if ( tc_data_H[ :NEW ][ :indicator_A ][ ancestor_idx ] == :SKIP )
                    puts "TC #{current_type_N_indicator_CKA} `#{tc_data_H[ :CURRENT ][ :tc_uri_A ].join( '`') }` already updated, skipped."
                    next current_tc_uri
                end
                puts "Update TC `#{current_tc_uri.trailing_digits}` '#{current_type_N_indicator_CKA.first} #{tc_data_H[ :NEW ][ :indicator_A ][ ancestor_idx ]}'"
                tc_BO = Top_Container.new( res_O, current_tc_uri ).new_buffer.read
                new_indicator = tc_data_H[ :NEW ][ :indicator_A ].fetch( ancestor_idx )
                tc_BO.record_H[ K.indicator ] = new_indicator
                tc_BO.store
                tc_data_H[ :NEW ][ :tc_uri_A ][ ancestor_idx ] = tc_BO.uri_addr
                count_of_H[ :current_tcz_processed ] += 1                
                next current_tc_uri
            end
            tc_data_H[ :ancestor_H_A_A ].each_index do | ancestor_idx |
                if ( tc_data_H[ :NEW ][ :indicator_A ][ ancestor_idx ] == :SKIP )
                    puts "TC #{current_type_N_indicator_CKA} `#{tc_data_H[ :CURRENT ][ :tc_uri_A ].join( '`') }` already updated, skipped."
                    next ancestor_idx
                end
                if ( tc_data_H[ :NEW ][ :tc_uri_A ][ ancestor_idx ].not_nil? )
                    if ( current_tc_uri_idx > 0 )
                        if ( tc_data_H[ :NEW ][ :tc_uri_A ].any?( &:nil? ) )
                            SE.puts "#{SE.lineno}: =============================================="
                            SE.puts 'A duplicate TC found a nil in tc_data_H[ :NEW ][ :tc_uri_A ]'
                            SE.puts 'The 1st TC should have set everything to a new TC uri.'
                            SE.q {'current_tc_uri_idx'}
                            SE.q {'ancestor_idx'}
                            SE.q {'tc_data_H'}
                            raise
                        else
                            puts "Dup TC for '#{current_type_N_indicator_CKA.first} #{tc_data_H[ :NEW ][ :indicator_A ][ ancestor_idx ]}'"
                            next ancestor_idx
                        end
                    end
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts 'Was expecting tc_data_H[ :NEW ][ :tc_uri_A ][ ancestor_idx ] to be nil'
                    SE.q {'current_tc_uri_idx'}
                    SE.q {'ancestor_idx'}
                    SE.q {'tc_data_H'}
                    raise                    
                end
                puts "Create TC for '#{current_type_N_indicator_CKA.first} #{tc_data_H[ :NEW ][ :indicator_A ][ ancestor_idx ]}'"
                tc_BO = Top_Container.new( res_O ).new_buffer
                                                  .create
                                                  .load( current_tc_record_H.deep_copy )                       
                new_indicator = tc_data_H[ :NEW ][ :indicator_A ].fetch( ancestor_idx )                   
                tc_BO.record_H[ K.indicator ] = new_indicator
                tc_BO.store
                tc_data_H[ :NEW ][ :tc_uri_A ][ ancestor_idx ] = tc_BO.uri_addr
                count_of_H[ :new_tcz_added ] += 1
            end
            tc_QO.ao_data_H_A__OF_tc_uri( current_tc_uri ).each do | ao_data_H |    # All records of the current TC
                idx_A = tc_data_H[ :ancestor_H_A_A ].each_index.select { | idx | tc_data_H[ :ancestor_H_A_A ][ idx ] == ao_data_H[ K.ancestors ] }                
                if ( idx_A.length != 1 )
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts 'Was only expecting 1 match on: tc_data_H[ :ancestor_H_A_A ][ idx ] == ao_data_H[ K.ancestors ]'
                    SE.q {'current_tc_uri'}
                    SE.q {'idx_A'}
                    SE.q {'ao_data_H'}
                    SE.q {'tc_data_H[ :ancestor_H_A_A ]'}
                    SE.q {'tc_data_H'}
                    raise
                end                    

                ancestor_idx = idx_A.first
                new_tc_uri   = tc_data_H[ :NEW ][ :tc_uri_A ][ ancestor_idx ]
                SE.raise if ( new_tc_uri.nil? )

                puts "Update AO `#{ao_data_H[ K.uri ].trailing_digits}` " +
                     "from TC `#{current_tc_uri.trailing_digits}` " + 
                     "(#{current_type_N_indicator_CKA.first} #{current_type_N_indicator_CKA.last}) " +
                     "to `#{new_tc_uri.trailing_digits}` " +
                     "(#{current_type_N_indicator_CKA.first} #{tc_data_H[ :NEW ][ :indicator_A ].fetch( ancestor_idx )}) "               
#               ao_record_H = ao_QO.record_H__OF_uri( ao_data_H.fetch( K.uri ) ).deep_copy           
                ao_rec_BO = Archival_Object.new( res_O, ao_data_H.fetch( K.uri ) )
                                           .new_buffer
                                           .read
#                                          .load( ao_record_H )

                cnt_of_changes = 0
                cnt_of_TCz     = 0
                ao_rec_BO.record_H.to_CKA_h.each_pair do | key_CKA, value |
                    next if value.is_not_a?( String )
                    cnt_of_TCz +=1 if value.include?( '/top_containers/' )
                    next if value != current_tc_uri
                    cnt_of_changes += 1
                    ao_rec_BO.record_H.value__using_CKA!( key_CKA ) { new_tc_uri }
                end                   
                if cnt_of_changes != 1
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Unexpected count on change of TC ref in AO"
                    SE.q {'cnt_of_changes'}
                    SE.q {'ao_rec_BO.record_H'}
                    raise
                end
                if cnt_of_TCz != 1
                    SE.puts "#{SE.lineno}: =============================================="
                    SE.puts "Unexpected number of TC ref in AO"
                    SE.q {'cnt_of_TCz'}
                    SE.q {'ao_rec_BO.record_H'}
                    raise
                end
                ao_rec_BO.store
                count_of_H[ :aoz_updated ] += 1

            end
        count_of_H[ :current_tcz_processed ] += 1
        end
    end
end

SE.q {'count_of_H'}        








