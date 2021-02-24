require 'pp'
require 'date'
require 'class.date.extend.rb'
require 'class.array.extend.rb'
require 'module.Se.rb'
require 'module.ArchivesSpace.Konstants.rb'

class String

    def scan_for_dates( param_H )
        if ( not param_H.is_a?( Hash ) ) then
            Se.puts "#{Se.lineno}: Expected param to be a type HASH."
            Se.pp param_H
            raise
        end
        if ( param_H.key?( :date_format ) ) then
            if ( param_H[ :date_format ] == "mmm_dd_yyyy" ) then
                return scan_for_dates_mmm_dd_yyyy( param_H )
            else
                Se.puts "#{Se.lineno}: Unknown date format '#{param_H[ :date_format ]}' to scan for."
                raise
            end
        end
        Se.puts "#{Se.lineno}: No :date_format in param Hash."
        raise
    end

    def scan_for_dates_mmm_dd_yyyy( param_H )
        if ( not param_H.is_a?( Hash ) ) then
            Se.puts "#{Se.lineno}: Expected param to be a type HASH."
            Se.pp param_H
            raise
        end

        local_param_H = {}.merge( param_H) 
        if ( local_param_H.key?( :thru_date_separator ) ) then
            thru_date_separator = local_param_H[ :thru_date_separator ]
        else
            thru_date_separator = '-' 
        end
        if ( local_param_H.key?( :default_century ) ) then
            default_century = local_param_H[ :default_century ]
            if ( not (default_century.integer? and (default_century.length = 2 or (default.century.length = 4 and default_century[ 2..3 ] != "00" )))) then
                 Se.puts "#{Se.lineno}: Expected the :default_century to be NN00 (or NN), not '#{default_century}'"
                 raise
            end
            local_param_H[ :default_century ] = local_param_H[ :default_century ][0..1]
        else
            local_param_H[ :default_century ] = "19"
        end
        
        scan_idx_0R_H = {}
        leading_delimiter_RE = %r{\s*(?:,)?\s*}x
        thru_date_separator_RE = %r{\s*#{thru_date_separator}\s*}x

#       date_normal_RE = %r{(((#{K.month_RE})\s+( (#{K.day_RE})                                      ,\s+)?)?(#{K.year4_RE}|#{K.year2_RE}))}x
        date_normal_RE = %r{((#{K.month_RE})\s+( (#{K.day_RE})                                      ,\s*)?)?(#{K.year4_RE}|#{K.year2_RE})}x
#       date_2_days_RE = %r{((#{K.month_RE})\s+( (#{K.day_RE}#{thru_date_separator_RE}#{K.day_RE})  ,\s*)?)?(#{K.year4_RE}|#{K.year2_RE})}x
#                           12                 3 4                                                          5                                                        
    
        scan_idx_0R_H[ :date_string ] = 0
        scan_idx_0R_H[ :month ] = -4                    # 3 2
        scan_idx_0R_H[ :day ] = -2                      # 5 4 
        scan_idx_0R_H[ :year ] = -1                     # 6 5


        scan_RE = %r{
                    (#{leading_delimiter_RE})(    
                                                  
                                                 ((#{date_normal_RE})(#{thru_date_separator_RE}#{date_normal_RE})+)
                                                |(#{date_normal_RE})
                                             )
                    }x

        scan_idx_0R_H[ :leading_delimiter ] = 0
        scan_idx_0R_H[ :whole_replace_string ] = 1
        scan_idx_0R_H[ :date_RE_groups ] = 5 + 1       # 6  The scan groupings count too!
        scan_idx_0R_H[ :from_date ] = 3                # 2
        scan_idx_0R_H[ :thru_date ] = nil              # 9
        scan_idx_0R_H[ :single_date ] = nil            # 16

        scan_idx_0R_H[ :total_RE_groups ] = ( scan_idx_0R_H[ :date_RE_groups ] * 3 ) + 3
        scan_idx_0R_H[ :thru_date ]   = scan_idx_0R_H[ :from_date ] + scan_idx_0R_H[ :date_RE_groups ]   
        scan_idx_0R_H[ :single_date ] = scan_idx_0R_H[ :thru_date ] + scan_idx_0R_H[ :date_RE_groups ]  

#       pp scan_idx_0R_H
        return scan_for_dates_proc( local_param_H, scan_RE, scan_idx_0R_H )
    end
    private :scan_for_dates_mmm_dd_yyyy

    def scan_for_dates_proc( param_H, scan_RE, scan_idx_0R_H )

        default_century = param_H[ :default_century ]
        
        scan_O = self.scan( scan_RE )  # date pattern match
        # pp scan_O

        output_date_A = []
        scan_O.each_with_index do |row, r_idx| 
            if ( row.length != scan_idx_0R_H[ :total_RE_groups ] ) then
                Se.puts "#{Se.lineno}: I shouldn't be here: row.length != scan_idx_0R_H[ :total_RE_groups ]"
                Se.puts "#{Se.lineno}: #{row.length} != #{scan_idx_0R_H[ :total_RE_groups ]}"
                p "| " + row.join(" | ") + " |"
                raise
            end
#           p "| " + row.join(" | ") + " |"
            leading_delimiter = row[ scan_idx_0R_H[ :leading_delimiter ]]
            whole_replace_string = row[ scan_idx_0R_H[ :whole_replace_string ]]
            from_thru_date_A_A = []
            if ( row[ scan_idx_0R_H[ :single_date ]] ) then
                from_thru_date_A_A << row[ scan_idx_0R_H[ :single_date ] .. scan_idx_0R_H[ :single_date ] + scan_idx_0R_H [:date_RE_groups] - 1 ]
            else
                from_thru_date_A_A << row[ scan_idx_0R_H[ :from_date ] .. scan_idx_0R_H[ :from_date ] + scan_idx_0R_H [:date_RE_groups] - 1 ]
                from_thru_date_A_A << row[ scan_idx_0R_H[ :thru_date ] .. scan_idx_0R_H[ :thru_date ] + scan_idx_0R_H [:date_RE_groups] - 1 ]
            end
            converted_date_A = []
            verify_replace_string = ""
            from_thru_date_A_A.each_with_index do |from_thru_date_A, ft_idx |
                if ( from_thru_date_A.length != scan_idx_0R_H[ :date_RE_groups ] ) then
                    Se.puts "#{Se.lineno}: I shouldn't be here: from_thru_date_A.length != scan_idx_0R_H[ :date_RE_groups ]"
                    Se.puts "#{Se.lineno}: #{from_thru_date_A.length} != #{scan_idx_0R_H[ :date_RE_groups ]}"
                    pp from_thru_date_A
                    raise
                end
#               pp from_thru_date_A
                verify_replace_string += from_thru_date_A[ scan_idx_0R_H[ :date_string ]]
                date_string = from_thru_date_A[ scan_idx_0R_H[ :date_string ]]
                month = from_thru_date_A[ scan_idx_0R_H[ :month ]]
                day = from_thru_date_A[ scan_idx_0R_H[ :day ]]
                year = from_thru_date_A[ scan_idx_0R_H[ :year ]]
#               p month, day, year, scan_idx_0R_H[ :year ]
                if ( not year or ( not month and day )) then
                    Se.puts "#{Se.lineno}: I shouldn't be here: #{r_idx},#{ft_idx}: '#{whole_replace_string}' > '#{date_string}' not year or ( not month and day)!"
                    pp from_thru_date_A
                    raise
                end    
                if ( year.length == 2 and month == nil and day == nil ) then
                    Se.puts "#{Se.lineno}: bad date: #{r_idx},#{ft_idx}: #{whole_replace_string} -> #{date_string} isolated 2 digit number" 
                    converted_date_A.pop(converted_date_A.length)
                    break
                end
                if ( year.length == 2 ) then
                    year = default_century + year           # These are strings
                end

                testdate = year
                case ft_idx
                when 0 
                    testdate += (month) ? " #{month}" : " Jan"
                    testdate += (day)   ? " #{day}"   : " 01"
                when 1
                    testdate += (month) ? " #{month}" : " Dec"
                    testdate += (day)   ? " #{day}"   : " 01"       # This will be set to the end-of-month below
                else
                    Se.puts "#{Se.lineno}: I shouldn't be here: #{r_idx},#{ft_idx}: '#{whole_replace_string}' > '#{date_string}' ft_idx not 0 or 1"
                    raise
                end 
                testdate.sub!( /\./, "" )           # Take the period off the months (eg Feb.)
                begin
                    strptime_O = Date::strptime( testdate, "%Y %b %d" )
                rescue
                    Se.puts "#{Se.lineno}: bad date: #{r_idx},#{ft_idx}: '#{whole_replace_string}' -> '#{date_string}' -> '#{testdate}' strptime conversion failed"
                    converted_date_A.pop(converted_date_A.length)
                    break
                end
                if ( strptime_O.year < 0 ) then
                    Se.puts "#{Se.lineno}: bad date: #{r_idx},#{ft_idx}: '#{whole_replace_string}' -> '#{date_string}' -> '#{strptime_O}' negative year"
                    converted_date_A.pop(converted_date_A.length)
                    break
                end
                if ( day == nil and strptime_O.day != 1 ) then
                    Se.puts "#{Se.lineno}: I shouldn't be here: #{r_idx},#{ft_idx}: '#{whole_replace_string}' -> '#{date_string}' -> '#{strptime_O} day != 1"
                    raise
                end
                if ( day == nil and ft_idx == 1 ) then
                    strptime_O = strptime_O.last_day_of_month
                end
#               Se.puts "#{Se.lineno}: good date: #{r_idx},#{ft_idx}: '#{whole_replace_string}' -> '#{strptime_O}'"
                as_date_yyyy_mm_dd = strptime_O.strftime( '%Y' )
                as_date_yyyy_mm_dd += strptime_O.strftime( '-%m' ) if ( month )
                as_date_yyyy_mm_dd += strptime_O.strftime( '-%d' ) if ( day )
                converted_date_A << [ as_date_yyyy_mm_dd, date_string, strptime_O ]
            end
            if ( whole_replace_string != verify_replace_string ) then
                Se.puts "#{Se.lineno}: bad date: #{r_idx}: whole_replace_string != verify_replace_string"
                Se.puts "'#{whole_replace_string}' != '#{verify_replace_string}'"
                next                
            end
            case converted_date_A.length 
            when 0
        #       Se.puts "#{Se.lineno}: bad date: #{r_idx}: '#{whole_replace_string}' Not converted"
            when 1
                output_date_A << [ leading_delimiter + whole_replace_string, converted_date_A ]
            when 2
                if ( converted_date_A[ 0 ][ 2 ] > converted_date_A[ 1 ][ 2 ] ) then
                    Se.puts "#{Se.lineno}: bad date: #{r_idx}: '#{whole_replace_string}' From date > thru date"
                else
                    output_date_A << [ leading_delimiter + whole_replace_string, converted_date_A ]
                end
            else
                Se.puts "#{Se.lineno}: I shouldn't be here: #{r_idx}: '#{whole_replace_string}' converted_date_A.length = #{converted_date_A.length}"
                raise
            end
        end 
        return output_date_A 
    end
    private :scan_for_dates_proc
end
