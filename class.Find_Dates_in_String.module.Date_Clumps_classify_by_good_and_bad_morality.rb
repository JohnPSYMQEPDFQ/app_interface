#   Part of class.Find_Dates_in_String.rb

module Date_Clumps_classify_by_good_and_bad_morality

    public  attr_reader :good__date_clump_S__A, :bad__date_clump_S__A
    private attr_writer :good__date_clump_S__A, :bad__date_clump_S__A

    #   NOTE:   "def self.initialize" will initialize module variables, NOT the instance variables of the class
    #           the module is included in !!!!!!  See the comment in 'Find_Dates_in_String::initialize' for how
    #           to call a module's "def initialize".  BUT, the "def initialize" is called ONLY at
    #           instance initialize!!!  If the module is supposed to initialize some variables FOR the module
    #           each time a method is called in the class, I decided to name a module method the same name
    #           as the instance method and call it like is being done for "def initialize".
    #           See the :do_find method in "class.Find_Dates_in_String.rb".
    def do_find

        self.good__date_clump_S__A = [ ]
        self.bad__date_clump_S__A = [ ]
    end
    
    def date_clumps_classify_by_good_and_bad_morality( )
        date_clump_S__A.each do | date_clump_S |
            case date_clump_S.morality
            when :good
                good__date_clump_S__A.push << date_clump_S 
            when :bad
                bad__date_clump_S__A.push << date_clump_S 
            else
                SE.puts "#{SE.lineno}: I shouldn't be here: amoral date: '#{date_clump_S.morality}', #{date_clump_S}"
                raise
            end
        end
        if ( option_H[ :sort ] ) then
#               Doesn't work:  good__date_clump_S__A = good__date_clump_S__A.sort_by! { | date_clump_S | [ date_clump_S.from_date ] }  
#               Does work:     good__date_clump_S__A = self.good__date_clump_S__A.sort_by! { | date_clump_S | [ date_clump_S.from_date ] }
#                       -or 
#                              good__date_clump_S__A.sort_by! { | date_clump_S | [ date_clump_S.from_date ] }
#               No idea why...
            good__date_clump_S__A.sort_by! { | date_clump_S | [ date_clump_S.from_date ] }
            prev_date = ''
            good__date_clump_S__A.each_with_index do | date_clump_S, idx |
                if ( date_clump_S.from_date < prev_date ) then
                    SE.puts "#{SE.lineno}: Warning: Dates overlap! good from-date '#{date_clump_S.from_date} at element #{idx} "+
                            "< previous date #{prev_date}, there may be others."
                    SE.puts original_text
                    SE.puts ''
                    break
                end
                prev_date = ( date_clump_S.thru_date.blank? ) ? date_clump_S.from_date : date_clump_S.thru_date
            end
        end
    end
end
