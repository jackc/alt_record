require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'

$LOAD_PATH.unshift("lib")
require 'alt_record'

Rake::TestTask.new("test") do |t|
  t.test_files = Dir.glob("test/*_test.rb").sort
  t.verbose = true
end

spec = Gem::Specification.new do |s|
  s.name              = "alt_record"
  s.version           = AltRecord::VERSION
  s.summary           = "Alternate implementation of ActiveRecord pattern"
  s.homepage          = "http://github.com/JackC/alt_record"

  s.files             = FileList["[A-Z]*", "{bin,lib,rails,test}/**/*"]

  s.author            = "Jack Christensen"
  s.email             = "jack@jackchristensen.com"
end

Rake::GemPackageTask.new( spec ) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end
