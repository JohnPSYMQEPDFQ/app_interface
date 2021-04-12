require 'pp'
require 'awesome_print'
require 'optparse'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'class.String.extend.rb'
require 'class.Find_Dates_in_String.rb'



BEGIN {}
END {}

binding.pry if ( respond_to? :pry )
myself_name = File.basename( $0 )


cmdln_option_H = { :find_dates_option_H => { },
                 }

OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options]"
    option.on( "-f", "--find_dates_option_H x", "Option Hash passed to the Find_Dates_in_String class." ) do |opt_arg|
        begin
            cmdln_option_H[ :find_dates_option_H ] = eval( opt_arg ).merge
        rescue Exception => msg
            SE.puts ""
            SE.puts msg
            SE.ap "Find_Dates_in_String default options:"
            SE.ap Find_Dates_in_String.new( ).option_H
            exit
        end
    end
    option.on( "-h", "--help" ) do
        SE.puts option
        SE.puts ""
        SE.puts "Find_Dates_in_String default options:".ai
        SE.puts Find_Dates_in_String.new( ).option_H.ai
        SE.puts ""
        SE.puts "Note that:  The --file_dates_option_H numeric values have to be quoted (no integers), eg."
        SE.puts "            #{myself_name} -find_date_option_H '{ :default_century => \"20\" }' file"
        exit
    end
end.parse!  # Bang because ARGV is altered



if ( ARGV.length > 0 ) then 
    input_string = ARGV.join(" ")  #  " 1939 Feb. 18-Dec. 2, 1939 / 1940 May 25-Sep. 29, 1940 "
    find_dates_O = Find_Dates_in_String.new( {  :morality_replace_option => { :good  => :remove },
                                                :date_string_composition => :only_dates,
                                                :sort => false,
                                             }.merge( cmdln_option_H[ :find_dates_option_H ] ) )
else
    SE.puts "No dates found on command line"
    exit
end

SE.puts "input_string = #{input_string.ai}"

output_string = find_dates_O.do_find( input_string )

SE.puts "output_string = #{output_string.ai}"

SE.q { 'find_dates_O.good_date_clump_S_A' }
SE.q { 'find_dates_O.bad_date_clump_S_A' }


