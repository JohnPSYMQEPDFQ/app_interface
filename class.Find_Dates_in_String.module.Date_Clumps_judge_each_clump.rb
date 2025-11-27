# frozen_string_literal: true

#   Part of class.Find_Dates_in_String.rb

module Date_Clumps_judge_each_clump
    
    def date_clumps_judge_each_clump( )
        date_clump_S__A.each do | date_clump_S |
           #SE.q {'date_clump_S'}
            date_clump_S.date_match_S__A.each_with_index do | date_match_S, date_match_idx |
                year   = date_match_S.ymd_S.year.dup 
                month  = date_match_S.ymd_S.month.dup
                day    = date_match_S.ymd_S.day.dup
                
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
                    date_match_S.ymd_S.year = year.dup
                    date_match_S.ymd_S.day  = day.dup
                end
                
                if ( year.length < 2 or year.length == 3 or year.length > 4 ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' bad year length."
                    SE.puts "#{SE.lineno}: #{self.original_text}"                        
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( month and month.integer? and month.length > 2 ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' bad numeric month length"
                    date_clump_S.judge_date( :bad, stringer )
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    next
                end

                if ( day and day.not_integer? ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' day not numeric: '#{day}'"
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( year.not_integer? ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' year not numeric: '#{year}'"
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( year.length == 2 ) then
                    if ( date_match_idx == 0 ) then
                        year = self.option_H[ :default_century_pivot_ccyymmdd ].year.to_s[ 0, 2 ] + year  # self.option_H[ :default_century_pivot_ccyymmdd ] is a strptime_O
                    else
                        if ( date_clump_S.date_match_S__from.strptime_O ) then
                            year = date_clump_S.as_from_date[ 0, 2 ] + year                   # Take the century from the converted from_year, which is already in YYYY format
                        else
                            year = self.option_H[ :default_century_pivot_ccyymmdd ].year.to_s[ 0, 2 ] + year          
                        end
                    end
                end
#               BELOW HERE THE 'year' WILL ALWAYS BE 4 digits

                if ( month and month.not_integer? ) then
                    # month_match_O = month.match( /^(?<month_M>#{K.alpha_month_RES})/ )  # Only need for 'soft months' , which isn't programmed
                    # if ( not month_match_O.nil? ) then
                        # month_named_captures = month_match_O.named_captures
                        # month = month_named_captures[ 'month_M' ]
                    # end
                    month.sub!( /\.$/, '' )                         # Take the period off the months (eg Feb.)
                end

                testdate = +''
                testdate << year
                if ( date_match_idx == 0 )
                    testdate << ( (month) ? " #{month}" : " Jan" )
                    testdate << ( (day)   ? " #{day}"   : " 01" )
                else
                    testdate << ( (month) ? " #{month}" : " Dec" )
                    testdate << ( (day)   ? " #{day}"   : " 01" )     # This will be set to the end-of-month below
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
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( date_match_S.strptime_O.year < 0 ) then
                    stringer = "#{SE.lineno}: bad date: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                            "'#{date_match_S.all_pieces}' -> "+
                                            "'#{date_match_S.piece( 1 )}' -> '#{date_match_S.strptime_O}' negative year"
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( day.nil? and date_match_S.strptime_O.day != 1 ) then
                    SE.puts "#{SE.lineno}: I shouldn't be here: #{date_match_S.pattern_name}, idx=#{date_match_idx}: "+
                                         "'#{date_match_S.all_pieces}' -> "+
                                         "'#{date_match_S.piece( 1 )}' -> '#{date_match_S.strptime_O} day != 1"
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    raise
                end
                
                if ( self.option_H[ :default_century_pivot_ccyymmdd ] and date_match_S.ymd_S.year.length == 2 ) then               
                    if ( date_match_S.strptime_O < self.option_H[ :default_century_pivot_ccyymmdd ] ) then
                        date_match_S.strptime_O = date_match_S.strptime_O.next_year( 100 )
                    end
                end          
                if ( day.nil? and date_match_idx > 0 ) then
                    date_match_S.strptime_O = date_match_S.strptime_O.last_day_of_month
                end
                                               
                date_match_S.as_date  = date_match_S.strptime_O.strftime( '%Y' )
                date_match_S.as_date << date_match_S.strptime_O.strftime( '-%m' ) if ( month )
                date_match_S.as_date << date_match_S.strptime_O.strftime( '-%d' ) if ( day )
            end
            next if ( date_clump_S.morality == :bad )
            
            if ( date_clump_S.date_match_S__A.length > 2 ) then                 
                stringer = "#{SE.lineno}: #{date_clump_S.date_match_S__A.length} run-on thru dates: "
                date_clump_S.date_match_S__A.each do | date_match_S |
                    stringer << "'#{date_match_S.all_pieces}' "
                end
                SE.puts "#{SE.lineno}: #{self.original_text}"
                date_clump_S.judge_date( :bad, stringer )
                next
            end      
            if ( date_clump_S.date_match_S__A.length == 1 and 
                 date_clump_S.date_match_S__from.ymd_S.year.length == 2 and 
                 date_clump_S.date_match_S__from.ymd_S.month.nil? and 
                 date_clump_S.date_match_S__from.ymd_S.day.nil? 
                ) then
                stringer = "#{SE.lineno}: probable bad date: #{date_clump_S.date_match_S__from.pattern_name}: "+
                                        "'#{date_clump_S.date_match_S__from.all_pieces}' -> "+
                                        "'#{date_clump_S.date_match_S__from.piece( 1 )}' isolated 2 digit number."
                SE.puts "#{SE.lineno}: #{self.original_text}"
                date_clump_S.judge_date( :bad, stringer )
                next
            end
            case date_clump_S.date_match_S__A.length
            when 1
                if ( date_clump_S.date_match_S__from.strptime_O.nil? ) then
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    SE.puts "#{SE.lineno}: Unexpected 'date_clump_S.date_match_S__from.strptime_O' == nil !"
                    SE.q {'date_clump_S'}
                    raise
                end
                if ( date_clump_S.date_match_S__from.strptime_O < self.option_H[ :yyyymmdd_min_value] ) then
                    stringer = "#{SE.lineno}: Date dropped: " 
                                            "'#{date_clump_S.as_from_date}' -> "+
                                            "date LT min value '#{self.option_H[ :yyyymmdd_min_value]}'"
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( date_clump_S.date_match_S__from.strptime_O > self.option_H[ :yyyymmdd_max_value] ) then
                    stringer = "#{SE.lineno}: Date dropped: "+
                                            "'#{date_clump_S.as_from_date}' -> "+
                                            "date GT max value '#{self.option_H[ :yyyymmdd_max_value]}'"
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
            when 2   
                if ( date_clump_S.date_match_S__from.strptime_O.nil? ) then
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    SE.puts "#{SE.lineno}: Unexpected 'date_clump_S.date_match_S__from.strptime_O' == nil !"
                    SE.q {'date_clump_S'}
                    raise
                end
                if ( date_clump_S.date_match_S__thru.strptime_O.nil? ) then
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    SE.puts "#{SE.lineno}: Unexpected 'date_clump_S.date_match_S__thru.strptime_O' == nil !"
                    SE.q {'date_clump_S'}
                    raise
                end                 
                if ( date_clump_S.date_match_S__from.strptime_O > date_clump_S.date_match_S__thru.strptime_O ) then
                    stringer = "#{SE.lineno}: From date '#{date_clump_S.as_from_date}' > Thru date '#{date_clump_S.as_thru_date}'"
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( date_clump_S.date_match_S__from.strptime_O < self.option_H[ :yyyymmdd_min_value] ) then
                    stringer = "#{SE.lineno}: Date dropped: " +
                                            "'#{date_clump_S.as_from_date}' -> "+
                                            "from date LT min value '#{self.option_H[ :yyyymmdd_min_value]}'"
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end
                if ( date_clump_S.date_match_S__thru.strptime_O > self.option_H[ :yyyymmdd_max_value] ) then
                    stringer = "#{SE.lineno}: Date dropped: " +
                                            "'#{date_clump_S.as_thru_date}' -> "+
                                            "thru date GT max value '#{self.option_H[ :yyyymmdd_max_value]}'"
                    SE.puts "#{SE.lineno}: #{self.original_text}"
                    date_clump_S.judge_date( :bad, stringer )
                    next
                end

                if ( self.option_H[ :debug_options ].include?( :print_good_dates ) ) then
                    arr = date_clump_S.date_match_S__A.each.map{ | struct | "'#{struct.pattern_name}'='#{struct.as_date}'" }
                    SE.puts "good date: '#{date_clump_S.date_match_string}' (#{arr.join( '; ' )}}"
                end
            else
                SE.puts "#{SE.lineno}: I shouldn't be here, date_clump_S.date_match_S__A.length != 2"
                raise
            end

            date_clump_S.morality = :good
            date_clump_S.error_msg = ''
           #SE.q {'date_clump_S'}
        end
    end
end