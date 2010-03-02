require 'test/test_helper'

class BaseColumnFilterTest < Test::Unit::TestCase
  def test_column_name_filter_simple
    AltRecord::DataSet.new(WeatherStation)
    assert WeatherStation.new.new_record?
  end
  
  
end
