require 'test/test_helper'

class DataSetColumnFilterTest < Test::Unit::TestCase
  def test_column_name_filter_string_cs
    ds = AltRecord::DataSet.new(WeatherStation).name_cs("Chicago")
    assert_equal [ AltRecord::SqlFilter.new("name=?", "Chicago") ], ds.filters    
  end
  
  def test_column_name_filter_string_ci
    ds = AltRecord::DataSet.new(WeatherStation).name_ci("Chicago")
    assert_equal [ AltRecord::SqlFilter.new("LOWER(name)=LOWER(?)", "Chicago") ], ds.filters    
  end
end