=begin

    This will convert a query into a spreadsheet.
    As it is now, only queries that work with uri's like /thing/:repo or /thing will work.
       

=end

require 'json'
require 'optparse'
require 'csv'

require 'class.Archivesspace.rb'
require 'class.Archivesspace.ArchivalObject.rb'
require 'class.Archivesspace.Repository.rb'
require 'class.Archivesspace.Resource.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option_H = { :rep_num => nil,
                   :res_num => nil,
                   :type => nil,
                   :leading_columns_only => false,
                   :comparison_filter => false,
                  }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Filter on Repository n." ) do |opt_arg|
        cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Filter on Resource n." ) do |opt_arg|
        cmdln_option_H[ :res_num ] = opt_arg
        if ( cmdln_option_H[ :rep_num ].nil? ) then
            SE.puts "The --res-num option needs the --rep-num option set first."
            SE.q {'cmdln_option_H'}
            exit 1
        end
    end
    option.on( "--type X", "Type of records to query (required), e.g. LOCATIONS" ) do |opt_arg|
        cmdln_option_H[ :type ] = opt_arg
    end
    option.on( "--lco", "--leading-columns-only", "Only output the 'leading_column_A' fields." ) do |opt_arg|
        cmdln_option_H[ :leading_columns_only ] = true
    end
    option.on( "--cf", "--filter", "--comparison-filter", "Apply the comparison-filter to the output." ) do |opt_arg|
        cmdln_option_H[ :comparison_filter ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit
    end
end.parse!  # Bang because ARGV is altered
SE.q { 'cmdln_option_H' }
if ( cmdln_option_H[ :type ].nil? ) then
    SE.puts "No --type option provided.  This is required."
    SE.q {'cmdln_option_H'}
    exit 1
end

header_separator = '=>'

aspace_O = ASpace.new
case true
when cmdln_option_H[ :res_num ].not_nil?  then
    rep_O = Repository.new( aspace_O, cmdln_option_H[ :rep_num ] )
    res_O = Resource.new( rep_O, cmdln_option_H[ :res_num ] )
    query_O = res_O.query( cmdln_option_H[ :type ].downcase ).record_H_A__all
when cmdln_option_H[ :rep_num ].not_nil?  then
    rep_O = Repository.new( aspace_O, cmdln_option_H[ :rep_num ] )
    query_O = rep_O.query( cmdln_option_H[ :type ].downcase ).record_H_A__all
else
    query_O = aspace_O.query( cmdln_option_H[ :type ].downcase ).record_H_A__all
end

header_H = {}
composite_key_record_A = []
query_O.result_A.each do | record_H |
    hash = record_H.deep_yield( yield_to: [ Hash ] ) do | y | 
                    if ( cmdln_option_H[ :comparison_filter ] == true ) then
                        y.reject { | key, value | K.comparison_filter_A.include?( key ) } 
                    else
                        y
                    end
                    end.deep_yield { | y | y.to_composite_key_h }
                       .transform_keys { | k | k.join( header_separator ) }
    composite_key_record_A << hash
    hash.each_key do | key | 
        stringer = key
        next if ( header_H.has_key?( stringer ) )
        header_H[ stringer ] = stringer.length
    end
end

case cmdln_option_H[ :type ]
when LOCATIONS
    leading_column_A = %w( building floor room area 
                           coordinate_1_label coordinate_1_indicator
                           coordinate_2_label coordinate_2_indicator
                           coordinate_3_label coordinate_3_indicator
                           title
                           uri
                          )
else
    leading_column_A = []
end
if ( leading_column_A.empty? ) then
    if ( cmdln_option_H[ :leading_columns_only ] == true ) then
        SE.puts "#{SE.lineno}: ============================================"
        SE.puts "The leading-columns-only option is set, but"
        SE.puts "'leading_column_A' is empty!"
        exit
    end
    header_A = header_H.keys.sort
else
    header_A = leading_column_A 
    if ( cmdln_option_H[ :leading_columns_only ] == false ) then
        header_A.concat( header_H.keys.sort - leading_column_A )
    else
        arr = header_A - header_H.keys.sort
        if ( arr.not_empty? ) then
            SE.puts "Columns missing from leading_column_A: #{arr.join(',')}"
            SE.puts "The --filter option is on!" if ( cmdln_option_H[ :comparison_filter ] )
            SE.puts ''
        end        
    end
end
SE.puts "Columns available: #{header_H.keys.sort.join(',')}"
SE.puts ''
SE.puts "Columns used:      #{header_A.join(',')}"

CSV do | csv_O |                    # <<<  Defaults to stdout.  'CSV.open( $stdout )' didn't work.
    csv_O << header_A
    composite_key_record_A.each do | record_H |    
        csv_O << record_H.values_at( *header_A ) 
    end
end









