#   Part of class.Find_Dates_in_String.rb

module Date_Clumps_parse_text_dates
    public  attr_reader :date_clump_C, :possible_date_C, :date_match_C, :ymd_C,
                        :date_clump_S__A
    private attr_writer :date_clump_C, :possible_date_C, :date_match_C, :ymd_C,
                        :date_clump_S__A
    
    #   NOTE:   "def self.initialize" will initialize module variables, NOT the instance variables of the class
    #           the module is included in !!!!!!  See the comment in 'Find_Dates_in_String::initialize' for how
    #           to call a module's "def initialize".  BUT, the "def initialize" is called ONLY at
    #           instance initialize!!!  If the module is supposed to initialize some variables FOR the module
    #           each time a method is called in the class, I decided to name a module method the same name
    #           as the instance method and call it like is being done for "def initialize".
    #           See the :do_find method in "class.Find_Dates_in_String.rb".
    def do_find( )   
  
        self.date_clump_S__A = [ ]
        self.date_clump_C = Struct.new( :full_match_string__everything,
                                        :full_match_string__begin_delim__lstrip,
                                        :date_match_string,
                                        :full_match_string__end_delim__rstrip,
                                        :uid,                 
                                        :full_match_string__everything__beginning_offset,
                                        :full_match_string__begin_delim__lstrip__adj_offset, 
                                        :date_match_string__beginning_offset,
                                        :date_match_S__A,
                                        :circa,
                                        :bulk,
                                        :morality,
                                        :error_msg,
                                        keyword_init: true
                                        )   do
                                                def judge_date( judgement, input_error_msg, print = true )
                                                    SE.puts input_error_msg if ( print )
                                                    SE.puts ''              if ( print )
                                                    self.error_msg  = ''    if ( error_msg.nil? )
                                                    self.error_msg += '  '  if ( error_msg.not_blank? )
                                                    self.error_msg += input_error_msg
                                                    return if ( judgement.nil? )
                                                    if ( morality.nil? ) then
                                                        self.morality = judgement
                                                        return
                                                    end
                                                    if ( morality == :bad ) then
                                                        return if ( judgement == :bad )
                                                        SE.puts "#{SE.lineno}: Date morality was already bad, not changed to #{judgement}"
                                                        return
                                                    end
                                                    SE.puts "#{SE.lineno}: Date morality was already #{morality}, changed to #{judgement}"
                                                    self.morality = judgement
                                                    return
                                                end
                                                def from
                                                    if ( date_match_S__A.length > 2 ) then
                                                        SE.puts "#{SE.lineno}: I shouldn't be here: date_clump_S.length > 2"
                                                        SE.q { 'date_match_S' }
                                                        raise
                                                    end
                                                    return date_match_S__A[ 0 ]
                                                end
                                                def thru
                                                    if ( date_match_S__A.length > 2 ) then
                                                        SE.puts "#{SE.lineno}: I shouldn't be here: date_clump_S.length > 2"
                                                        SE.q { 'date_match_S' }
                                                        raise
                                                    end
                                                    return date_match_S__A[ 1 ]
                                                end      
                                                def as_from_date
                                                    date_match_S = from
                                                    if ( date_match_S.nil? ) then
                                                        SE.puts "#{SE.lineno}: I shouldn't be here: date_clump_S without a from date"
                                                        SE.q { 'date_match_S' }
                                                        raise
                                                    end
                                                    return date_match_S.as_date
                                                end
                                                def as_thru_date
                                                    date_match_S = thru
                                                    if ( date_match_S.nil? ) then
                                                        return ''
                                                    else
                                                        return date_match_S.as_date
                                                    end
                                                end 
                                                def full_match_string__with_original_dates_and_modifiers
                                                    stringer  = full_match_string__begin_delim__lstrip
                                                    stringer += date_match_string
                                                    stringer += full_match_string__end_delim__rstrip
                                                    return stringer
                                                end          
                                            end
                                            
        self.possible_date_C = Struct.new( :pattern_name,
                                           :regexp,
                                           :match_O,
                                         )


        self.date_match_C = Struct.new( :match_O,
                                        :pattern_name,
                                        :regexp,
                                        :ymd_S,
                                        :strptime_O,
                                        :as_date,
                                      ) do
                                            def circa
                                                return false if ( match_O.named_captures[ 'date_modifier' ].nil? )
                                                return true if (match_O.named_captures[ 'date_modifier' ].match?( /^(circa|ca([.])?)/i ) )
                                                return false
                                            end
                                            def bulk
                                                return false if ( match_O.named_captures[ 'date_modifier' ].nil? )
                                                return true if (match_O.named_captures[ 'date_modifier' ].match?( /^bulk/i ) )
                                                return false
                                            end
                                            def all_pieces
                                                return  match_O.named_captures[ 'begin_M' ] +
                                                        match_O.named_captures[ 'date_M' ] +    # Includes 'bulk' and 'circa'
                                                        match_O.named_captures[ 'end_M' ]
                                            end
                                            def piece( num )
                                                piece_A = [ match_O.named_captures[ 'begin_M' ],
                                                            match_O.named_captures[ 'date_M' ], # Includes 'bulk' and 'circa'
                                                            match_O.named_captures[ 'end_M' ],
                                                          ]
                                                if ( num.is_a?( Integer )) then
                                                    return piece_A[ num ]
                                                end
                                                if ( num.is_a?( Range )) then
                                                    return piece_A[ num ].join('')
                                                end
                                                raise "#{SE.lineno}: I shouldn't be here: Was expect a number or range."
                                            end
                                            alias_method :pieces, :piece
                                        end
                                                                        
        self.ymd_C = Struct.new( :year, :month, :day )
    end    


    def get_tree_of__possible_date_S__A_A( param__initial_offset, param__looking_for_a_thru_date = false, param__level = 0 )
#       SE.q {[ 'param__initial_offset', 'output_data_O.string' ]}
        tree_of__possible_date_S__A_A = [ ]
        if ( param__level > 10 ) then
            SE.puts "#{SE.lineno}: In to deep"
            SE.q { 'tree_of__possible_date_S__A_A' }
            raise
        end
        date_pattern_RES_S__A.each do | date_pattern_RES_S |
            pattern_name = date_pattern_RES_S.pattern_name
            if ( param__looking_for_a_thru_date ) then
                regexp = %r{(?<begin_M>#{thru_date_begin_delim_RES})(?<date_M>#{date_pattern_RES_S.pattern_RES})(?<end_M>#{thru_date_end_delim_RES})}xi
            else
                regexp = %r{(?<begin_M>#{begin_delim_RES})(?<date_M>#{date_modifier_RES}#{date_pattern_RES_S.pattern_RES})(?<end_M>#{end_delim_RES})}xi               
            end
            scan_begin_offset = param__initial_offset + 0
            ld = SE::Loop_detector.new( 100 )
            loop do   
                ld.loop
                break if ( scan_begin_offset >= output_data_O.string.maxoffset )
                match_O = output_data_O.string.match( regexp, scan_begin_offset )
                break if ( match_O.nil? )
              # SE.q {[ 'scan_begin_offset', 'output_data_O.string.maxoffset', 'output_data_O.string' ]}
              # SE.q {[ 'match_O' ]}
                match_string      = match_O.named_captures[ 'begin_M' ] +
                                    match_O.named_captures[ 'date_M' ] +
                                    match_O.named_captures[ 'end_M' ]
                match_offset      = match_O.offset( :begin_M )[ 0 ]
                match_length      = match_string.length
                scan_begin_offset = match_offset + match_length
                if ( match_O.named_captures[ 'end_M' ].match?( /#{thru_date_separator_RES}/ix ) ) then
                    result = get_tree_of__possible_date_S__A_A( scan_begin_offset, true, param__level + 1 )
                    tree_of__possible_date_S__A_A << [ possible_date_C.new( pattern_name, regexp, match_O ), result ]
                else
                    tree_of__possible_date_S__A_A << [ possible_date_C.new( pattern_name, regexp, match_O ), [ ] ]
                end
            end
        end
        return tree_of__possible_date_S__A_A
    end
    
    def get_combinations_of__possible_date_S__A_A( param__tree_of__possible_date_S__A_A, 
                                                   param__combinations_of__possible_date_S__A_A = [], 
                                                   param__predecessors_A = [] )
        param__tree_of__possible_date_S__A_A.each do | param__tree_of__possible_date_S__A |
            new_predecessors_A = []
            new_predecessors_A.concat( param__predecessors_A )
            new_predecessors_A.append( param__tree_of__possible_date_S__A[ 0 ] )
            if ( param__tree_of__possible_date_S__A[ 1 ].length > 0 ) then
                get_combinations_of__possible_date_S__A_A( param__tree_of__possible_date_S__A[ 1 ], 
                                                           param__combinations_of__possible_date_S__A_A, 
                                                           new_predecessors_A)
            else
                param__combinations_of__possible_date_S__A_A << new_predecessors_A
            end
        end
        return param__combinations_of__possible_date_S__A_A
    end

    def get_the_longest_date( )
        tree_of__possible_date_S__A_A = get_tree_of__possible_date_S__A_A( 0 )
        if ( option_H[ :debug_options ].include?( :print_date_tree )) then
            SE.puts ''
            SE.q { 'tree_of__possible_date_S__A_A' }
        end  
        
        return [ ] if ( tree_of__possible_date_S__A_A.empty? )
        
        combinations_of__possible_date_S__A_A = get_combinations_of__possible_date_S__A_A( tree_of__possible_date_S__A_A )
        if ( option_H[ :debug_options ].include?( :print_unsorted_combinations )) then
            SE.puts ''
            SE.q { 'combinations_of__possible_date_S__A_A' }
        end
        
        sorted_combinations_of__possible_date_S__A_A = combinations_of__possible_date_S__A_A.sort_by do | combinations_of__possible_date_S__A | 
                            [   
                                0 - combinations_of__possible_date_S__A.sum { | possible_date_S | possible_date_S.match_O[ 0 ].gsub( /\s/,'' ).length },
                                0 + combinations_of__possible_date_S__A.length,                                                
                                0 + combinations_of__possible_date_S__A[ 0 ].match_O.offset( :begin_M )[ 0 ],
                            ]
                            end
        if ( option_H[ :debug_options ].include?( :print_sorted_combinations )) then
            SE.puts ''
            SE.q { 'sorted_combinations_of__possible_date_S__A_A' }
        end
#
#       Return only the longest date ( element 0 after sorting) of all the dates found.
        date_match_S__A = [ ]
        sorted_combinations_of__possible_date_S__A_A[ 0 ].each do | possible_date_S |             
            date_match_S = date_match_C.new(   possible_date_S.match_O,
                                               possible_date_S.pattern_name,
                                               possible_date_S.regexp,
                                             )
            date_match_S__A << date_match_S
        end
        return date_match_S__A         
    end
    
    def date_clumps_parse_text_dates( )

        ld = SE::Loop_detector.new( 100 )
        loop do   
            ld.loop
            if ( option_H[ :debug_options ].include?( :print_output_data )) then
                SE.puts ''
                SE.q { 'output_data_O.string' }
            end     
            
#           date_match_S__A is the from date [element 0] and (optional) thru date [element 1].  
            date_match_S__A = get_the_longest_date( )
            break if ( date_match_S__A.empty? )
            
            date_clump_S = date_clump_C.new( full_match_string__everything: '',
                                             full_match_string__begin_delim__lstrip: '', 
                                             date_match_string: '',
                                             full_match_string__end_delim__rstrip: '',
                                             date_match_S__A: date_match_S__A,
                                             circa: false,
                                             bulk: false,
                                            )
            date_clump_S__A << date_clump_S
            
            date_clump_S.date_match_S__A.each_with_index do | date_match_S, date_match_idx |
                               
                date_match_string = ''
                full_match_string__begin_delim__lstrip = ''
                full_match_string__end_delim__rstrip = ''
                full_match_string__everything = ''
#                    First date or only date
                if ( date_match_idx == 0 ) 
                    date_clump_S.uid                                                   = date_clump_uid_O.uid_of_num( date_clump_S__A.length )                    
                    date_clump_S.date_match_string__beginning_offset                   = date_match_S.match_O.offset( :date_M )[ 0 ]  
                    date_clump_S.circa                                                 = date_match_S.circa
                    date_clump_S.bulk                                                  = date_match_S.bulk
                    date_match_string                                                 += date_match_S.piece( 1 )   # includes 'bulk' and 'circa/ca'
                    
                    stringer                                                           = date_match_S.piece( 0 ).lstrip
                    offset_adj = date_match_S.piece( 0 ).length - stringer.length
                    date_clump_S.full_match_string__everything__beginning_offset       = date_match_S.match_O.offset( :begin_M )[ 0 ]
                    date_clump_S.full_match_string__begin_delim__lstrip__adj_offset    = date_match_S.match_O.offset( :begin_M )[ 0 ] + offset_adj
                    full_match_string__begin_delim__lstrip                             = stringer
#                        First date
                    if ( date_match_idx < date_clump_S.date_match_S__A.maxindex ) then
                        date_match_string                                             += date_match_S.piece( 2 )
#                        Only date
                    else
                        full_match_string__end_delim__rstrip                           = date_match_S.piece( 2 ).rstrip
                    end
                    full_match_string__everything                                     += date_match_S.all_pieces
                end
#                   Middle dates (NOT the first or last)
                if ( date_match_idx > 0 and date_match_idx < date_clump_S.date_match_S__A.maxindex ) then
                    date_match_string                                                 += date_match_S.all_pieces
                    full_match_string__everything                                     += date_match_S.all_pieces
                end 
#                   Last date                
                if ( date_match_idx > 0 and date_match_idx == date_clump_S.date_match_S__A.maxindex ) then
                    date_match_string                                                 += date_match_S.pieces( 0 .. 1 )
                    stringer                                                           = date_match_S.piece( 2 ).rstrip
                    if ( not ( stringer.length > 1 and stringer.match( /#{end_delim_RES}/ ) and
                                                       full_match_string__begin_delim__lstrip[ 0, 1 ].match( /#{begin_delim_RES}/ ) ) ) then
                        full_match_string__end_delim__rstrip                           = stringer
                    end                         
                    full_match_string__everything                                     += date_match_S.all_pieces
                end
                    
                date_clump_S.date_match_string                                        += date_match_string  
                date_clump_S.full_match_string__begin_delim__lstrip                   += full_match_string__begin_delim__lstrip
                date_clump_S.full_match_string__end_delim__rstrip                     += full_match_string__end_delim__rstrip
                date_clump_S.full_match_string__everything                            += full_match_string__everything
                pattern_cnt_H[ date_match_S.pattern_name ] += 1
 
                date_match_S.ymd_S = ymd_C.new( ) 
                if ( date_match_S.pattern_name.match?( /__nn_nn_nn/ ) ) then
                    if ( date_match_S.match_O.named_captures[ 'nn_1st_M' ].length == 4 ) then
                        date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                        date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'nn_2nd_M' ]
                        date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                    else
                        case option_H[ :nn_nn_nn_date_order ]
                        when :mm_dd_yy
                            date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                            date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_2nd_M' ]
                            date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                        when :dd_mm_yy
                            date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                            date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'nn_2nd_M' ]
                            date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                        when :yy_mm_dd
                            date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                            date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'nn_2nd_M' ]
                            date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                        else
                            SE.puts "#{SE.lineno}: I shouldn't be here: #{date_match_S.pattern_name}: "+
                                                 "'#{date_match_S.all_pieces}' > "+
                                                 "invalid :nn_nn_nn_date_order value '#{option_H[ :nn_nn_nn_date_order ]}'"
                            raise
                        end
                    end
                elsif ( date_match_S.pattern_name.match?( /__nn_MMM_nn/ ) ) then
                    case option_H[ :nn_mmm_nn_day_year_order ]
                    when :yy_mm_dd
                        date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                        date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'month_M' ]
                        date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                    when :dd_mm_yy
                        date_match_S.ymd_S.day   = date_match_S.match_O.named_captures[ 'nn_1st_M' ]
                        date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'month_M' ]
                        date_match_S.ymd_S.year  = date_match_S.match_O.named_captures[ 'nn_3rd_M' ]
                    else
                        SE.puts "#{SE.lineno}: I shouldn't be here: #{date_match_S.pattern_name}: "+
                                             "'#{date_match_S.all_pieces}' > "+
                                             "invalid :nn_mmm_nn_day_year_order value '#{option_H[ :nn_mmm_nn_day_year_order ]}'"
                        raise
                    end
                elsif ( date_match_S.pattern_name.match?( /__(MMM_dd_dd_yy|MMM_dd_MMM_dd_yy|MMM_MMM_yy)/ )) then  
                    date_match_S.ymd_S.year  =  date_match_S.match_O.named_captures[ 'year_M' ]
                    date_match_S.ymd_S.month =  date_match_S.match_O.named_captures[ 'month_M' ]
                    date_match_S.ymd_S.day   =  date_match_S.match_O.named_captures[ 'day_M' ]
                    
                    generated_thru_date_match_S = date_match_C.new( date_match_S.match_O )
                    generated_thru_date_match_S.pattern_name = date_match_S.pattern_name
                    generated_thru_date_match_S.ymd_S = ymd_C.new( )
                    generated_thru_date_match_S.ymd_S.year =  date_match_S.match_O.named_captures[ 'year_M' ]
                    if ( date_match_S.match_O.named_captures.key?( 'thru_month_M' )) then
                        generated_thru_date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'thru_month_M' ]
                    else
                        generated_thru_date_match_S.ymd_S.month = date_match_S.match_O.named_captures[ 'month_M' ]
                    end
                    if ( date_match_S.match_O.named_captures.key?( 'thru_day_M' )) then
                        generated_thru_date_match_S.ymd_S.day = date_match_S.match_O.named_captures[ 'thru_day_M' ]
                    else
                        generated_thru_date_match_S.ymd_S.day = date_match_S.match_O.named_captures[ 'day_M' ]
                    end
                    date_clump_S.date_match_S__A << generated_thru_date_match_S
                else
                    date_match_S.ymd_S.year  =  date_match_S.match_O.named_captures[ 'year_M' ]
                    date_match_S.ymd_S.month =  date_match_S.match_O.named_captures[ 'month_M' ]
                    date_match_S.ymd_S.day   =  date_match_S.match_O.named_captures[ 'day_M' ]
                end
                
                break if (date_match_S.piece( 2 ) !~ /#{thru_date_separator_RES}/ix ) 
            end 

#           SE.q {[ 'date_clump_S' ]}                     
            output_data_O.string[ date_clump_S.full_match_string__begin_delim__lstrip__adj_offset, 
                                  date_clump_S.full_match_string__with_original_dates_and_modifiers.length ] = date_clump_S.uid
                      
        end
    end
end
