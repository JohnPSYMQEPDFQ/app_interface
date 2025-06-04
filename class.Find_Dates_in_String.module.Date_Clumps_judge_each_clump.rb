#   Part of class.Find_Dates_in_String.rb

module Date_Clumps_judge_each_clump
    
    def date_clumps_judge_each_clump( )
        date_clump_S__A.each do | date_clump_S |

            date_clump_S.date_match_S__A.each_with_index do | date_match_S, date_match_idx |

                year   = date_match_S.ymd_S.year
                month  = date_match_S.ymd_S.month
                day    = date_match_S.ymd_S.day
                
                if ( year.nil? or ( month.nil? and day )) then
                    SE.puts "#{SE.lineno}: I shouldn't be here: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                         "'#{date_match_S.all_pieces}' -> "+
                                         "'#{date_match_S.piece( 1 )}' year.nil? or ( month.nil? and day)!"
                    SE.q { 'date_clump_S' }
                    raise
                end
                
                if ( day and day.integer? and day.length == 4 and year.length.between?( 1, 2 ) ) then       
                    stringer = "#{SE.lineno}: Swapped day and year: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+                                            
                                            "'#{date_match_S.piece( 1 )}' -> " + year + ' ' + month + ' ' + day
                    date_clump_S.judge_date( nil, stringer )
                    year, day               = day, year
                    date_match_S.ymd_S.year = year
                    date_match_S.ymd_S.day  = day
                end
                
                if ( year.length == 1 or year.length == 3 ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' bad year."
                    SE.puts "#{SE.lineno}: #{original_text}"                        
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( month and month.integer? and month.length == 3 ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' bad month."
                    date_clump_S.judge_date( :bad, stringer )
                    SE.puts "#{SE.lineno}: #{original_text}"
                    next
                end

                if ( year.length == 4 )
                    if ( year < option_H[ :yyyymmdd_min_value].year.to_s ) then
                        stringer = "#{SE.lineno}: Date dropped: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                                "'#{date_match_S.all_pieces}' -> "+
                                                "'#{date_match_S.piece( 1 )}' year < min value #{option_H[ :yyyymmdd_min_value]}"
                        SE.puts "#{SE.lineno}: #{original_text}"
                        date_clump_S.judge_date( :bad, stringer )
                        next
                    end
                    if ( year > option_H[ :yyyymmdd_max_value].year.to_s ) then
                        stringer = "#{SE.lineno}: Date dropped: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                                "'#{date_match_S.all_pieces}' -> "+
                                                "'#{date_match_S.piece( 1 )}' year > max value #{option_H[ :yyyymmdd_max_value]}"
                        SE.puts "#{SE.lineno}: #{original_text}"
                        date_clump_S.judge_date( :bad, stringer )
                        next
                    end
                end
                if ( day and day.not_integer? ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' day not numeric: '#{day}'"
                    SE.puts "#{SE.lineno}: #{original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( year.not_integer? ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' year not numeric: '#{year}'"
                    SE.puts "#{SE.lineno}: #{original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( year.length == 2 ) then
                    if ( date_match_idx == 0 ) then
                        year = option_H[ :default_century_pivot_ccyymmdd ].year.to_s[ 0, 2 ] + year  # option_H[ :default_century_pivot_ccyymmdd ] is a strptime_O
                    else
                        if ( date_clump_S.from.strptime_O ) then
                            year = date_clump_S.as_from_date[ 0, 2 ] + year                   # Take the century from the converted from_year, which is already in YYYY format
                        else
                            year = option_H[ :default_century_pivot_ccyymmdd ].year.to_s[ 0, 2 ] + year          
                        end
                    end
                end

                if ( month and month.not_integer? ) then
                    # month_match_O = month.match( /^(?<month_M>#{K.alpha_month_RES})/ )  # Only need for 'soft months' , which isn't programmed
                    # if ( not month_match_O.nil? ) then
                        # month_named_captures = month_match_O.named_captures
                        # month = month_named_captures[ 'month_M' ]
                    # end
                    month.sub!( /\.$/, '' )                         # Take the period off the months (eg Feb.)
                end

                testdate = year
                if ( date_match_idx == 0 )
                    testdate += (month) ? " #{month}" : " Jan"
                    testdate += (day)   ? " #{day}"   : " 01"
                else
                    testdate += (month) ? " #{month}" : " Dec"
                    testdate += (day)   ? " #{day}"   : " 01"       # This will be set to the end-of-month below
                end

                if ( month and month.integer? ) then
                    strptime_fmt = '%Y %m %d'
                else
                    strptime_fmt = '%Y %b %d'
                end
                date_match_S.strptime_O = do_strptime( testdate, strptime_fmt )
                if ( date_match_S.strptime_O.nil? ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' -> "+
                                            "'#{testdate}' -> '#{strptime_fmt}' strptime conversion failed"
                    SE.puts "#{SE.lineno}: #{original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( date_match_S.strptime_O.year < 0 ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' -> '#{date_match_S.strptime_O}' negative year"
                    SE.puts "#{SE.lineno}: #{original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( day.nil? and date_match_S.strptime_O.day != 1 ) then
                    SE.puts "#{SE.lineno}: I shouldn't be here: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                         "'#{date_match_S.all_pieces}' -> "+
                                         "'#{date_match_S.piece( 1 )}' -> '#{date_match_S.strptime_O} day != 1"
                    SE.puts "#{SE.lineno}: #{original_text}"
                    raise
                end
                
                if ( option_H[ :default_century_pivot_ccyymmdd ] ) then               
                    if ( date_match_S.strptime_O < option_H[ :default_century_pivot_ccyymmdd ] ) then
                        date_match_S.strptime_O = date_match_S.strptime_O.next_year( 100 )
                    end
                end
               
                if ( day.nil? and date_match_idx > 0 ) then
                    date_match_S.strptime_O = date_match_S.strptime_O.last_day_of_month
                end
                               
                date_match_S.as_date  = date_match_S.strptime_O.strftime( '%Y' )
                date_match_S.as_date += date_match_S.strptime_O.strftime( '-%m' ) if ( month )
                date_match_S.as_date += date_match_S.strptime_O.strftime( '-%d' ) if ( day )
            end
            next if ( date_clump_S.morality == :bad )
            
            if ( date_clump_S.date_match_S__A.length > 2 ) then                 
                stringer = "#{SE.lineno}: #{date_clump_S.date_match_S__A.length} run-on thru dates: "
                date_clump_S.date_match_S__A.each do | date_match_S |
                    stringer += "'#{date_match_S.all_pieces}' "
                end
                SE.puts "#{SE.lineno}: #{original_text}"
                date_clump_S.judge_date( :bad, stringer )
                next
            end      
            if ( date_clump_S.date_match_S__A.length == 1 and date_clump_S.from.ymd_S.year.length == 2 and date_clump_S.from.ymd_S.month.nil? and date_clump_S.from.ymd_S.day.nil? ) then
                stringer = "#{SE.lineno}: probable bad date: #{date_clump_S.from.pattern_name}: "+
                                        "'#{date_clump_S.from.all_pieces}' -> "+
                                        "'#{date_clump_S.from.piece( 1 )}' isolated 2 digit number."
                SE.puts "#{SE.lineno}: #{original_text}"
                date_clump_S.judge_date( :bad, stringer )
                next
            end
            
            if ( date_clump_S.date_match_S__A.length == 2 and date_clump_S.from.strptime_O and date_clump_S.thru.strptime_O ) then
                if (date_clump_S.from.strptime_O > date_clump_S.thru.strptime_O ) then
                    stringer = "#{SE.lineno}: From date '#{date_clump_S.as_from_date}' > Thru date '#{date_clump_S.as_thru_date}'"
                    SE.puts "#{SE.lineno}: #{original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
            end

            if ( option_H[ :debug_options ].include?( :print_good_dates ) ) then
                stringer = "#{SE.lineno}: good date: #{date_match_S.pattern_name}: '#{date_match_S.all_pieces}'"
                SE.puts stringer
            end
            date_clump_S.morality = :good
            date_clump_S.error_msg = ''

        end
    end
end