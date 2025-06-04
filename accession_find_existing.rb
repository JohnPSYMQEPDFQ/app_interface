#!run_ruby.sh

require 'module.SE.rb'
require 'csv.rb'
require 'optparse'

module Main_Global_Variables
#       Instead of easily mistyped instance-variables, we can do this...
        attr_accessor :cmdln_option_H, :myself_name
end
include Main_Global_Variables
#       But not sure why it needs to be in a module...

myself_name = File.basename( $0 )
cmdln_option_H = { :input_col_sep => ',',
                 }
                  
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options] existing_accessions.csv file_to_check.csv"

    option.on( "-i --input_col_sep x", "The :col_sep value for the CSV input." ) do | opt_arg |
        cmdln_option_H[ :input_col_sep ] = opt_arg
    end
   
    option.on( '-?, -h, --help', "This help" ) do
        $stderr.puts option
        exit 1
    end
end.parse!  # Bang because ARGV is altered

if ( ARGV.length != 2 ) then
    raise "Was expecting two files. Try: '#{myself_name} --help'"
end

existing_accession_H = {}
csv_input = CSV.new( File::open( ARGV[ 0 ]), headers: true, col_sep: cmdln_option_H[ :input_col_sep ] )
csv_input.each do | input_ROW |
    existing_accession_H[ input_ROW[ 'identifier' ] ] = true
end
csv_input = CSV.new( File::open( ARGV[ 1 ]), headers: true, col_sep: cmdln_option_H[ :input_col_sep ] )
csv_input.each do | input_ROW |
    if ( existing_accession_H.has_key?( input_ROW[ 'accession_number_1' ] ) ) then
        SE.puts '================================='
        SE.q {[ 'input_ROW.to_h.compact' ]}
    end
end




