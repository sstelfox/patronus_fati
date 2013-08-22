require "bundler/gem_tasks"

desc "Run all the tests"
task :test do
  base_spec_path = File.expand_path(File.dirname(__FILE__))
  test_files = Dir.glob(File.join(base_spec_path, 'spec', '**', '*_spec.rb'))
  test_files.each { |f| require_relative f }
end
