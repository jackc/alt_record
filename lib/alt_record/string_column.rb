module AltRecord
  class StringColumn < Column
    def cast_value(v)
      v.to_s
    end
  end
end