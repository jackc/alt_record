require 'rake'
require 'rake/testtask'

Rake::TestTask.new("test") do |t|
  t.test_files = Dir.glob("test/*_test.rb").sort
  t.verbose = true
end

