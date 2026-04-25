=begin

    Display all the Archival-Objects of a Resource, with a few different 
    print options.

=end

require 'json'
require 'optparse'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'
require 'class.Archivesspace.TopContainer.rb'
require 'class.Archivesspace.Location.rb'

module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :myself_name, :cmdln_option_H, :rep_O, :res_O, :ala_id_0
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

BEGIN {
    LF = "\n"
    }
END {}

self.myself_name = File.basename( $0 )

self.cmdln_option_H = { :rep_num  => 2,
                        :res_num  => nil,
                        :res_faft => nil,
                        :update   => false,
                       }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Repository number ( default = 2 )." ) do |opt_arg|
        self.cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Resource number ( required )." ) do |opt_arg|
        self.cmdln_option_H[ :res_num ] = opt_arg
    end
    option.on( "--res-faft x", "Resource's K.Filing_Aid_Filing_Title ( required )" ) do | opt_arg |
        self.cmdln_option_H[ :res_faft ] = opt_arg.strip.downcase
    end
    option.on( "--update", "Do updates." ) do | opt_arg |
        self.cmdln_option_H[ :update ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
#SE.q { 'self.cmdln_option_H' }

if ( self.cmdln_option_H.fetch( :rep_num ).nil? ) then
    SE.puts "The --rep-num option is required."
    raise
end
if ( self.cmdln_option_H.fetch( :res_num ).nil? ) then
    SE.puts "The --res-num option is required."
    raise
end
if ( self.cmdln_option_H[ :res_faft ].nil? ) then
    SE.puts "The --res-faft option is required."
    raise
end

aspace_O = ASpace.new
aspace_O.allow_updates=self.cmdln_option_H.fetch( :update )
rep_O          = Repository.new( aspace_O, self.cmdln_option_H.fetch( :rep_num ) )
res_O          = Resource.new( rep_O, self.cmdln_option_H.fetch( :res_num ) )
res_rec_buf_O  = res_O.new_buffer.read
aspace_O.validate_resource_faft( res_rec_buf_O, self.cmdln_option_H[ :res_faft ] )
self.ala_id_0 = "_#{res_rec_buf_O.record_H.fetch( K.id_0 ).sub( /inmagic /, '' ).gsub( /\s+/, '_' )}_"

def get_ao_ala_stuff( record_H )
    changed_record_CKA_H = {}
    ala_note_RE = /\A\s*#{ALA_NOTE_MARKER}.*?#{LF}/
    orig_record_CKA_H = record_H.to_composite_key_h
    orig_record_CKA_H.each_pair do | orig_record_CKA, orig_value |
        next if ( orig_value.is_not_a?( String ) )
        next if ( orig_value.not_match?( /#{ALA_NOTE_MARKER}/ ) )
        new_value = orig_value + ''
        loop do 
            new_value.sub!( ala_note_RE, '' )
            m_O = $~
            break if m_O.nil?
        end
        if ( orig_value == new_value ) then
            SE.puts "#{SE.lineno} '#{ALA_NOTE_MARKER}' found, but nothing changed."
            SE.q {['orig_value','new_value']}
            SE.q {['orig_record_CKA']}
            SE.q {['orig_record_CKA_H']}
            raise            
        end
        changed_record_CKA_H[ orig_record_CKA ] = new_value
    end
    SE.q {'changed_record_CKA_H'} if ( changed_record_CKA_H.not_empty? )
    return changed_record_CKA_H
end

def remove_ao_ala_stuff( changed_record_CKA_H, record_H )
    changed_record_CKA_H.each_pair do | changed_record_CKA, text_value | 
        new_value     = record_H.dig( *changed_record_CKA )
        raise "new_value.nil?" if ( new_value.nil? )
        new_value.replace( text_value )
    end
end


changed_record_CKA_H = get_ao_ala_stuff( res_rec_buf_O.record_H )
if ( changed_record_CKA_H.not_empty? ) then 
    remove_ao_ala_stuff( changed_record_CKA_H, res_rec_buf_O.record_H )
    res_rec_buf_O.store
end

SE.puts "Getting AO's ..."
ao_query_O = AO_Query_of_Resource.new( resource_O: res_O, get_full_ao_record_TF: true )
ao_query_O.record_H_A.each do | record_H |
    changed_record_CKA_H = get_ao_ala_stuff( record_H )
    if ( changed_record_CKA_H.not_empty? ) then 
        ao_rec_buf_O = Archival_Object.new( res_O, record_H.fetch( K.uri ) ).new_buffer.read
        remove_ao_ala_stuff( changed_record_CKA_H, ao_rec_buf_O.record_H )
        ao_rec_buf_O.store
    end
end

SE.puts "Getting TC's ..."
TC_Query_of_Resource.new( ao_query_O ).record_H_A.each do | record_H |
    container_location_H_A = record_H.fetch( K.container_locations ).cbv
    container_location_H_A.delete_if { 
                    | container_location_H | container_location_H[ K.note ].to_s.match?( /^#{ALA_NOTE_MARKER}/i ) || 
                                             container_location_H[ K.start_date ].to_s == ALA_START_DATE }
    if ( container_location_H_A.length != record_H.fetch( K.container_locations ).length ) then
        rec_buf_O = Top_Container.new( res_O, record_H.fetch( K.uri ) ).new_buffer.read
        changed_record_H = rec_buf_O.record_H
        changed_record_H[ K.container_locations ] = container_location_H_A
        SE.q {'changed_record_H'} if ( container_location_H_A.not_empty? )
        rec_buf_O.store        
    end
end

ala_problem_id_0_text = "#{ALA_PROBLEMS} [#{self.ala_id_0}"
search_text  = %Q|title:"#{ala_problem_id_0_text}"|         # Note field-name and quotes in text
SE.q {'search_text'}
loc_record_H_A = rep_O.search( record_type_A: [ K.location ], search_text: search_text ).result_A
loc_record_H_A.each do | loc_record_H |
    raise "if ( loc_record_H[ K.title ].not_match?( /#{self.ala_id_0}/ ) )" if ( loc_record_H[ K.title ].not_match?( /#{self.ala_id_0}/ ) )
    loc_buf_O = Location.new( rep_O, loc_record_H[ K.uri ] ).new_buffer.read
    loc_buf_O.delete
end

