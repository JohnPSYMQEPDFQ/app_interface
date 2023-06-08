

require 'module.SE.rb'
require 'module.ArchivesSpace.Konstants.rb'

class Spreadsheet_CSV

    def initialize( ead_id )
        @ead_id = ead_id
        @column_translation_H = {   # ArchivesSpace to Spreadsheet names
            K.ead_id => K.ead ,
            K.label => K.dates_label ,
            K.certainty => K.date_certainty ,
            K.physdisc => [ K.n_physdesc, K.p_physdesc ] ,  #  Text and Publish-flag columns
        }
        @row_H = initialize_row_H()        
        puts '"' + @row_H.keys.join('","') + '"'
    end
    attr_accessor :row_H
    
    def translate_column( p1_k )
        if ( @column_translation_H.has_key?( p1_k ) ) then
            return @column_translation_H[ p1_k ]
        end
        return p1_k
    end
    
    def initialize_row_H( )      
        h = {   
                "ArchivesSpace field code (please don't edit this row)" => "" ,  # <<< This needs to be in the header of column 1
                K.ead => @ead_id ,
                K.title => K.undefined ,
                K.hierarchy => K.undefined ,
                K.level => K.undefined ,
                K.publish => K.spreadsheet_true ,
            # Dates
                K.dates_label => "" ,
                K.begin => "" ,
                K.end => "" ,
                K.date_type => "" ,
                K.expression => "" ,
                K.date_certainty => ""  ,  
            # Notes: physical discription
                translate_column( K.physdisc )[ 0 ] => "" , #  Text of note
                translate_column( K.physdisc )[ 1 ] => "" , #  Publish-flag of note
            }
        return h
    end
    private :initialize_row_H
    
    def load_dates( p1_date_A )
        p1_date_A.each_index do | idx |
            if ( idx > 0 ) then
                SE.puts "#{SE.lineno}: Not programmed for more than one date"
                SE.ap "#{$.}: idx=#{idx}" 
                SE.ap "#{$.}: p1_date_A:", p1_date_A
                raise
            end
            p1_date_A[idx].keys.each do | k |
                @row_H[ translate_column( k ) ] = p1_date_A[idx][ k ]
            end
        end
    end
    
    def load_notes( p1_note_A )
#       Only handles singlepart notes

        p1_note_A.each_index do | idx |
            if ( idx > 0 ) then
                SE.puts "#{SE.lineno}: Not programmed for more than one note"
                SE.ap "#{$.}: idx=#{idx}"
                SE.ap "#{$.}: p1_note_A:", p1_note_A
                raise
            end 
            if ( ! p1_note_A[ idx ].has_key?( K.type ) ) then
                SE.puts "#{SE.lineno}: Was expecting a key of 'K.type' in p1_note_A[ %{idx} ]"
                SE.ap "#{$.}: p1_note_A[ #{idx} ]:", p1_note_A[ idx ]
                raise
            end
            if ( ! p1_note_A[ idx ].has_key?( K.content ) ) then
                SE.puts "#{SE.lineno}: Was expecting a key of 'K.content' in p1_note_A[ %{idx} ]"
                SE.ap "#{$.}: p1_note_A[ #{idx} ]:", p1_note_A[ idx ]
                raise
            end
            if ( translate_column( p1_note_A[ idx ][K.type ] ) == nil ) then
                SE.puts "#{SE.lineno}: No translation column programmed for note-type '#{p1_note_A[ idx ][K.type ]}'"
                SE.ap "#{$.}: p1_note_A[ #{idx} ]:", p1_note_A[ idx ]
                raise
            end
            @row_H[ translate_column( p1_note_A[ idx ][K.type ] )[0] ] = p1_note_A[ idx ][K.content ].join( "\n" ) 
            @row_H[ translate_column( p1_note_A[ idx ][K.type ] )[1] ] = K.spreadsheet_true
        end
    end
    
    def puts_row( )
        h = initialize_row_H( )
        @row_H.keys.each do | k | 
            if (! h.has_key?( k )) then
                SE.puts "#{SE.lineno}: =============================================="
                SE.puts "Unexpected key: '#{k}' in row_H"
                SE.ap @row_H
                raise
            end
        end
        a1=[]
        h.keys.each do | k | 
            if ( @row_H.has_key?( k ) ) then
                a1.push( @row_H[ k ] )
            else
                a1.push( "" )
            end
        end
        puts '"' + a1.join('","') + '"'
        @row_H = initialize_row_H()
    end
end
