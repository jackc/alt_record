require 'test/unit'
require 'alt_record'

AltRecord::Base.establish_connection :host => 'localhost', :dbname => 'Jack', :user => 'Jack', :password => 'Jack'

class WeatherStation < AltRecord::Base
  set_table_name "weather_stations"
  
  map_column 'id', :serial
  map_column 'name', :string
  map_column 'notes', :string, :lazy => true
end

class DailyWeatherMeasurement < AltRecord::Base
  set_table_name "daily_weather_measurements"
  
  map_column 'weather_station_id', :integer, :primary_key => true
  map_column 'date', :date, :primary_key => true
  map_column 'low', :integer
  map_column 'high', :integer
  map_column 'notes', :string, :lazy => true
end