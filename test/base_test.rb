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
  
  def test_save_new_record_with_composite_primary_key
    ws = WeatherStation.new :name => "London"
    ws.save
    
    dwm = DailyWeatherMeasurement.new :weather_station_id => ws.id, :date => Date.civil(2000,1,1), :low => 30, :high => 50
    dwm.save
  end
  
  def test_save_updates_record
    ws = WeatherStation.new
    ws.name = "Chicago"
    ws.save
    
    ws.name = "St. Paul"
    ws.save
    
    assert_equal "St. Paul", WeatherStation.find(ws.id).name
  end
  
  def test_attributes_assignment
    ws = WeatherStation.new
    ws.attributes = { :name => "New York City" }
    assert_equal "New York City", ws.name
  end
  
  def test_initialize_with_attributes
    ws = WeatherStation.new :name => "London"
    assert_equal "London", ws.name
  end
  
  def test_find_with_serial_primary_key
    ws = WeatherStation.new :name => "London"
    ws.save
    
    found_ws = WeatherStation.find(ws.id)
    assert found_ws.kind_of?(WeatherStation)
  end
  
  def test_find_with_composite_primary_key
    ws = WeatherStation.new :name => "London"
    ws.save
    
    dwm = DailyWeatherMeasurement.new :weather_station_id => ws.id, :date => Date.civil(2000,1,1), :low => 30, :high => 50
    dwm.save
    
    found_dwm = DailyWeatherMeasurement.find ws.id, Date.civil(2000,1,1)
  end

  def test_find_all
    assert WeatherStation.find_all.all? { |ws| ws.kind_of?(WeatherStation) }
  end

  def test_find_all_with_lazy_load
    weather_stations = WeatherStation.find_all
    assert weather_stations.all? { |ws| ws.attributes["notes"] == AltRecord::LazyLoadedValue }
    assert weather_stations.first.notes != AltRecord::LazyLoadedValue
    assert weather_stations.none? { |ws| ws.attributes["notes"] == AltRecord::LazyLoadedValue }
  end

  def test_find_all_with_lazy_load_with_composite_primary_key
    daily_weather_measurements = DailyWeatherMeasurement.find_all
    assert daily_weather_measurements.all? { |dwm| dwm.attributes["notes"] == AltRecord::LazyLoadedValue }
    assert daily_weather_measurements.first.notes != AltRecord::LazyLoadedValue
    assert daily_weather_measurements.none? { |dwm| dwm.attributes["notes"] == AltRecord::LazyLoadedValue }
  end

end
