#   Part of class.Find_Dates_in_String

class Date_clump_uid
    public  attr_reader :pattern_RES, :pattern_RE, :pattern_length,
                        :prefix, :suffix, :digit_length, :uid_length, :date_clump_punct_chars
    private attr_writer :pattern_RES, :pattern_RE, :pattern_length,
                        :prefix, :suffix, :digit_length, :uid_length, :date_clump_punct_chars

    
    def initialize( separation_punctuation_O )
        self.date_clump_punct_chars = separation_punctuation_O.reserve_punctuation_chars( /[<>]/ )
        self.prefix                 = " #{date_clump_punct_chars[ 0 ]}DATE_CLUMP_#:"        # The leading and
        self.suffix                 = "#{date_clump_punct_chars[ 1 ]} "                     # trailing space is important!  
        self.digit_length           = '10'
        self.pattern_RES            = prefix + "[0-9]{#{digit_length}}" + suffix
        self.pattern_RE             = /#{pattern_RES}/
        self.uid_length             = uid_of_num( 0 ).length
    end
    
    def uid_of_num( num )
        return prefix + "%0#{digit_length}d" % num + suffix       
    end
    
    def num_from_uid( uid )
        if ( uid.length == uid_length and 
             uid[  0, prefix.length ] == prefix and 
             uid[ -2, suffix.length ] == suffix ) then
            return uid[ prefix.length, 10 ].to_i
        else
            SE.puts "#{SE.lineno}: NOT ( uid.length == #{uid_length} and" 
            SE.puts "#{SE.lineno}:       uid[  0, #{prefix.length} ] == #{prefix} and"
            SE.puts "#{SE.lineno}:       uid[ -2, #{suffix.length} ] == #{suffix} )"
            SE.q {[ 'uid' ]}
            raise
        end
    end
end
 