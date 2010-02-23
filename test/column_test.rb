require 'test/test_helper'

class ColumnTest < Test::Unit::TestCase
  def test_options_primary_key
    assert AltRecord::Column.new("id", :primary_key => true).primary_key?
    assert !AltRecord::Column.new("id", :primary_key => false).primary_key?
  end
end
