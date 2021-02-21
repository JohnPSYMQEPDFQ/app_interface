require 'module.ArchivesSpace.Konstants.rb'

regexp = %r{
    \s*(?:,)?\s*(          
                  (#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}\s*-\s*(#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}
                 |(#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}
                )
            }x
    
input_record = "leading text, 1950-1959, Apr. 15, 1920, November 21, 1860, Feb. 16, 1910 - Jun 16, 1920, Dec 15, 1931, 1940"
pp input_record

scan_O = input_record.scan( regexp )  # date pattern match
pp scan_O

regexp = %r{
    \s*(?:,)?\s*(          
                  (#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}\s*-\s*(#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}
                 |(#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}
                )
    (?:\s+|$)}x
date_A = []
loop do
    match_O = input_record.match( regexp )  # date pattern match
    if ( match_O ) then
        date_A.unshift( match_O[ 1 ] )
        input_record.sub!( regexp, " " )
    else
        break
    end
end

pp input_record
pp date_A
