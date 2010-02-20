require 'test/test_helper'

class ColumnTest < Test::Unit::TestCase
  def test_serial_column_is_primary_key
    assert AltRecord::Column.new("id", :serial).primary_key?
  end
  
  
end
