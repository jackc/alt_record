module AltRecord
  class DateColumn < Column
    def cast_value(v)
      Date.parse(v)
    end
  end
end