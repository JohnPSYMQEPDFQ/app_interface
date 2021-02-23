require "pp"
require 'date'
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
        Se.puts "#{Se.lineno}: Unknown date format '#{param_H[ :date_format ]}' to scan for."
        raise
    end

    def scan_for_dates_mmm_dd_yyyy( param_H )
        if ( not param_H.is_a?( Hash ) ) then
            Se.puts "#{Se.lineno}: Expected param to be a type HASH."
            Se.pp param_H
            raise
        end
        if ( param_H.key?( :date_from_thru_separator_RE ) ) then
            date_from_thru_separator_RE = param_H[ :date_from_thru_separator_RE ]
        else
            date_from_thru_separator_RE = %r{\s*-\s*} 
        end
        if ( param_H.key?( :default_century ) ) then
            default_century = param_H[ :default_century ]
            if ( not (default_century.integer? and (default_century.length = 2 or (default.century.length = 4 and default_century[ 2..3 ] != "00" )))) then
                 Se.puts "#{Se.lineno}: Expected the :default_century to be NN00 (or NN), not '#{default_century}'"
                 raise
            end
            default_century = param_H[ :default_century ][0..1]
        else
            default_century = "19"
        end
        
        date_RE = %r{
                    (\s*(?:,)?\s*)(           
                        (                              (((#{K.month_RE})\s+((#{K.day_RE}),\s+)?)?(#{K.year4_RE}|#{K.year2_RE})))
                        (#{date_from_thru_separator_RE}(((#{K.month_RE})\s+((#{K.day_RE}),\s+)?)?(#{K.year4_RE}|#{K.year2_RE})))+
                    |   (                              (((#{K.month_RE})\s+((#{K.day_RE}),\s+)?)?(#{K.year4_RE}|#{K.year2_RE})))
                                  )
                    }x
            
#       pp self
        
        scan_O = self.scan( date_RE )  # date pattern match
        # pp scan_O
        # Scan results from above pattern:
        # double date
        # "   | Apr. 1920 - may 1920 | Apr. 1920 | Apr. 1920 | Apr.  | Apr. |  |  | 1920 |  - may 1920 | may 1920 | may  | may |  |  | 1920 |  |  |  |  |  |  | "        
        # single date:
        # ",  | jun 16, 1920 |  |  |  |  |  |  |  |  |  |  |  |  |  |  | jun 16, 1920 | jun 16, 1920 | jun 16,  | jun | 16,  | 16 | 1920"

        
        scan_idx_0R_H = {
                         :leading_delimiter  => 0,
                         :whole_replace_string => 1,
                         :from_date => 2,
                         :thru_date => 9,
                         :single_date => 16,
                         :date_replace_string => 0,
                         :date_string => 1,
                         :month => 3,
                         :day => 5,
                         :year => 6,
                         :date_elements => 6
                        }
        
        output_date_A = []
        scan_O.each_with_index do |row, r_idx| 
#           p row.join(" | ")
            leading_delimiter = row[ scan_idx_0R_H[ :leading_delimiter ]]
            whole_replace_string = row[ scan_idx_0R_H[ :whole_replace_string ]]
            from_thru_date_A_A = []
            if ( row[ scan_idx_0R_H[ :single_date ]] ) then
                from_thru_date_A_A << row[ scan_idx_0R_H[ :single_date ] .. scan_idx_0R_H[ :single_date ] + scan_idx_0R_H [:date_elements] ]
            else
                from_thru_date_A_A << row[ scan_idx_0R_H[ :from_date ] .. scan_idx_0R_H[ :from_date ] + scan_idx_0R_H [:date_elements] ]
                from_thru_date_A_A << row[ scan_idx_0R_H[ :thru_date ] .. scan_idx_0R_H[ :thru_date ] + scan_idx_0R_H [:date_elements] ]
            end
            converted_date_A = []
            verify_replace_string = ""
            from_thru_date_A_A.each_with_index do |from_thru_date_A, ft_idx |
#               pp from_thru_date_A
                verify_replace_string += from_thru_date_A[ scan_idx_0R_H[ :date_replace_string ]]
                date_string = from_thru_date_A[ scan_idx_0R_H[ :date_string ]]
                month = from_thru_date_A[ scan_idx_0R_H[ :month ]]
                day = from_thru_date_A[ scan_idx_0R_H[ :day ]]
                year = from_thru_date_A[ scan_idx_0R_H[ :year ]]
                if ( year.length == 2 and month == nil and day == nil ) then
                    Se.puts "#{Se.lineno}: bad date: #{r_idx},#{ft_idx}: #{whole_replace_string} -> #{date_string} isolated 2 digit number" 
                    converted_date_A.pop(converted_date_A.length)
                    break
                end
                if ( year.length == 2 ) then
                    year = default_century + year           # These are strings
                end
                if ( ft_idx == 0 and from_thru_date_A_A.length == 1 and ( month == nil or day == nil ) ) then
                    from_thru_date_A_A << from_thru_date_A
                    verify_replace_string[ date_string ] = ""
                end
                if ( month == nil and day == nil ) then
                    case ft_idx
                    when 0 
                        month = "Jan"
                        day = "01"
                        date_string = "#{month} #{day}, #{year}"
                    when 1
                        month = "Dec"
                        day = "31"
                        date_string = "#{month} #{day}, #{year}"
                    else
                        Se.puts "#{Se.lineno}: I shouldn't be here: #{r_idx},#{ft_idx}: #{whole_replace_string} > #{date_string}"
                        raise
                    end    
                end
                month.sub!( /\.$/, "" )       
                if ( day == nil ) then
                    testdate = "#{month} 01 #{year}" 
                else
                    testdate = "#{month} #{day} #{year}" 
                end
                begin
                    strptime_O = Date::strptime( testdate, "%b %d %Y" )
                rescue
                    Se.puts "#{Se.lineno}: bad date: #{r_idx},#{ft_idx}: #{whole_replace_string} -> #{date_string} strptime conversion failed"
                    converted_date_A.pop(converted_date_A.length)
                    break
                end
                if ( strptime_O.year < 0 ) then
                    Se.puts "#{Se.lineno}: bad date: #{r_idx},#{ft_idx}: #{whole_replace_string} -> #{date_string} -> #{strptime_O} negative year"
                    converted_date_A.pop(converted_date_A.length)
                    break
                end
                if ( day == nil and ft_idx == 0 and strptime_O.day != 1 ) then
                    Se.puts "#{Se.lineno}: I shouldn't be here: #{r_idx},#{ft_idx}: #{whole_replace_string} -> #{date_string}"
                    raise
                end
                if ( day == nil and ft_idx == 1 ) then
                    strptime_O = strptime_O.next_month(1)
                    strptime_O = strptime_O.prev_day(1)
#                   Se.puts "#{Se.lineno}: MOD date: #{r_idx},#{ft_idx}: #{whole_replace_string} -> #{strptime_O} -> changed to end of month"
                end
#               Se.puts "#{Se.lineno}: good date: #{r_idx},#{ft_idx}: #{whole_replace_string} -> #{strptime_O}"
                converted_date_A << [ date_string, strptime_O ]
            end
            if ( whole_replace_string != verify_replace_string ) then
                Se.puts "#{Se.lineno}: bad date: #{r_idx}: whole_replace_string != verify_replace_string"
                Se.puts "'#{whole_replace_string}' != '#{verify_replace_string}'"
                next                
            end
            case converted_date_A.length 
            when 0
        #       Se.puts "#{Se.lineno}: bad date: #{r_idx},#{ft_idx}: #{whole_replace_string} Not converted"
            when 1
                output_date_A << [ leading_delimiter + whole_replace_string, converted_date_A ]
            when 2
                if ( converted_date_A[ 0 ][ 1 ] > converted_date_A[ 1 ][ 1 ] ) then
                    Se.puts "#{Se.lineno}: bad date: #{r_idx},#{ft_idx}: #{whole_replace_string} From date > thru date"
                else
                    output_date_A << [ leading_delimiter + whole_replace_string, converted_date_A ]
                end
            else
        #       Se.puts "#{Se.lineno}: bad date: #{r_idx},#{ft_idx}: #{whole_replace_string} converted_date_A.length = #{converted_date_A.length}"
            end
        end 
        return output_date_A 
    end
    private :scan_for_dates_mmm_dd_yyyy
end
