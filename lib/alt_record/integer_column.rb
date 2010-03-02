module AltRecord
  class IntegerColumn < Column
    def cast_value(v)
      Integer(v)
    end
  end
end