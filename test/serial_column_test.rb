require 'test/test_helper'

class SerialColumnTest < Test::Unit::TestCase
  def test_serial_column_is_primary_key
    assert AltRecord::SerialColumn.new("id").primary_key?
  end
end
