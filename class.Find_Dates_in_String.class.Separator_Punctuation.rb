#   Part of class.Find_Dates_in_String

class Separator_Punctuation
    public  attr_reader :all_punct_chars, :usable_text_punct_chars
    private attr_writer :all_punct_chars, :usable_text_punct_chars
    def initialize
        self.all_punct_chars = '~!@#$%^&*()_+`-={}[]:";\'<>?,.\\|'    
        self.usable_text_punct_chars = all_punct_chars + ''
    end
    def reserve_punctuation_chars( separator_RE )
        if ( separator_RE.is_not_a?( Regexp ) ) then
            SE.puts "#{SE.lineno}: I was expecting param1 to be a 'Regexp', instead it's a '#{separator_RE.class}'"
            raise
        end
        if ( not all_punct_chars.match?( separator_RE ) ) then
            SE.puts "#{SE.lineno}: No punctuation characters found for param '#{separator_RE.to_s}'"
            raise
        end
        all_punct_chars_temp = all_punct_chars + ''
        arr = [ ]
        loop do
            match_O = usable_text_punct_chars.match( separator_RE )
            if ( match_O ) then
                arr << match_O[ 0 ]
                usable_text_punct_chars[ match_O[ 0 ] ] = ''
                all_punct_chars_temp[ match_O[ 0 ] ] = ''
            else
                match_O = all_punct_chars_temp.match( separator_RE )
                if ( match_O ) then
                    SE.puts "#{SE.lineno}: Punctuation character: #{$&} in param1 '#{separator_RE.to_s}' is already used."
                    raise
                end
                break
            end
        end
        if ( arr.length == 0 ) then
            SE.puts "#{SE.lineno}: I shouldn't be here:" 
            SE.q {[ 'arr' ]}
            raise
        end
        return arr.join( '' )
    end
end