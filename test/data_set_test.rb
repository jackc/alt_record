require 'test/test_helper'

class DataSetTest < Test::Unit::TestCase

  def test_model_class
    assert_equal WeatherStation, AltRecord::DataSet.new(WeatherStation).model_class
  end
  
  def test_filters
    assert_equal [], AltRecord::DataSet.new(WeatherStation).filters
  end

  def test_all
    assert WeatherStation.where('true').all
  end
end
