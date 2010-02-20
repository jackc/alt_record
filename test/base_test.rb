require 'test/test_helper'

class BaseTest < Test::Unit::TestCase
  def test_new_record_should_be_true_for_unsaved_record
    assert WeatherStation.new.new_record?
  end
  
  def test_new_record_should_be_false_after_successful_save_of_new_record
    ws = WeatherStation.new
    ws.name = "Chicago"
    ws.save
    assert !ws.new_record?
  end
  
  def test_save_new_record_with_serial_column_gets_serial_value
    ws = WeatherStation.new
    ws.name = "Chicago"
    ws.save
    assert ws.id
  end
  
  def test_attributes_assignment
    ws = WeatherStation.new
    ws.attributes = { :name => "New York City" }
    assert_equal "New York City", ws.name
  end
end
