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
    input_string = ARGV.join(" ")  
else
    SE.puts "No test string found on command line, maybe something like:"
    SE.puts "1939 Feb. 18-Dec. 2, 1939 / 1940 May 25-Sep. 29, 1940"
    SE.puts "Here is the default test..."
    a1 = []
    a1 << "fmt002_a 1980 through 1990"
    a1 << "fmt003_a Feb 9, 1981 through Feb 10, 1981"
    a1 << "fmt004_a Mar 1982 - April-1982"
    a1 << "fmt004_c March 82 through Apr-82"
    a1 << "fmt005_a 1983 Apr - 1983-May"
    a1 << "fmt005_c 83-Apr - 83 May"
    a1 << "fmt006_a 9/May/1984 - 10-May-1984"
    a1 << "fmt006_b 1984/May/9 through 1984-June-10"
    a1 << "fmt006_c 11/May/84 through 8-Jun-84"
    a1 << "fmt008_a Jun 9 - 10, 1985"
    a1 << "fmt008_b Jun 9 - 10, 85"
    a1 << "fmt009_a Jul 8 - Aug 11, 1986"
    a1 << "fmt009_b Jul 11 - Aug 8, 86"
    a1 << "fmt010_a Sep-Oct 1987"
    a1 << "fmt010_b Sep-Oct 87"
    a1 << "fmt013_a 7-1-88 - 7/2/88"
    input_string =""
    input_string += a1.join( " " ) 
    input_string += a1.map{ | e | e.sub(/^fmt\d\d\d_./, '') }.shuffle.join( " and " )
end
SE.puts "input_string  = #{input_string.ai}"

find_dates_O = Find_Dates_in_String.new( {  :morality_replace_option => { :good  => :remove },
                                            :date_string_composition => :only_dates,
                                            :sort => false,
                                         }.merge( cmdln_option_H[ :find_dates_option_H ] ) )
                                   
output_string = find_dates_O.do_find( input_string )

SE.puts "----------------------------------"
SE.puts "output_string = #{output_string.ai}"
SE.puts "----------------------------------"
SE.q { 'find_dates_O.good__date_clump_S__A' }
SE.puts "----------------------------------"
SE.q { 'find_dates_O.bad__date_clump_S__A' }
SE.puts "----------------------------------"
SE.puts "input_string  = #{input_string.ai}"
SE.puts "----------------------------------"
SE.puts "output_string = #{output_string.ai}"
SE.puts "----------------------------------"
SE.q { 'find_dates_O.pattern_cnt_H' }

