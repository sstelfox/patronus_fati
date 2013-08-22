
base_spec_path = File.expand_path(File.dirname(__FILE__))
test_files = Dir.glob(File.join(base_spec_path, '**', '*_spec.rb'))
test_files.each { |f| require_relative f }
