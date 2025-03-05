#   Part of class.Find_Dates_in_String.rb

module Date_Regexp_variables

    public  attr_reader :date_pattern_RES_S__A, :pattern_cnt_H,
                        :date_text_separator_RES, :thru_date_separator_RES, :thru_date_begin_delim_RES, :thru_date_end_delim_RES, 
                        :begin_delim_RES, :end_delim_RES

    private attr_writer :date_pattern_RES_S__A, :pattern_cnt_H,
                        :date_text_separator_RES, :thru_date_separator_RES, :thru_date_begin_delim_RES, :thru_date_end_delim_RES, 
                        :begin_delim_RES, :end_delim_RES


    def date_regexp_variables__initialize
#
#       A module having a method named 'initialize' will be called IF the class 'initialize' method calls 'super'.  BUT,
#       if there are more than one modules, only the last one included will be have its 'initialize' method called!   
#       To get around that, do the following code in a class's 'initialize' to run any included module's method having
#       a method named '[MODULE_NAME]__initialize'.   
#           self.singleton_class.included_modules.map { | mn | "#{mn}__initialize".downcase.to_sym }.filter_map { | mcim | self.send( mcim ) if self.respond_to?( mcim ) }
#

        usable_text_punct_RES           = Regexp::escape( separation_punctuation_O.usable_text_punct_chars )  # THIS NEEDS TO WRAPPED: [#{usable_text_punct_RES}]                            
#       dash_RES                        = "\\s{0,2}-\\s{0,2}"
        slash_dash_RES                  = "\\s{0,2}(?:-|/){1}\\s{0,2}"          # Note the \\ because it's a double quoted string.
        space_dash_RES                  = "\\s{0,2}(?:\\s|-){1}\\s{0,2}"
#       space_dash_slash_RES            = "\\s{0,2}(?:\\s|-|/){1}\\s{0,2}"
        comma_RES                       = "\\s{0,2},\\s{0,2}"
        space_comma_RES                 = "\\s{0,2}(?:\\s|,){1}\\s{0,2}"
        space_RES                       = "\\s{0,3}" 
        n_nn_RES                        = "(?:#{K.day_RES}|#{K.numeric_month_RES})" 
        year_RES                        = ( option_H[ :default_century_pivot_ccyymmdd ].nil? ) ? "#{K.year4_RES}" : "(#{K.year2_RES}|#{K.year4_RES})"  
                                                                            # For possible year positions
                                                                            # If no default year, only look for 4 digit years.

        self.date_text_separator_RES    = "(?:\\s*(?:#{option_H[ :date_text_separators ]})\\s*){1}"
        self.thru_date_separator_RES    = "(?:\\s{0,2}(?:#{option_H[ :thru_date_separators ]})\\s{0,2}){1}"
        self.thru_date_begin_delim_RES  = "\\G\\s*"
        self.thru_date_end_delim_RES    = "\\s*(?:[ #{usable_text_punct_RES}]|\\Z){1}"   
#                NOTE: The single space after the [ <<<(here, at the beginning)
#                      is NOT the same as "\\s*(?:[#{usable_text_punct_RES} ]|\\Z){1}"                            
#                                    -or- "\\s*(?:[#{usable_text_punct_RES}]| |\\Z){1}"   
#                But I don't know why!           
                 
#               NOTE: 'only-dates' or 'from-dates' can't START with '-'.
#               NOTE: \G is required when using a 'match( regexp, starting_point )'.  \A or ^ means from the start of the string
#                     whereas \G means from the start of the match!   
        self.begin_delim_RES            = "(?:\\G|\\s+|[ #{usable_text_punct_RES}]|#{date_text_separator_RES})"    
#                        NOTE: The single space after the [ <<<(here, at the beginning)
#                              is NOT the same as "\\s*(?:[#{usable_text_punct_RES} ]|\\Z){1}"                            
#                                            -or- "\\s*(?:[#{usable_text_punct_RES}]| |\\Z){1}"   
#                        But I don't know why!      
        self.end_delim_RES              = "\\s*(?:#{thru_date_separator_RES}|[ #{usable_text_punct_RES}]|\\Z){1}"  
#                                           NOTE: The single space after the [ <<<(here, at the beginning)
#                                                 is NOT the same as "\\s*(?:[#{usable_text_punct_RES} ]|\\Z){1}"                            
#                                                               -or- "\\s*(?:[#{usable_text_punct_RES}]| |\\Z){1}"   
#                                           But I don't know why!      

        date_pattern_RES_S = Struct.new( :pattern_name, :pattern_RES )      # The :pattern_name and length are computed and added later.
                                                                            # Literal spaces in the pattern are removed.  Spaces are just
                                                                            # for ease of reading. To match a space, use \\s instead.
                                                                            # And, it HAS to be \\ because it's a double quoted string.

        initial__date_pattern_RES_S__A = []

                                        #   fmt002__ = possible year 

        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt002__yyyy>           (?<year_M>#{year_RES}))" )
 

                                        #   fmt003__ = Dates in 'MMM dd, yyyy' format with spaces between 'MMM' 'dd'

        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt003__MMM_dd_yyyy>    (?<month_M>#{K.alpha_month_RES})#{space_RES}     (?<day_M>#{n_nn_RES})#{comma_RES}     (?<year_M>#{year_RES}))" )


                                        #   fmt005__ = Dates in 'MMM yyyy' or 'MMM-yyyy' format
                                        
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt005__MMM_yyyy>       (?<month_M>#{K.alpha_month_RES})#{space_dash_RES}     (?<year_M>#{year_RES}))" )
                
                
                                        #   fmt006__ = Dates in 'mm yyyy' or 'mm-yyyy' format
                                        
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt006__mm_yyyy>        (?<month_M>#{K.numeric_month_RES})#{slash_dash_RES}   (?<year_M>#{year_RES}))" )

         
                                        #   fmt007__ = Dates in 'yyyy MMM' or 'yyyy-MMM' format
                                        
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt007__yyyy_MMM>       (?<year_M>#{year_RES})#{space_dash_RES}    (?<month_M>#{K.alpha_month_RES}))" )

         
                                        #   fmt008__ = Dates in 'yyyy mm' or 'yyyy-mm' format
                                        
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt008__yyyy_mm>        (?<year_M>#{year_RES})#{slash_dash_RES}    (?<month_M>#{K.numeric_month_RES}))" )


                                        #   fmt009__ = Dates in 'dd [-/] MMM [-/] yyyy' or ' yyyy [-/] MMM [-/] dd' format

#       initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
#               "(?<fmt009__nn_MMM_nn>  (?:" +    
#                   "   (?: (?<nn_1st_M>#{n_nn_RES})#{space_dash_slash_RES} (?<month_M>#{K.alpha_month_RES})#{space_dash_slash_RES} (?<nn_3rd_M>#{n_nn_RES}))" +
#                   "|  (?: (?<nn_1st_M>#{n_nn_RES})#{space_dash_slash_RES} (?<month_M>#{K.alpha_month_RES})#{space_dash_slash_RES} (?<nn_3rd_M>#{year_RES}))" +
#                   "|  (?: (?<nn_1st_M>#{year_RES})#{space_dash_slash_RES} (?<month_M>#{K.alpha_month_RES})#{space_dash_slash_RES} (?<nn_3rd_M>#{n_nn_RES}))" +
#               "  ) )" )
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt009__nn_MMM_nn>  (?:" +    
                    "   (?: (?<nn_1st_M>#{n_nn_RES})#{slash_dash_RES} (?<month_M>#{K.alpha_month_RES})#{slash_dash_RES} (?<nn_3rd_M>#{n_nn_RES}))" +
                    "|  (?: (?<nn_1st_M>#{n_nn_RES})#{slash_dash_RES} (?<month_M>#{K.alpha_month_RES})#{slash_dash_RES} (?<nn_3rd_M>#{year_RES}))" +
                    "|  (?: (?<nn_1st_M>#{year_RES})#{slash_dash_RES} (?<month_M>#{K.alpha_month_RES})#{slash_dash_RES} (?<nn_3rd_M>#{n_nn_RES}))" +
                "  ) )" )


                                         #   fmt011__ = Dates in 'MMM dd - dd, yyyy format (hybid double)

        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt011__MMM_dd_dd_yyyy>     (?<month_M>#{K.alpha_month_RES})#{space_RES}    (?<day_M>#{n_nn_RES})"+
                                                              "#{thru_date_separator_RES}       (?<thru_day_M>#{n_nn_RES})#{space_comma_RES}  (?<year_M>#{year_RES}))" )


                                         #   fmt012__ = Dates in 'MMM dd - MMM dd, yyyy format (hybid double)
                                         
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt012__MMM_dd_MMM_dd_yyyy> (?<month_M>#{K.alpha_month_RES})#{space_RES}             (?<day_M>#{n_nn_RES})"+
              "#{thru_date_separator_RES}      (?<thru_month_M>#{K.alpha_month_RES})#{space_comma_RES}  (?<thru_day_M>#{n_nn_RES})#{comma_RES}(?<year_M>#{year_RES}))" )

                                        #   fmt013__ = Dates in 'MMM-MMMM yy[yy] format (hybid double) Note there's NO COMMA after the month

        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt013__MMM_MMM_yyyy>       (?<month_M>#{K.alpha_month_RES})#{space_RES}"+
              "#{thru_date_separator_RES}       (?<thru_month_M>#{K.alpha_month_RES})#{space_RES}                                              (?<year_M>#{year_RES}))" )


                                        #   fmt014__ = All numeric dates 'nn [-/] nn [-/] nn ' format,  the 1st and 3rd positions could be 1 or 4 digets (days or years)
                                        
        initial__date_pattern_RES_S__A << date_pattern_RES_S.new( nil,
                "(?<fmt014__nn_nn_nn>   (?:" +
                    "   (?: (?<nn_1st_M>#{n_nn_RES})#{slash_dash_RES}  (?<nn_2nd_M>#{n_nn_RES})#{slash_dash_RES}   (?<nn_3rd_M>#{year_RES}))" +
#                   "|  (?: (?<nn_1st_M>#{n_nn_RES})#{slash_dash_RES}  (?<nn_2nd_M>#{n_nn_RES})#{slash_dash_RES}   (?<nn_3rd_M>#{year_RES}))" +
                    "|  (?: (?<nn_1st_M>#{year_RES})#{slash_dash_RES}  (?<nn_2nd_M>#{n_nn_RES})#{slash_dash_RES}   (?<nn_3rd_M>#{n_nn_RES}))" +
                "  ) )" )

#       Set the pattern_name and length
        initial__date_pattern_RES_S__A.each_index do | idx |
            stringer = initial__date_pattern_RES_S__A[ idx ].pattern_RES.gsub( /\s{4,} /,'   ' )  # get rid of the big literal spaces.
            pattern_name = stringer[ stringer.index( '<' ) + 1 .. stringer.index( '>' ) - 1 ]
            if ( not pattern_name.match?( /^fmt\d{3}__/ ) ) then
                SE.puts "#{SE.lineno}: I shouldn't be here: pattern_name doesn't start with /fmtNNN__'#{pattern_name}'"
                raise
            end
            initial__date_pattern_RES_S__A[ idx ].pattern_RES  = stringer          
            initial__date_pattern_RES_S__A[ idx ].pattern_name = pattern_name
        end

#       Load date patterns to use
        self.date_pattern_RES_S__A = [ ]
        initial__date_pattern_RES_S__A.each_index do | idx |
            pattern_name = initial__date_pattern_RES_S__A[ idx ].pattern_name
            if ( pattern_name.match?( /#{option_H[ :pattern_name_RES ]}/ )) then
                date_pattern_RES_S__A.push( initial__date_pattern_RES_S__A[ idx ] )
            end
        end
        if ( date_pattern_RES_S__A.length == 0 ) then
            SE.puts "#{SE.lineno}: No patterns selected based on RE: #{option_H[ :pattern_name_RES ]}"
            raise
        end

#       Check for duplicate pattern names
        self.pattern_cnt_H = {}
        self.date_pattern_RES_S__A.each_index do | idx |
            pattern_name = date_pattern_RES_S__A[ idx ].pattern_name
            if ( pattern_cnt_H.key?( pattern_name ) ) then
                SE.puts "#{SE.lineno}: I shouldn't be here: duplicate pattern_name '#{pattern_name}'"
                raise
            end
            pattern_cnt_H[ pattern_name ] = 0
        end
                  
    end
    
end
