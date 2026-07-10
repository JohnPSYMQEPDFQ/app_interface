=begin

    This will convert a query into a spreadsheet.
    As it is now, only queries that work with uri's like /thing/:repo or /thing will work.
    
    If you get a "{\"error\":\"Sinatra::NotFound\"}\n" error, it could be because
    the --rep-num is needed.  For example, a LOCATIONS query doesn't need a repository, but
    a RESOURCE query does.   By default the :rep-num is nil (unlike most programs that default to 2).
       
    To get specific columns (that aren't already programmed), you can used the 'line' program.   
        line --list-column-numbers  : will show the column names
        line --column column-list   : allows for specific columns to be selected
            e.g.: ... archivesspace.all_records.to_csv.rb --rep 2 --type resources | line -column id_0,title
            
=end

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
                   :separator_for_CKA_headers => '.',
                   :programmed_column_list => nil,      # Set using --type logic
                   :append_at_end => false,
                   :comparison_filter => false,
                   :column_header_info => false,
                  }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [ options ]"
    option.on( "--rep-num n", OptionParser::DecimalInteger, "Filter on Repository n." ) do |opt_arg|
        cmdln_option_H[ :rep_num ] = opt_arg
    end
    option.on( "--res-num n", OptionParser::DecimalInteger, "Filter on Resource n." ) do |opt_arg|
        cmdln_option_H[ :res_num ] = opt_arg
        if ( cmdln_option_H[ :rep_num ].nil? ) then
            cmdln_option_H[ :rep_num ] = 2
        end
    end
    option.on( "--type X", "Type of record to query (in lowercase) or the pre-programmed set of columns to use (in UPPERCASE)" ) do |opt_arg|
        cmdln_option_H[ :type ] = opt_arg
        case true
        when opt_arg == opt_arg.upcase 
            cmdln_option_H[ :programmed_column_list ] = true
        when opt_arg == opt_arg.downcase
            cmdln_option_H[ :programmed_column_list ] = false
        else
            SE.puts "The --type value should be all upper or lowercase, not '#{opt_arg}'"
            SE.puts "All uppercase is for the programmed column selections."
            SE.puts "All lowercase is for all the fields of the record."
            exit 1
        end
    end
    option.on( "--app", "--append-at-end", "For a programmed column list, append the rest of the columns to the end." ) do |opt_arg|
        cmdln_option_H[ :append_at_end ] = true
    end
    option.on( "--sep X", "Separator for CKA headers, default is '.'" ) do |opt_arg|
        cmdln_option_H[ :separator_for_CKA_headers ] = opt_arg
    end
    option.on( "--cf", "--filter", "--comparison-filter", "Apply the comparison-filter to the output." ) do |opt_arg|
        cmdln_option_H[ :comparison_filter ] = true
    end
    option.on( "--chi", "--column-header-info", "Output column header info to STDERR." ) do |opt_arg|
        cmdln_option_H[ :column_header_info ] = true
    end
    option.on( "-h","--help" ) do
        SE.puts option
        exit 1
    end
end.parse!  # Bang because ARGV is altered
SE.q { 'cmdln_option_H' }
if ( cmdln_option_H[ :type ].nil? ) then
    SE.puts "No --type option provided.  This is required."
    exit 1
end
SE.raise if ( cmdln_option_H[ :programmed_column_list ].nil? )

#  The programmed column selection option should be in UPPER CASE.  
case cmdln_option_H[ :type ]
when "FOR_LOCATION_SYNC"        #   This is used to create the CSRM location file used 
                                #   as input to 'archivesspace.location_csv.sync.rb'
    cmdln_option_H[ :type ] = 'locations'
    programmed_column_selection_A = %w( building floor room area 
                                        coordinate_1_label coordinate_1_indicator
                                        coordinate_2_label coordinate_2_indicator
                                        coordinate_3_label coordinate_3_indicator
                                        title
                                        uri
                                       )
else
    programmed_column_selection_A = []
end
if ( cmdln_option_H[ :programmed_column_list ] && programmed_column_selection_A.empty? ) 
    SE.puts "No column selection of --type '#{cmdln_option_H[ :type ]}' programmed!"
    raise
end

aspace_O = ASpace.new
SE.puts 'Starting query...'
case true
when cmdln_option_H[ :res_num ].not_nil?  then
    rep_O = Repository.new( aspace_O, cmdln_option_H[ :rep_num ] )
    res_O = Resource.new( rep_O, cmdln_option_H[ :res_num ] )
    record_H_A = res_O.query( cmdln_option_H[ :type ].downcase ).record_H_A
when cmdln_option_H[ :rep_num ].not_nil?  then
    rep_O = Repository.new( aspace_O, cmdln_option_H[ :rep_num ] )
    record_H_A = rep_O.query( cmdln_option_H[ :type ].downcase ).record_H_A
else
    record_H_A = aspace_O.query( cmdln_option_H[ :type ].downcase ).record_H_A
end

header_H = {}
record_CKA = []
record_H_A.each do | record_H |
    hash = record_H.deep_yield do | y | 
                    if ( y.is_a?( Hash ) && cmdln_option_H[ :comparison_filter ] == true ) then
                        y.reject { | key, value | K.comparison_filter_A.include?( key ) } 
                    else
                        y
                    end
                    end.to_CKA_h 
                       .transform_keys do | ck_A | 
                            SE.raise if ( ck_A.any? { | ck | ck.is_a?( String ) &&
                                                             ck.include?( cmdln_option_H[ :separator_for_CKA_headers ] ) } )
                            ck_A.join( cmdln_option_H[ :separator_for_CKA_headers ] ) 
                        end
                            
    record_CKA << hash
    hash.each_key do | key | 
        next if ( header_H.has_key?( key ) )
        header_H[ key ] = key.length
    end
end

SE.puts ''
if ( programmed_column_selection_A.empty? ) then
    header_A = header_H.keys.sort
    SE.puts "The --app option is ignored for record queries!" if ( cmdln_option_H[ :append_at_end ] )
else
    header_A = programmed_column_selection_A 
    if ( cmdln_option_H[ :append_at_end ] == true ) then
        header_A.concat( header_H.keys.sort - programmed_column_selection_A )
    else
        arr = header_A - header_H.keys.sort
        if ( arr.not_empty? ) then
            SE.puts "Columns missing from programmed_column_selection_A: #{arr.join(',')}"
            SE.puts "The --filter option is on!" if ( cmdln_option_H[ :comparison_filter ] )
            SE.puts ''
        end        
    end
    if ( cmdln_option_H[ :column_header_info ] == true ) then
        SE.puts "Columns available: #{header_H.keys.sort.join(',')}"
        SE.puts ''
        SE.puts "Columns used:      #{header_A.sort.join(',')}"
        SE.puts ''
    end
end
if ( cmdln_option_H[ :column_header_info ] == true ) then
    SE.puts "Column order:      #{header_A.join(',')}"
    SE.puts ''
end

SE.puts "Total columns:     #{header_A.length}"
SE.puts "Total records:     #{record_CKA.length}"
SE.puts ''
CSV do | csv_O |                    # <<<  Defaults to stdout.  'CSV.open( $stdout )' didn't work.
    csv_O << header_A
    record_CKA.each do | record_H |    
        csv_O << record_H.values_at( *header_A ) 
    end
end









