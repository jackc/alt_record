require 'test/unit'
require 'altrecord'

AltRecord::Base.establish_connection :host => 'localhost', :dbname => 'Jack', :user => 'Jack', :password => 'Jack'

class WeatherStation < AltRecord::Base
  set_table_name "weather_stations"
  
  map_column 'id', :serial
  map_column 'name', :string
end