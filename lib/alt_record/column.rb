module AltRecord
  class Column
    attr_reader :name

    def initialize(name, options={})
      @name = name
      @primary_key = options[:primary_key]
    end

    def primary_key?
      @primary_key
    end

    def cast_value(v)
      raise "not implemented"
    end

    def equal_filter(v)
      SqlFilter.new("#{name}=?", v)
    end

    def in_filter(*values)
      SqlFilter.new("#{name} IN(#{(['?'] * values.size).join(', ')})", *values)
    end

    def between_filter(a, b)
      SqlFilter.new("#{name} BETWEEN ? AND ?", a, b)
    end

    def greater_than_filter(v)
      SqlFilter.new("#{name} > ?", v)
    end

    def greater_than_or_equal_filter(v)
      SqlFilter.new("#{name} >= ?", v)
    end

    def less_than_filter(v)
      SqlFilter.new("#{name} < ?", v)
    end

    def less_than_or_equal_filter(v)
      SqlFilter.new("#{name} <= ?", v)
    end
  end
end