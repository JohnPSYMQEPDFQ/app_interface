require 'Date'                       # This messes-up CSV.
require 'class.Date.extend.rb'
require 'class.Hash.extend.rb'
require 'class.Array.extend.rb'
require 'class.Object.extend.rb'
require 'class.String.extend.rb'
require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'

require 'class.Find_Dates_in_String.class.Separator_Punctuation.rb'
require 'class.Find_Dates_in_String.class.Date_clump_uid.rb'
require 'class.Find_Dates_in_String.module.Set_Options.rb'
require 'class.Find_Dates_in_String.module.Date_Regexp_variables.rb'
require 'class.Find_Dates_in_String.module.Output_Date_Text_Validation.rb'
require 'class.Find_Dates_in_String.module.Date_Clumps_parse_text_dates.rb'
require 'class.Find_Dates_in_String.module.Date_Clumps_judge_each_clump.rb'
require 'class.Find_Dates_in_String.module.Date_Clumps_convert_back_to_text_dates.rb'
require 'class.Find_Dates_in_String.module.Date_Clumps_classify_by_good_and_bad_morality.rb'


 
class Find_Dates_in_String    
    public  attr_reader :original_text,
                        :separation_punctuation_O, :date_clump_uid_O,
                        :output_data_O, :output_data_with_all_dates_removed_O,
                        :output_data_uid_H
    private attr_writer :original_text,
                        :separation_punctuation_O, :date_clump_uid_O,
                        :output_data_O, :output_data_with_all_dates_removed_O,
                        :output_data_uid_H

    include Set_Options
    include Date_Regexp_variables     
    include Output_Date_Text_Validation    
    include Date_Clumps_parse_text_dates 
    include Date_Clumps_judge_each_clump
    include Date_Clumps_convert_back_to_text_dates
    include Date_Clumps_classify_by_good_and_bad_morality
            
    
    def initialize( param__option_H = {} )    
        binding.pry if ( respond_to? :pry )       
        
        self.separation_punctuation_O = Separator_Punctuation.new               
        self.date_clump_uid_O = Date_clump_uid.new( separation_punctuation_O )
        
        set_options( param__option_H )
        
        self.output_data_uid_H = {}        
#
#       A module having a method named 'initialize' will be called IF the class 'initialize' method calls 'super'.  BUT,
#       if there are more than one modules, only the last one included will be have its 'initialize' method called!   
#       To get around that, do the following code in a class's 'initialize' to run any included module's method having
#       a method named '[MODULE_NAME]__initialize'.   
#                   
        self.singleton_class.included_modules.map { | mn | "#{mn}__initialize".downcase.to_sym }.filter_map { | mcim | self.send( mcim ) if self.respond_to?( mcim ) }
       
    end    

    def do_strptime( testdate, strptime_fmt )   
        begin
            strptime_O = Date::strptime( testdate, strptime_fmt )
        rescue
            strptime_O = nil
        end
        return strptime_O
    end           
    
    def do_find( param__original_text )
        self.original_text = param__original_text 

        self.output_data_O = String_with_before_after_STORE_and_ASSIGN_methods.new( after_change_method: method( :after_change_validate )  )
        self.output_data_with_all_dates_removed_O = String_with_before_after_STORE_and_ASSIGN_methods.new( )
#       output_data_with_all_dates_removed_O.before_change_method = method( :before_change_validate )    # Can't be active at the same
#       output_data_with_all_dates_removed_O.after_change_method  = method( :after_change_validate )     # time as above due to the
                                                                                                         # the Hash in the validation 
                                                                                                         # function.                  
        output_data_O.string = original_text + ''   # Make a new string, not a pointer.           
        
        date_clumps_parse_text_dates( )
        date_clumps_judge_each_clump( )
      
        output_data_O.before_change_method = method( :before_change_validate ) 
        output_data_with_all_dates_removed_O.string = output_data_O.string + ''
       
        date_clumps_convert_back_to_text_dates( )
        date_clumps_classify_by_good_and_bad_morality( )

        case option_H[ :date_string_composition ]
        when :dates_in_text
            if (output_data_with_all_dates_removed_O.string =~ %r~#{K.alpha_month_RES}( |/|-)~i ) then
                SE.puts "#{SE.lineno}: Warning possible unmatched date '#{$~}' in '#{output_data_with_all_dates_removed_O.string}'"
                SE.puts ''
            end
        when :only_dates
            if (output_data_with_all_dates_removed_O.string.not_blank? ) then
                SE.puts "#{SE.lineno}: Unconverted dates in: '#{original_text}'"
                SE.puts "#{SE.lineno}: Extra text:           '#{output_data_with_all_dates_removed_O.string}'"  if ( original_text != output_data_with_all_dates_removed_O.string )
                if ( good__date_clump_S__A.length > 0 ) then
                    stringer = good__date_clump_S__A.map do | date_clump_S |
                        date_clump_S.date_match_S__A.map do | date_match_S |
                            date_match_S.as_date
                        end
                    end.join( "','")
                    SE.puts "#{SE.lineno}: Good dates: '#{stringer}' moved to bad-dates array after row #{bad__date_clump_S__A.length}"
                    bad__date_clump_S__A += good__date_clump_S__A
                    self.good__date_clump_S__A = [ ]
                end
                SE.puts ''
                return original_text
            end
        end
        return output_data_O.string.rstrip
    end
end



