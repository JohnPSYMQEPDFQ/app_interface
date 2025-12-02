# frozen_string_literal: true

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
formatter_morality_option = '{ :morality_replace_option => { :bad => :keep, :good => :remove_from_end } }'
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options]"
    option.on( "-f", "--formatter", "Short for --find_dates_option_H '#{formatter_morality_option}' " ) do 
        begin
            SE.q {'cmdln_option_H[ :find_dates_option_H ]'}
            thing = eval( formatter_morality_option ).to_h
            cmdln_option_H[ :find_dates_option_H ].update( thing )
        rescue Exception => msg
            SE.puts ''
            SE.puts msg
            SE.ap "Find_Dates_in_String default options:"
            SE.ap Find_Dates_in_String.new( ).option_H
            exit
        end
    end
    option.on( "--find_dates_option_H x", "Option Hash passed to the Find_Dates_in_String class." ) do | opt_arg |
        begin
            thing = eval( opt_arg )
            cmdln_option_H[ :find_dates_option_H ].update( thing )
        rescue Exception => msg
            SE.puts ''
            SE.puts msg
            SE.ap "Find_Dates_in_String default options:"
            SE.ap Find_Dates_in_String.new( ).option_H
            exit
        end
    end
    option.on( "-h", "--help" ) do
        SE.puts option
        SE.puts ''
        SE.puts "Find_Dates_in_String default options:".ai
        SE.puts Find_Dates_in_String.new( ).option_H.ai
        SE.puts ''
        SE.puts "Note that:  The --file_dates_option_H numeric values have to be quoted (no integers), eg."
        SE.puts "            #{myself_name} --find_date_option_H '{ :default_century_pivot_ccyymmdd => \"19\" }' file"
        SE.puts ''
        SE.puts "            The :debug_options require a hash-in-a-hash, as follow:"
        SE.puts "            #{myself_name} -f '{ :debug_options => { :print_date_tree => true } }'"
        exit
    end
end.parse!  # Bang because ARGV is altered



if ( ARGV.length > 0 ) then 
    input_string = ARGV.join(' ')  
elsif ( $stdin.stat.pipe? ) then
    SE.puts "No test string found on command line, input from pipe..."
    input_string = ARGF.each_line.to_a.join( ' ' ).chomp
else
    SE.puts "No test string found on command line, maybe something like:"
    SE.puts "'1939 Feb. 18-Dec. 2, 1939 and 1940 May 25-Sep. 29, 1940'"
    SE.puts "Here is the default test..."
    a1 = []
    a1 << "fmt002_a 1980 through 1990"
    a1 << "fmt003_a Feb 9, 1981 to Feb 10, 1981"
    a1 << "fmt005_a Mar 1982 - April-1982"
    a1 << "fmt005_c March 82 through Apr-82"
    a1 << "fmt006_a 4-1982 - 05-1982"
    a1 << "fmt007_a 1983 Apr - 1983-May"
    a1 << "fmt007_c 83-Apr - 83 May"
    a1 << "fmt008_a 1983-04 - 1983-5"
    a1 << "fmt009_a 9/May/1984 - 10-May-1984"
    a1 << "fmt009_b 1984/May/9 to 1984-June-10"
    a1 << "fmt009_c 11/May/84 through 8-Jun-84"
    a1 << "fmt011_a Jun 9 - 10, 1985"
    a1 << "fmt011_b Jun 9 - 10, 85"
    a1 << "fmt012_a Jul 8 - Aug 11, 1986"
    a1 << "fmt012_b Jul 11 - Aug 8, 86"
    a1 << "fmt013_a Sep-Oct 1987"
    a1 << "fmt013_b Nov-Dec 87"
    a1 << "fmt014_a 7-1-88 - 7/2/88"
    input_string = +''
    input_string << a1.shuffle.join( ' ' )
    input_string << a1.map{ | e | e.sub(/^fmt\d\d\d_./, '') }.shuffle.join( " and " )
end

expected_cnt_H = {                      #  As-of 11/19/2024
                  "fmt002__yyyy" => 4,
           "fmt003__MMM_dd_yyyy" => 4,
              "fmt005__MMM_yyyy" => 8,
               "fmt006__mm_yyyy" => 4,
              "fmt007__yyyy_MMM" => 8,
               "fmt008__yyyy_mm" => 4,
             "fmt009__nn_MMM_nn" => 12,
        "fmt011__MMM_dd_dd_yyyy" => 4,
    "fmt012__MMM_dd_MMM_dd_yyyy" => 4,
          "fmt013__MMM_MMM_yyyy" => 4,
              "fmt014__nn_nn_nn" => 4,
    }

SE.puts "input_string  = #{input_string.ai}"
find_dates_O = Find_Dates_in_String.new( {  :morality_replace_option => { :good  => :remove },
                                            :date_string_composition => :dates_in_text,
#                                           :default_century_pivot_ccyymmdd => '1900',
                                            :sort => false,
                                         }.update( cmdln_option_H[ :find_dates_option_H ] ) )

# SE.pom( find_dates_O )
# SE.pov( find_dates_O )
SE.q {[ 'find_dates_O.option_H' ]}                                                  
                                           
output_string = find_dates_O.do_find( input_string )
#utput_string = find_dates_O.do_find( input_string )      # This tests if two calls to :do_file is broken.


SE.puts "----------------------------------"
SE.puts "output_string = #{output_string.ai}"
SE.puts "=============================================================================="
SE.puts "Total good dates: #{find_dates_O.good__date_clump_S__A.length}"
SE.puts "----------------------------------"
SE.q { 'find_dates_O.good__date_clump_S__A' }
SE.puts "----------------------------------"
SE.puts "Total good dates: #{find_dates_O.good__date_clump_S__A.length}"
SE.puts "=============================================================================="
SE.puts "Total bad dates: #{find_dates_O.bad__date_clump_S__A.length}"
SE.puts "----------------------------------"
SE.q { 'find_dates_O.bad__date_clump_S__A' }
SE.puts "----------------------------------"
SE.puts "Total bad dates: #{find_dates_O.bad__date_clump_S__A.length}"
SE.puts "=============================================================================="
SE.puts "input_string  = #{input_string.ai}"
SE.puts "----------------------------------"
SE.puts "output_string = #{output_string.ai}"
SE.puts "----------------------------------"
SE.puts "Total good dates: #{find_dates_O.good__date_clump_S__A.length}"
SE.puts "----------------------------------"
SE.puts "Total bad dates: #{find_dates_O.bad__date_clump_S__A.length}"
SE.puts "----------------------------------"
find_dates_O.pattern_cnt_H.each_pair do | k, v |
    print "%30s" % k + " => #{v}"
    if ( expected_cnt_H.has_key?( k ) ) then
        if ( ARGV.empty? and v != expected_cnt_H[ k ] ) then
            puts " expected #{expected_cnt_H[ k ]}"
        else
            puts ''
        end
    else
        puts " unexpected key" + k
    end
end   


if ( cmdln_option_H[ :find_dates_option_H ].nil? or cmdln_option_H[ :find_dates_option_H ][:default_century_pivot_ccyymmdd].nil? ) then
    SE.puts "Finding 4 digit dates only !!!!!!!!"
    SE.puts "Set --find_date_option_H '{ :default_century_pivot_ccyymmdd => \"19\" }' to include 2 digit dates."
else
    SE.puts ''
    SE.puts "Finding 2 and 4 digit dates."
end
if ( ARGV.not_empty? ) then
    SE.puts "Set -f to mimic the formatter program's option of:"
    SE.puts "#{formatter_morality_option}"
end







