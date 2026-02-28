#!run_ruby.sh

require 'date'
require 'class.Archivesspace.rb'
require 'csv.rb'
require 'class.Find_Dates_in_String.rb'
require 'optparse'

module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :aspace_O, :cmdln_option_H, :myself_name, :record_H
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

@myself_name = File.basename( $0 )

#   Fields with '|'
#       Date of gift:  Spreadsheet only handles 3 dates.  
#                      Some dates have comments:  put in expression.    
#                      Dates over 3, make a note.
#       Notes:  replace with line-feed
#       Accession Number:  replace with ' + '
#       Name: replace with ' + '
#
#   There's only one General note field, so
#   create a string for a note as follows:
#     1)  The InMagic note
#     2)  Additional dates (beyond 3)
#     3)  Odd dates
#     4)  The entire InMagic record (minus the InMagic note)  
#

@cmdln_option_H = { :input_col_sep => ',',
                   }
                  
OptionParser.new do |option|
    option.banner = "Usage: [STDIN |] #{myself_name} [options] [file] [file]"

    option.on( "-i --input_col_sep x", "The :col_sep value for the CSV input." ) do | opt_arg |
        cmdln_option_H[ :input_col_sep ] = opt_arg
    end
   
    option.on( '-?, -h, --help', "This help" ) do
        $stderr.puts option
        exit 1
    end
end.parse!  # Bang because ARGV is altered

if ( ARGV.empty? and not $stdin.stat.pipe? ) then
    raise "No file or STDIN pipe."
end

@aspace_O = ASpace.new()
inmagic_header_A = [ 'name', 'date of gift', 'accession number', 'notes' ]

template_record_H = {
    'accession_title' => nil,
    'accession_number_1' => nil,
    'accession_number_2' => nil,
    'accession_number_3' => nil,
    'accession_number_4' => nil,
    'accession_date' => nil,
    'date_1_label' => nil,
    'date_1_expression' => nil,
    'date_1_begin' => nil,
    'date_1_end' => nil,
    'date_1_type' => nil,
    'date_2_label' => nil,
    'date_2_expression' => nil,
    'date_2_begin' => nil,
    'date_2_end' => nil,
    'date_2_type' => nil,
    'accession_access_restrictions' => nil,
    'accession_access_restrictions_note' => nil,
    'accession_acquisition_type' => nil,
    'accession_condition_description' => nil,
    'accession_content_description' => nil,
    'accession_general_note' => nil,
    'accession_language'                             => 'eng', 
    'accession_script'                               => 'Latn',
    'accession_retention_rule' => nil,
    'accession_use_restrictions_note' => nil,
    'accession_cataloged_note' => nil,
    'accession_acknowledgement_sent' => nil,
    'accession_acknowledgement_sent_date' => nil,
    'accession_agreement_received' => nil,
    'accession_agreement_received_date' => nil,
    'accession_agreement_sent' => nil,
    'accession_agreement_sent_date' => nil,
    'accession_cataloged' => nil,
    'accession_cataloged_date' => nil,
    'accession_processed' => nil,
    'accession_processed_date' => nil,
    'agent_type' => nil,                            # 'agent_person', 'agent_corporate_entity'
    'agent_role' => nil,                            # 'creator'                      
    'agent_name_name_order' => nil,                 # 'Indirect'                
    'agent_name_source' => nil,                     # 'local'                 
    'agent_name_primary_name' => nil,
}

def template_date_formatter( as_date, date_column_num )
    record_H[ "date_#{date_column_num}_label" ]      = 'creation'
    record_H[ "date_#{date_column_num}_expression" ] = aspace_O.format_date_expression( as_date )
    record_H[ "date_#{date_column_num}_begin" ]      = as_date
    record_H[ "date_#{date_column_num}_end" ]        = as_date
    record_H[ "date_#{date_column_num}_type" ]       = 'inclusive' 
end


find_dates_O = Find_Dates_in_String.new( { Find_Dates_in_String::MORALITY_OPTION => { :good  => Find_Dates_in_String::REPLACE_ALL },
                                           :pattern_name_RES => '.',
                                           :date_string_composition => :dates_in_text,
                                           :yyyymmdd_min_value => '1960',
                                           :default_century_pivot_ccyymmdd => "19",
                                           } )

accession_number_H = {}
csrm_foundation_seq_num = "000"
note_join_string = ' +++CRLF+++ '
csv_input = CSV.new( ARGF, headers: true, col_sep: cmdln_option_H[ :input_col_sep ] )
csv_output = CSV.new( $stdout, :write_headers => true, :headers => template_record_H.keys )
csv_input.each do | input_ROW |

    record_H = template_record_H.merge( {} )
    anomaly_A = []
    note_A = []
    input_ROW.each_pair do | inmagic_column_name, inmagic_column | 
        inmagic_column = '' if ( inmagic_column.nil? )
        inmagic_column.chomp!
        inmagic_column_bar_split_A = inmagic_column.split( '|' ).map( &:to_s ).map( &:chomp ).map( &:strip ) 
        case inmagic_column_name.downcase
        when inmagic_header_A[ 0 ] 
            stringer = inmagic_column_bar_split_A.join( ' / ' )
            if ( inmagic_column_bar_split_A.length > 1 ) then
#                anomaly_A.push( "Double title: #{stringer}" )
            end
            if ( stringer.blank? ) then
                stringer = 'BLANK' 
                anomaly_A.push( "Blank title: #{inmagic_column}" )
            end
            stringer.split( /[^c]\/[^o]/i ).map( &:to_s ).map( &:chomp ).map( &:strip ).reject(&:empty?).each_with_index do | e, idx |
#               SE.q {[ 'e', 'idx' ]}
                case idx
                when 0
                    record_H[ 'accession_title' ] = e
                when 1
                    if ( e.gsub!( /,*\s+agent$/i, '' ) ) then
                        record_H[ 'agent_type' ] = 'agent_person'
                        record_H[ 'agent_role' ] = 'creator'                      
                        record_H[ 'agent_name_name_order' ] = 'Indirect'                
                        record_H[ 'agent_name_source' ] = 'local'  
                        record_H[ 'agent_name_primary_name' ] = e
                    else
                        record_H[ 'accession_title' ] += " / #{e}"
#                       anomaly_A.push( "Slash(/) in title but not an agent: #{stringer}" )
                    end
                else
                    if ( e =~ /,*\s+agent$/i ) then
                        record_H[ 'accession_title' ] += " + #{e}"
                        anomaly_A.push( "Two (or more) Agents in title: #{stringer}" )
                    else
                        record_H[ 'accession_title' ] += " / #{e}"
                        anomaly_A.push( "Two (or more) shashes(/) in title: #{stringer}" )
                    end
                end
            end
                       
        when inmagic_header_A[ 1 ] 
            aspace_date_A = []
            unknown_date_text_A = []
            inmagic_column_bar_split_A.each do | date_text |
                next if ( date_text.blank? )
                date_text_with_good_dates_replaced = find_dates_O.do_find( date_text )
                token_A = date_text_with_good_dates_replaced.split.map( &:to_s ).map( &:chomp ).map( &:strip )
              # SE.q {[ 'token_A' ]}
              # SE.q {[ 'find_dates_O.good__date_clump_S__A' ]}
                find_dates_O.good__date_clump_S__A.each do | e |    
                  # SE.q {[ 'e' ]}
                    if (  e.date_match_S__A.maxindex == 0 and
                          e.date_match_S__A[ 0 ].as_date == token_A[ 0 ][0 .. e.date_match_S__A[ 0 ].as_date.maxoffset ] ) then
                        case true
                        when ( find_dates_O.good__date_clump_S__A.length == 1 and token_A.length == 1 ) then                 
                            aspace_date_A.push( token_A.shift )  
                            break
                        when ( find_dates_O.good__date_clump_S__A.length == 2 and token_A.length > 2 ) then
                            stringer = token_A.shift
                            break if ( token_A.join( ' ' ).include?( ';' ) )
                            aspace_date_A.push( stringer )  
                            break
                        end
                    end
                end
              # SE.q {[ 'token_A' ]}
              # SE.q {[ 'aspace_date_A' ]}
                if ( token_A.length > 0 ) then
                    unknown_date_text_A.push( token_A.join( ' ' ) )
                end      
            end
            aspace_date_A.sort!
            aspace_date_A.uniq!
            aspace_date_A.map{ | e | e.sub!( /[^a-z0-9]$/i, '' ) }
            aspace_date_A.each do | aspace_date |
                testdate = ' ' * 10                                 # 10 spaces
                testdate[ 0, aspace_date.length ] = aspace_date     # stick the date at the front
                testdate.gsub!( ' ' * 3, '-01' )                    # replace each 3 spaces with '-01' (eg. '1984' -> '1984-01-01')
                begin
                    Date::strptime( testdate, '%Y-%m-%d' )
                rescue
                    SE.puts "#{SE.lineno}: Invalid date '#{aspace_date}' tested as '#{testdate}'"
                    SE.q {[ 'aspace_date_A ']}
                    raise
                end                
            end
            
          # SE.q {[ 'aspace_date_A' ]}
            record_H[ 'accession_date' ] = aspace_date_A.shift if ( aspace_date_A.length > 0 and aspace_date_A[ 0 ].length == 10 )
            template_date_formatter( aspace_date_A.shift, 1 )            if ( aspace_date_A.length > 0 )
            template_date_formatter( aspace_date_A.shift, 2 )            if ( aspace_date_A.length > 0 )
            anomaly_A.push( "More than 3 dates. Extras are: " + aspace_date_A.join( ' + ' ) ) if ( aspace_date_A.length > 0 )
            anomaly_A.push( "Unknown text/date in date field: " + unknown_date_text_A.join( ' + ' ) ) if ( unknown_date_text_A.length > 0 )
            
        when inmagic_header_A[ 2 ] 
            accession_number_A = inmagic_column_bar_split_A       
            if ( accession_number_A.maxindex > 0 ) then
                anomaly_A.push( "#{accession_number_A.length} Accession Numbers '#{inmagic_column}'.")
            end
            accession_number = accession_number_A.shift 
            if ( accession_number.nil? or accession_number.blank? ) then
                stringer = "BLANK"
                anomaly_A.push( "No InMagic Accession Number, assigned number is: #{stringer}" )
                accession_number = stringer + ''
            end
            if ( accession_number.downcase == "CSRM Foundation".downcase ) then
                csrm_foundation_seq_num.next!
                accession_number = "CSRM Foundation " + csrm_foundation_seq_num
            end
            if ( accession_number_H.has_key?( accession_number ) ) then
                accession_number_H[ accession_number ].next!
                stringer  = accession_number + ''
                stringer += "-#{accession_number_H[ accession_number ]}"
                anomaly_A.push( "Duplicate Accession Number: #{accession_number}, new number is: #{stringer}" )
                accession_number = stringer + ''
            else
                accession_number_H[ accession_number ] = 'A'
            end
            
            record_H[ 'accession_number_1' ] = accession_number
            record_H[ 'accession_number_2' ] = accession_number_A.shift if ( accession_number_A.length > 0 )
            record_H[ 'accession_number_3' ] = accession_number_A.shift if ( accession_number_A.length > 0 )
            record_H[ 'accession_number_4' ] = accession_number_A.shift if ( accession_number_A.length > 0 )
            anomaly_A.push( "Extra Accession numbers: " + accession_number_A.join( ' + ' ) ) if ( accession_number_A.length > 0 )
            
        when inmagic_header_A[ 3 ] 
            if ( inmagic_column_bar_split_A.length > 0 ) then 
                note_A.push( inmagic_column_bar_split_A.join( note_join_string ) ) 
                note_A.push( note_join_string )
            end
        else
            SE.puts "#{csv_input.lineno}, Unknown input column '#{inmagic_column_name.downcase}'"
            SE.q {[ 'input_ROW' ]}
            raise
        end
    end
    note_A.push( "InMagic Conversion 02/11/2025:" )  # This is the first date of the conversion.  #{ Date.today.strftime('%m/%d/%Y')}:" )
    note_A.push( input_ROW.to_h.values.join( ' ! ' ) )
    record_H[ 'accession_general_note' ] = [ note_A + anomaly_A ].join( note_join_string ) 
    if ( anomaly_A.length > 0 ) then
        SE.puts "Anomaly, rec=#{csv_input.lineno}: '#{record_H[ 'accession_title' ]}' #{anomaly_A.join( note_join_string )}"
    end
#   SE.q {[ 'record_H' ]}
    csv_output.puts record_H.values 
end

SE.puts "Duplicate Accession Numbers..."
accession_number_H.each_pair do | k, v |
    next if ( v == 'A' )
    SE.puts "Accession Number #{k}, #{v}"
end


