require 'test/test_helper'

class ColumnTest < Test::Unit::TestCase
  def test_options_primary_key
    assert AltRecord::Column.new("id", :primary_key => true).primary_key?
    assert !AltRecord::Column.new("id", :primary_key => false).primary_key?
  end
  
  def test_equal_filter
    assert_equal AltRecord::SqlFilter.new("num=?", 42), AltRecord::Column.new("num").equal_filter(42)
  end
  
  def test_in_filter
    assert_equal AltRecord::SqlFilter.new("num IN(?, ?)", 10, 42), AltRecord::Column.new("num").in_filter(10, 42)
  end
  
  def test_between_filter
    assert_equal AltRecord::SqlFilter.new("num BETWEEN ? AND ?", 18, 29), AltRecord::Column.new("num").between_filter(18, 29)
  end
  
  def test_greater_than_filter
    assert_equal AltRecord::SqlFilter.new("num > ?", 42), AltRecord::Column.new("num").greater_than_filter(42)
  end
  
  def test_greater_than_or_equal_filter
    assert_equal AltRecord::SqlFilter.new("num >= ?", 42), AltRecord::Column.new("num").greater_than_or_equal_filter(42)
  end
  
  def test_less_than_filter
    assert_equal AltRecord::SqlFilter.new("num < ?", 42), AltRecord::Column.new("num").less_than_filter(42)
  end
  
  def test_less_than_or_equal_filter
    assert_equal AltRecord::SqlFilter.new("num <= ?", 42), AltRecord::Column.new("num").less_than_or_equal_filter(42)
  end
end
