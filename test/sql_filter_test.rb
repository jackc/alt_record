require 'test/test_helper'

class SqlFilterTest < Test::Unit::TestCase
  def test_equality
    f1 = AltRecord::SqlFilter.new("1", "2")
    f2 = AltRecord::SqlFilter.new("1", "2")
    assert_equal f1, f2
  end
end
