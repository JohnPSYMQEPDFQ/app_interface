require 'module.ArchivesSpace.Konstants.rb'
require 'module.SE.rb'

#   A 'shelf' can't be a top container, the valid values are: 
#       Folder, box, carton, case, folder, frame, object, reel

#   The correct place for a 'shelf' is in the Location.   So, maybe someday...

class Shelf_ID_for_boxes
    def initialize
        @shelf_A=[]
        return self
    end
    def setup( boxes_on_shelf_string )
        regexp = /\A#{K.fmtr_shelf_box}:?\s*/i
        if ( ! boxes_on_shelf_string.sub!( regexp, '' ) ) then
            SE.puts "Not a Shelf_box string!"
            SE.q {[ 'boxes_on_shelf_string' ]}
            raise
        end

        regexp = /\A\s*shelf:(.+?)\s+boxs:(.+?)(shelf|\Z)/i
        min_box_range = 99999999
        max_box_range = 0
        while ( boxes_on_shelf_string.sub!( regexp, '' ) )
            SE.q {[ '$~' ]}  if ( $DEBUG )
            last_group = $3
            shelf_id = $1.strip
            box_ranges = $2.strip
            box_ranges_A = box_ranges.split( /,\s*/ )
            box_ranges_A.each do | e |
                case e.count( '-' )
                when 0
                    if ( ! e.integer? ) then
                        SE.puts "#{SE.lineno}: Non-integer found in box ranges '#{e}'"
                        SE.q {[ 'boxes_on_shelf_string' ]}
                        raise
                    end
                    @shelf_A.push( [ e.to_i .. e.to_i, shelf_id ] )
                    min_box_range = e.to_i if ( e.to_i < min_box_range )
                    max_box_range = e.to_i if ( e.to_i > max_box_range )
                when 1
                    ( range_begin, range_end ) = e.split( /\s*-\s*/ )
                    if ( ! range_begin.integer? ) then
                        SE.puts "#{SE.lineno}: Non-integer found in box ranges '#{range_begin}'"
                        SE.q {[ 'boxes_on_shelf_string' ]}
                        raise
                    end
                    if ( ! range_end.integer? ) then
                        SE.puts "#{SE.lineno}: Non-integer found in box ranges '#{range_end}'"
                        SE.q {[ 'boxes_on_shelf_string' ]}
                        raise
                    end
                    @shelf_A.push( [ range_begin.to_i .. range_end.to_i, shelf_id ] )
                    min_box_range = range_begin.to_i if ( range_begin.to_i < min_box_range )
                    max_box_range = range_end.to_i   if ( range_end.to_i > max_box_range )
                else
                    SE.puts "#{SE.lineno}: Found a range with two dashes '#{e}'"
                    SE.q {[ 'e', 'box_ranges', 'boxes_on_shelf_string' ]}
                    raise
                end
            end
            break if ( last_group.blank? )
            boxes_on_shelf_string = last_group + boxes_on_shelf_string
        end
        SE.q {[ '@shelf_A' ]}  if ( $DEBUG )
        SE.q {[ 'min_box_range', 'max_box_range' ]}  if ( $DEBUG )

        dup_shelfs_A = []
        min_box_range.upto( max_box_range ).map do | box_num |
            a1 = @shelf_A.select{ | box_range_A | box_range_A[ 0 ] === box_num }.map{ | box_range_A | box_range_A[ 1 ] } 
            if ( a1.length > 1 ) then
                dup_shelfs_A << "Box num #{box_num} has #{a1.length} shelfs '#{a1.join( ', ' )}'"
            end
        end
        if ( dup_shelfs_A.length > 0 ) then
            SE.puts "#{SE.lineno}: Boxes with duplicate shelfs found."
            SE.q {[ 'dup_shelfs_A' ]}
            raise
        end
        return self
    end
  
    def of_box( box_num )
        if ( ! box_num.integer? ) then
            SE.puts "#{SE.lineno}: Non-integer found for box_num '#{box_num}'"
            raise
        end
        @shelf_A.each do | box_range_A |
            return box_range_A[ 1 ] if ( box_range_A[ 0 ] === box_num.to_i )
        end
        SE.puts "#{SE.lineno}: I couldn't find a shelf-ID for box '#{box_num}'"
        raise
    end

end

#shelf_id = Shelf_ID_for_boxes.new
#shelf_id.setup( "__Shelf_Box__:  Shelf:I2.210.E5  Boxs: 1-6, 9 Shelf:I2.210.E6  Boxs: 6-8" )
#puts "#{shelf_id.of_box( 6 )}"


