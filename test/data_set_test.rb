require 'test/test_helper'

class DataSetTest < Test::Unit::TestCase
  def test_all
    assert WeatherStation.where('true').all
  end
end
