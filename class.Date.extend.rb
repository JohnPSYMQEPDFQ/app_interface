
class Date

    def last_day_of_month( )
        return self.prev_day(self.day - 1).next_month(1).prev_day(1)
    end

    def last_day_of_month?( )
        return ( self == self.last_day_of_month )
    end   
end
