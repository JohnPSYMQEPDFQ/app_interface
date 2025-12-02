=begin

Variable Abbreviations:
        AO = Archival Object ( Resources are an AO too, but they have their own structure. )
        AS = ArchivesSpace
        IT = Instance Type
        TC = Top Container
        SC = Sub-Container
        _H = Hash
        _J = Json string
        _RES = Regular Expression String, e.g: find_bozo_RES = '\s+bozo\s+'
        _RE  = Regular Expression, e.g.: find_bozo_RE = /#{find_bozo_RES}/
        _A = Array
        _O = Object
        _Q = Query
        _C = Class of Struct
        _S = Structure of _C 
        __ = reads as: 'in a(n)', e.g.: record_H__A = 'record' Hash "in an" Array.

=end

require 'date'                       
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
    public  attr_reader :aspace_O, :original_text,
                        :separation_punctuation_O, :date_clump_uid_O,
                        :output_data_O, :output_data_with_all_dates_removed_O
    private attr_writer :aspace_O, :original_text,
                        :separation_punctuation_O, :date_clump_uid_O,
                        :output_data_O, :output_data_with_all_dates_removed_O

    include Set_Options
    include Date_Regexp_variables     
    include Output_Date_Text_Validation    
    include Date_Clumps_parse_text_dates 
    include Date_Clumps_judge_each_clump
    include Date_Clumps_convert_back_to_text_dates
    include Date_Clumps_classify_by_good_and_bad_morality
            
    
    def initialize( p1_param__option_H = {}, p2_param_aspace_O = nil )    
        binding.pry if ( respond_to? :pry )       
        
        if ( p2_param_aspace_O.not_nil? ) then   # The ASpace Object is only needed for date_format method, so
                                                 # if that's not need nil is find.
            if ( p2_param_aspace_O.is_not_a?( ASpace ) ) then
                SE.puts "#{SE.lineno}: Param 2 should be 'nil' or an 'ASpace' object, not a '#{p2_param_aspace_O.class}'"
                raise
            end
        end
        self.aspace_O = p2_param_aspace_O
        self.separation_punctuation_O = Separator_Punctuation.new               
        self.date_clump_uid_O = Date_clump_uid.new( self.separation_punctuation_O )
        
        set_options( p1_param__option_H )
        
#
#       A module having a method named 'initialize' will be called IF the class 'initialize' method calls 'super'.  BUT,
#       if there is more than one module, only the last one included will have its 'initialize' method called !   
#       To get around that, do the following code in a class's 'initialize' to run any included module's method having
#       a method named '[MODULE_NAME]__initialize'.   
#                   
#       self.singleton_class.included_modules.map { | mn | "#{mn}__initialize".downcase.to_sym }.filter_map { | mcim | self.send( mcim ) if self.respond_to?( mcim ) }

#       BUT!!!  It turns out, there IS a way to call each module's 'initialize' method using the following code,
#       which I got from here: https://web.archive.org/web/20160325173756/http://stdout.koraktor.de/blog/2010/10/13/ruby-calling-super-constructors-from-multiple-included-modules/
#       However, to make it more "automatic", I added a loop for each method, testing for the existence of
#       __method__ (which is the currently executing method, which is :initialize).   

        self.singleton_class.included_modules.each do | mod |
#           next if ( not mod.respond_to?( __method__, true ) )   <<<<<  This didn't work.  It returned true for Kernal 
            next if ( not mod.private_instance_methods.member?( __method__ ) )
            mod.instance_method( __method__ ).bind( self ).call
        end
       
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
    
    #   NOTE:   "def self.initialize" will initialize module variables, NOT the instance variables of the class
    #           the module is included in !!!!!!  See the comment in 'Find_Dates_in_String::initialize' for how
    #           to call a module's "def initialize".  BUT, the "def initialize" is called ONLY at
    #           instance initialize!!!  If the module is supposed to initialize some variables FOR the module
    #           each time a method is called in the class, I decided to name a module method the same name
    #           as the instance method and call it like is being done for "def initialize".
        self.singleton_class.included_modules.each do | mod |
            next if ( not mod.method_defined?( __method__ ) )   
            mod.instance_method( __method__ ).bind( self ).call
        end
        
        self.original_text = param__original_text 

        self.output_data_O = String_with_before_after_STORE_and_ASSIGN_methods.new( after_change_method: method( :after_change_validate )  )         
        self.output_data_O.string = self.original_text.dup   # Make a new string, not a pointer.                
        date_clumps_parse_text_dates( )
        date_clumps_judge_each_clump( )                      
        self.output_data_O.before_change_method = method( :before_change_validate ) 

        self.output_data_with_all_dates_removed_O = String_with_before_after_STORE_and_ASSIGN_methods.new( )   
        self.output_data_with_all_dates_removed_O.before_change_method = method( :before_change_validate ) 
        self.output_data_with_all_dates_removed_O.after_change_method  = method( :after_change_validate )            
        self.output_data_with_all_dates_removed_O.string               = self.output_data_O.string.dup    
        date_clumps_convert_back_to_text_dates( )
        date_clumps_classify_by_good_and_bad_morality( )

        case option_H[ :date_string_composition ]
        when :dates_in_text
            if ( output_data_with_all_dates_removed_O.string.match?( %r~#{K.alpha_month_RES}( |/|-)~i ) ) then
                SE.puts "#{SE.lineno}: Warning possible unmatched date '#{$~}' in '#{self.output_data_with_all_dates_removed_O.string}'"
                SE.puts ''
            end
        when :only_dates
            if ( output_data_with_all_dates_removed_O.string.not_blank? ) then
                SE.puts "#{SE.lineno}: Unconverted dates in: '#{self.original_text}'"
                SE.puts "#{SE.lineno}: Extra text:           '#{self.output_data_with_all_dates_removed_O.string}'"  if ( original_text != self.output_data_with_all_dates_removed_O.string )
                if ( self.good__date_clump_S__A.length > 0 ) then
                    stringer = self.good__date_clump_S__A.map do | date_clump_S |
                        date_clump_S.date_match_S__A.map do | date_match_S |
                            date_match_S.as_date
                        end
                    end.join( "','")
                    SE.puts "#{SE.lineno}: Good dates: '#{stringer}' moved to bad-dates array after row #{self.bad__date_clump_S__A.length}"
                    self.bad__date_clump_S__A += self.good__date_clump_S__A
                    self.good__date_clump_S__A = [ ]
                end
                SE.puts ''
                return self.original_text
            end
        end
       #SE.q {'self.output_data_O.string'}  
        return self.output_data_O.string.rstrip
    end
end



