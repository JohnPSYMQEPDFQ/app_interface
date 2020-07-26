require 'module.ArchivesSpace.Konstants.rb'

input_record = "leading text, 1950-1959, November 21, 1860, Dec 15, 1931, 1940 trailing text"
pp input_record

date_A = []
loop do
    regexp = %r{
               \s*(?:,)?\s*(
                             (#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}\s*-\s*(#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}
                            |(#{K.month_RE}\s+#{K.day_RE},\s+)?#{K.year4_RE}
                           )
               }x
    match_O = input_record.match( regexp )  # date pattern match
    if ( match_O ) then
        date_A << match_O[ 1 ]
        input_record.sub!( regexp, "" )
    else
        break
    end
end

pp input_record
pp date_A
