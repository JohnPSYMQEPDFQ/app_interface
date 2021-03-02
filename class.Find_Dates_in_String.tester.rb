require 'pp'
require 'module.Se.rb'
require 'module.ArchivesSpace.Konstants.rb'
require 'pp'
require 'module.Se.rb'
require 'class.String.extend.rb'
require 'class.Find_Dates_in_String.rb'


BEGIN {}
END {}

date_A_A = [ ]

date_A_A << [ 'mar. 18, 1903 - may 26, 1904', 'fmt001__mmm_dd_yyyy__double' ]
date_A_A << [ 'jun 20, 05 - jan 19, 06', 'fmt001__mmm_dd_yy__double' ]

date_A_A << [ 'Oct 17, 1907', 'fmt001__mmm_dd_yyyy__single' ]
date_A_A << [ 'Aug 23, 08', 'fmt001__mmm_dd_yy__single' ]

date_A_A << [ 'mar. 1909 - may  1910', 'fmt001__mmm_yyyy__double' ]
date_A_A << [ 'jun  11 - jan  12', 'fmt001__mmm_yy__double' ]

date_A_A << [ 'Oct  1913', 'fmt001__mmm_yyyy__single' ]
date_A_A << [ 'Aug  14', 'fmt001__mmm_yy__single' ]
 
date_A_A << [ '1915 - 1916', 'fmt001__yyyy__double' ]
date_A_A << [ '1917 - 18', 'fmt001__yyyy__double' ]
date_A_A << [ '1919', 'fmt001__yyyy__single' ]
 
date_A_A << [ '20-21', 'fmt001__yy__double' ]

date_A_A << [ 'mar. - 1922 - may  - 1923', 'fmt002__mmm_yyyy__double' ]
date_A_A << [ 'jun - 24 - jan - 25', 'fmt002__mmm_yy__double' ]

date_A_A << [ 'Oct - 1926', 'fmt002__mmm_yyyy__single' ]
date_A_A << [ 'Aug - 27', 'fmt002__mmm_yy__single' ]

date_A_A << [ '18-jul-1928 - 30-sep-1929', 'fmt002__dd_mmm_yyyy__double' ]
date_A_A << [ '20-oct-30 - 9-mar-31', 'fmt002__dd_mmm_yy__double' ]

date_A_A << [ '1-sept-1932', 'fmt002__dd_mmm_yyyy__single' ]
date_A_A << [ '31-Aug-33', 'fmt002__dd_mmm_yy__single' ]

date_A_A << [ 'nov 19, 1934', 'fmt001__mmm_dd_yyyy__single' ]
date_A_A << [ 'jan 23, 35', 'fmt001__mmm_dd_yy__single' ]

date_A_A << [ 'jun 28 - 1936', 'fmt003__mmm_dd_yyyy__single' ]
date_A_A << [ 'mar 17 - 37', 'fmt003__mmm_dd_yy__single' ]

date_A_A << [ 'Jan 10 - 15, 1938', 'fmt004__mmm_dd_dd_yyyy' ]
date_A_A << [ 'feb 6 - 16, 39', 'fmt004__mmm_dd_dd_yy' ]


temp_A_A = date_A_A + []

# check for dups
dups = false
date_A_A.each_with_index do | a1_A, a1_idx |
    date_A_A.each_with_index do | a2_A, a2_idx |
      break if ( a1_idx == a2_idx )
        if ( a1_A[ 0 ] == a2_A[ 0 ] and a1_A[ 1 ] == a2_A[ 1 ] ) then
            puts "Duplcates at #{a1_idx} and #{a2_idx}"
            dups = true
        end
    end
end
exit if ( dups ) 

test_string = ""
date_A_A.shuffle.each_with_index do | date_A, idx | 
    test_string += "#{date_A[ 0 ]} "
end
test_string += ""

find_dates_O = Find_Dates_in_String.new( { :date_morality => { :good  => :remove },
                                           :pattern_name_RE_A => [ %r{.} ] } )
    
test_string += " mar. 18, 1903 - may 26, 1904  - Jun 25, 1920 "
if ( true == false ) then # do a simple test
    test_string = " 01-mar-46"
    temp_A_A = []
end
pp test_string

changed_string = find_dates_O.do_find( test_string )

puts "date_RE's in reverse length order ----------------"
find_dates_O.date_pattern_RE_A_S.each_with_index do | e_S, i |
    puts "priority=#{e_S.priority} length=#{e_S.length} #{e_S.pattern_name} #{i}"
end
puts "---------------------------------------------------"

if ( find_dates_O.good_date_A_S? ) then
    puts "Good dates --------------------------------------------"
    find_dates_O.good_date_A_S.each do | good_date_A |
        pattern_name = good_date_A.pattern_name
        date_pattern_RE_A_idx = find_dates_O.date_pattern_RE_H[ pattern_name ]
        pattern_length = find_dates_O.date_pattern_RE_A_S[ date_pattern_RE_A_idx ].length
        
        puts "#{pattern_name} (idx=#{date_pattern_RE_A_idx}, len=#{pattern_length}) '#{good_date_A.pattern_piece_A.join("")}'" + " date " + good_date_A[2] + " thru " + good_date_A[3]
        temp_A_A.each_with_index do | temp_A, idx |
            # puts "temp_A[ 0 ] = #{temp_A[ 0 ]}, good_date_A.pattern_piece_A[ 1 ] = #{good_date_A.pattern_piece_A[ 1 ]}, temp_A[ 1 ]=#{temp_A[ 1 ]}, good_date_A.pattern_name = #{good_date_A.pattern_name}" 
            if ( temp_A[ 0 ] == good_date_A.pattern_piece_A[ 1 ] and temp_A[ 1 ] == good_date_A.pattern_name ) then
                temp_A_A.delete_at( idx )
                break
            end       
        end
    end
    puts "-------------------------------------------------------"
end

if ( find_dates_O.bad_date_A_S? ) then
    puts "bad dates --------------------------------------------"
    find_dates_O.bad_date_A_S.each do | bad_date_A |
        pattern_name = bad_date_A.pattern_name
        date_pattern_RE_A_idx = find_dates_O.date_pattern_RE_H[ pattern_name ]
        pattern_length = find_dates_O.date_pattern_RE_A_S[ date_pattern_RE_A_idx ].length
        puts "#{pattern_name} (idx=#{date_pattern_RE_A_idx}, len=#{pattern_length}) '#{bad_date_A.pattern_piece_A.join("")}'" + " date " + bad_date_A[2] + " thru " + bad_date_A[3]
        temp_A_A.each_with_index do | temp_A, idx |
            if ( temp_A[ 0 ] == bad_date_A.pattern_piece_A[ 1 ] and temp_A[ 1 ] == bad_date_A.pattern_name ) then
                temp_A_A.delete_at( idx )
                break
            end       
        end
    end
    puts "-------------------------------------------------------"
end

if ( temp_A_A.length > 0 ) then
    puts " missed these combination  ----------------"
    temp_A_A.each do | temp_A |
        puts "#{temp_A[1]} #{temp_A[0]}"
        find_dates_O.good_date_A_S.each do | date_S |
            if ( temp_A[ 0 ] == date_S.pattern_piece_A[ 1 ] ) then
                puts "          , but found it in 'good' as '#{date_S.pattern_name}'"
            end
        end
        find_dates_O.bad_date_A_S.each do | date_S |
            if ( temp_A[ 0 ] == date_S.pattern_piece_A[ 1 ] ) then
                puts "          , but found it in 'bad'  as '#{date_S.pattern_name}'"
            end
        end       
    end
    puts " ------------------------------------------"
end
pp test_string
pp changed_string
