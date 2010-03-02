module AltRecord
  class StringColumn < Column
    def cast_value(v)
      v.to_s
    end
    
    def equal_cs_filter(v)
      SqlFilter.new("#{name}=?", v)
    end

    def equal_ci_filter(v)
      SqlFilter.new("LOWER(#{name})=LOWER(?)", v)
    end
  end
end