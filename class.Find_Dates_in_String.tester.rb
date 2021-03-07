require 'pp'
require 'optparse'
require 'module.Se.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'class.String.extend.rb'
require 'class.Find_Dates_in_String.rb'


BEGIN {}
END {}

myself_name = File.basename( $0 )

cmdln_option_H = {  }
find_dates_in_string_param_H = { }
OptionParser.new do |option|
    option.banner = "Usage: #{myself_name} [options]"
    option.on( "--date_string_composition x", "Should be :only_dates or :dates_in_text" ) do |opt_arg|
        cmdln_option_H[ :date_string_composition ] = opt_arg.sub( /^:/, "").to_sym
        find_dates_in_string_param_H[ :date_string_composition ] = cmdln_option_H[ :date_string_composition ]
    end
    option.on( "--print_good_dates", "Print the good dates too." ) do |opt_arg|
        cmdln_option_H[ :print_good_dates ] = :print_good_dates
        if ( not find_dates_in_string_param_H.key?( :debug_options )) then
            find_dates_in_string_param_H[ :debug_options ] = []
        end
        find_dates_in_string_param_H[ :debug_options ] << cmdln_option_H[ :print_good_dates ]
    end
    option.on( "--print_process_string", "Print the process_string before each pattern match test." ) do |opt_arg|
        cmdln_option_H[ :print_process_string ] = :print_process_string
        if ( not find_dates_in_string_param_H.key?( :debug_options )) then
            find_dates_in_string_param_H[ :debug_options ] = []
        end
        find_dates_in_string_param_H[ :debug_options ] << cmdln_option_H[ :print_process_string ]
    end
    option.on( "-h", "--help" ) do
        warn option
        exit
    end
end.parse!  # Bang because ARGV is altered

$gy = 0             # global year
def ny(  )          # next year
    $gy += 1
    return "%02d" % $gy
end
    
date_S = Struct.new( :date, :pattern_name )
date_A_S = [ ]


date_A_S << date_S.new( "19#{ny} - 19#{ny}", "fmt002__yyyy__double" )
date_A_S << date_S.new( "19#{ny} - #{ny}", "fmt002__yyyy__double" )
date_A_S << date_S.new( "19#{ny}", "fmt002__yyyy__single" )
 
date_A_S << date_S.new( "#{ny}-#{ny}", "fmt001__yy__double" )

date_A_S << date_S.new( "mar. 18, 19#{ny} - may 26, 19#{ny}", "fmt003__MMM_dd_yyyy__double" )
date_A_S << date_S.new( "jun 20, #{ny} - jan 19, 19#{ny}", "fmt003__MMM_dd_yy__double" )

date_A_S << date_S.new( "Oct 17, 19#{ny}", "fmt003__MMM_dd_yyyy__single" )
date_A_S << date_S.new( "Aug 23, #{ny}", "fmt003__MMM_dd_yy__single" )

date_A_S << date_S.new( "mar. 19#{ny} - may  19#{ny}", "fmt003__MMM_yyyy__double" )
date_A_S << date_S.new( "jun  #{ny} - jan  #{ny}", "fmt003__MMM_yy__double" )

date_A_S << date_S.new( "Oct  19#{ny}", "fmt003__MMM_yyyy__single" )
date_A_S << date_S.new( "Aug  #{ny}", "fmt003__MMM_yy__single" )

date_A_S << date_S.new( "mar. - 19#{ny} - may  - 19#{ny}", "fmt005__MMM_yyyy__double" )
date_A_S << date_S.new( "jun - #{ny} - jan - #{ny}", "fmt005__MMM_yy__double" )

date_A_S << date_S.new( "Oct - 19#{ny}", "fmt005__MMM_yyyy__single" )
date_A_S << date_S.new( "Aug - #{ny}", "fmt005__MMM_yy__single" )

date_A_S << date_S.new( "18-jul-19#{ny} - 30-sep-19#{ny}", "fmt004__dd_MMM_yyyy__double" )
date_A_S << date_S.new( "20-oct-#{ny} - 9-mar-#{ny}", "fmt004__dd_MMM_yy__double" )

date_A_S << date_S.new( "18/jul/19#{ny} - 30/sep/19#{ny}", "fmt004__dd_MMM_yyyy__double" )
date_A_S << date_S.new( "20/oct/#{ny} - 9/mar/#{ny}", "fmt004__dd_MMM_yy__double" )

date_A_S << date_S.new( "1-sept-19#{ny}", "fmt004__dd_MMM_yyyy__single" )
date_A_S << date_S.new( "31-Aug-#{ny}", "fmt004__dd_MMM_yy__single" )

date_A_S << date_S.new( "nov 19, 19#{ny}", "fmt003__MMM_dd_yyyy__single" )
date_A_S << date_S.new( "jan 23, #{ny}", "fmt003__MMM_dd_yy__single" )

date_A_S << date_S.new( "jun 28 - 19#{ny}", "fmt006__MMM_dd_yyyy__single" )
date_A_S << date_S.new( "mar 17 - #{ny}", "fmt006__MMM_dd_yy__single" )

date_A_S << date_S.new( "Jan 10 - 15, 19#{ny}", "fmt007__MMM_dd_dd_yyyy" )
date_A_S << date_S.new( "feb 6 - 16, #{ny}", "fmt007__MMM_dd_dd_yy" )

date_A_S << date_S.new( "Jan 10 - dec 15, 19#{ny}", "fmt007__MMM_dd_MMM_dd_yyyy" )
date_A_S << date_S.new( "feb 6 - dec. 16, #{ny}", "fmt007__MMM_dd_MMM_dd_yy" )

date_A_S << date_S.new( "Mar. - Sept 19#{ny}", "fmt008__MMM_MMM_yyyy" )
date_A_S << date_S.new( "April - july #{ny}", "fmt008__MMM_MMM_yy" )

date_A_S << date_S.new( "5/25/19#{ny} - 7/14/19#{ny}", "fmt009__nn_nn_yyyy__double" )
date_A_S << date_S.new( "7/21/19#{ny} - 9/18/#{ny}", "fmt009__nn_nn_yyyy__double" )
date_A_S << date_S.new( "5-25-19#{ny} - 7-14-19#{ny}", "fmt009__nn_nn_yyyy__double" )
date_A_S << date_S.new( "7-21-19#{ny} - 9-18-#{ny}", "fmt009__nn_nn_yyyy__double" )

date_A_S << date_S.new( "6/16/19#{ny}", "fmt009__nn_nn_yyyy__single" )
date_A_S << date_S.new( "6-16-19#{ny}", "fmt009__nn_nn_yyyy__single" )

date_A_S << date_S.new( "19#{ny}/5/25 - 19#{ny}/7/14", "fmt010__yyyy_nn_nn__double" )
date_A_S << date_S.new( "19#{ny}/07/21 - #{ny}/9/18", "fmt010__yyyy_nn_nn__double" )
date_A_S << date_S.new( "19#{ny}-5-25 - 19#{ny}-7-14", "fmt010__yyyy_nn_nn__double" )
date_A_S << date_S.new( "19#{ny}-07-21 - #{ny}-9-18", "fmt010__yyyy_nn_nn__double" )

date_A_S << date_S.new( "19#{ny}/6/16", "fmt010__yyyy_nn_nn__single" )
date_A_S << date_S.new( "19#{ny}-6-16", "fmt010__yyyy_nn_nn__single" )

date_A_S << date_S.new( "7-21-#{ny} - 9-18-#{ny}", "fmt011__nn_nn_nn__double" )    #NOTE:  Fmt011 is for 2 digit years only
date_A_S << date_S.new( "6-16-#{ny}", "fmt011__nn_nn_nn__single" )


puts "Last year: #{$gy}"

temp_A_A = date_A_S + []

# check for dups

date_A_S.each_with_index do | a1_S, a1_idx |
    date_A_S.each_with_index do | a2_S, a2_idx |
      break if ( a1_idx == a2_idx )
        if ( a1_S.pattern_name == a2_S.pattern_name and a1_S.date == a2_S.date ) then
            puts "Duplcates of pattern '#{a1_S.pattern_name}' '#{a1_s.date}'"
        end
    end
end


test_string = ""
date_A_S.shuffle.each do | date_S | 
    test_string += "#{date_S[ 0 ]} "
end
test_string += ""
# test_string += " mar. 18, 1903 - may 26, 1904  - Jun 25, 1920 "    # Test for extra

if ( ARGV.length > 0 ) then 
    test_string = ARGV.join("")  #  " 1939 Feb. 18-Dec. 2, 1939 / 1940 May 25-Sep. 29, 1940 "
    temp_A_A = []
    find_dates_O = Find_Dates_in_String.new( {  :morality_replace_option => { :good  => :remove },
                                                :pattern_name_RE => %r{.} ,
                                                :date_string_composition => :only_dates,
                                                :sort => false,
                                             }.merge( find_dates_in_string_param_H ) )
else
    puts "Test Dates:   ------------------------------------"
    date_A_S.each do | date_S |
        puts "#{'%-30s' % date_S.pattern_name} #{date_S.date}"
    end
    puts "--------------------------------------------------"
    find_dates_O = Find_Dates_in_String.new( {  :morality_replace_option => { :good  => :remove },
                                                :pattern_name_RE => %r{.},
                                                :sort => false,
                                             }.merge( find_dates_in_string_param_H ) )
end
puts "test_string: -------------------------------------"
pp test_string
puts "--------------------------------------------------"

changed_string = find_dates_O.do_find( test_string )

puts "date_RE's in order of search      ----------------"
find_dates_O.date_pattern_RE_A_S.each_with_index do | e_S, idx |
    puts "priority=#{e_S.priority} length=#{'%4d' % e_S.pattern_length} idx=#{'%-2d' % idx} #{e_S.pattern_name}"
end
puts "--------------------------------------------------"

if ( find_dates_O.good_date_A_S.length > 0 ) then
    puts "Good dates --------------------------------------------"
    expected_good_date_A_S = find_dates_O.good_date_A_S + []
    find_dates_O.good_date_A_S.each_with_index do | date_S, idx_1 |
        puts "#{'%-30s' % date_S.pattern_name} idx=#{'%-2d' % idx_1} #{'%-35s' % ('\'' + date_S.pattern_piece_A.join("") + '\'') }" + " date " + date_S[2] + " thru " + date_S[3]
        temp_A_A.each_with_index do | temp_A, idx_2 |
            # puts "temp_A.date = #{temp_A.date}, date_S.pattern_piece_A[ 1 ] = #{date_S.pattern_piece_A[ 1 ]}, temp_A.pattern_name=#{temp_A.pattern_name}, date_S.pattern_name = #{'%-30s' % date_S.pattern_name}" 
            if ( temp_A.date == date_S.pattern_piece_A[ 1 ] and temp_A.pattern_name == date_S.pattern_name ) then
                temp_A_A.delete_at( idx_2 )
                expected_good_date_A_S.each_with_index do | date_S, idx_3 |
                    if ( temp_A.date == date_S.pattern_piece_A[ 1 ] and temp_A.pattern_name == date_S.pattern_name ) then
                        expected_good_date_A_S.delete_at( idx_3 )
                        break
                    end
                end
                break
            end       
        end
    end
    if ( expected_good_date_A_S.length > 0 and temp_A_A.length > 0 ) then
        puts "Unexpected Good dates --------------------------------------"
        expected_good_date_A_S.each_with_index do | date_S, idx_1|
            puts "#{'%-30s' % date_S.pattern_name} idx=#{'%-2d' % idx_1} #{'%-35s' % ('\'' + date_S.pattern_piece_A.join("") + '\'') }" + " date " + date_S[2] + " thru " + date_S[3]
        end
    end
    puts "-------------------------------------------------------"
end

if ( find_dates_O.bad_date_A_S.length > 0 ) then
    puts "Bad dates --------------------------------------------"
    expected_bad_date_A_S = find_dates_O.bad_date_A_S + []
    find_dates_O.bad_date_A_S.each_with_index do | date_S, idx_1 |
        puts "#{'%-30s' % date_S.pattern_name} idx=#{'%-2d' % idx_1} #{'%-35s' % ('\'' + date_S.pattern_piece_A.join("") + '\'') }" + " date " + date_S[2] + " thru " + date_S[3]
        temp_A_A.each_with_index do | temp_A, idx_2 |
            # puts "temp_A.date = #{temp_A.date}, date_S.pattern_piece_A[ 1 ] = #{date_S.pattern_piece_A[ 1 ]}, temp_A.pattern_name=#{temp_A.pattern_name}, date_S.pattern_name = #{'%-30s' % date_S.pattern_name}" 
            if ( temp_A.date == date_S.pattern_piece_A[ 1 ] and temp_A.pattern_name == date_S.pattern_name ) then
                temp_A_A.delete_at( idx_2 )
                expected_bad_date_A_S.each_with_index do | date_S, idx_3 |
                    if ( temp_A.date == date_S.pattern_piece_A[ 1 ] and temp_A.pattern_name == date_S.pattern_name ) then
                        expected_bad_date_A_S.delete_at( idx_3 )
                        break
                    end
                end
                break
            end       
        end
    end
    if ( expected_bad_date_A_S.length > 0 and temp_A_A.length > 0 ) then
        puts "Unexpected bad dates --------------------------------------"
        expected_bad_date_A_S.each_with_index do | date_S, idx_1|
            puts "#{'%-30s' % date_S.pattern_name} idx=#{'%-2d' % idx_1} #{'%-35s' % ('\'' + date_S.pattern_piece_A.join("") + '\'') }" + " date " + date_S[2] + " thru " + date_S[3]
        end
    end
    puts "-------------------------------------------------------"
end

if ( temp_A_A.length > 0 ) then
    puts " missed these combination  ----------------"
    temp_A_A.each do | temp_A |
        puts "#{temp_A[1]} #{temp_A[0]}"
        find_dates_O.good_date_A_S.each do | date_S |
            if ( temp_A.date == date_S.pattern_piece_A[ 1 ] ) then
                puts "          , but found it in 'good' as '#{'%-30s' % date_S.pattern_name}'"
            end
        end
        find_dates_O.bad_date_A_S.each do | date_S |
            if ( temp_A.date == date_S.pattern_piece_A[ 1 ] ) then
                puts "          , but found it in 'bad'  as '#{'%-30s' % date_S.pattern_name}'"
            end
        end       
    end
    puts " ------------------------------------------"
end
puts "--------------------------------------------------"
puts "test_string:"
pp test_string
puts "--------------------------------------------------"
puts "changed_string:"
pp changed_string
