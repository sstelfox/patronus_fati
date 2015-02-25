require "bundler/gem_tasks"

task :environment do
  base_path = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
  $LOAD_PATH.unshift(base_path) unless $LOAD_PATH.include?(base_path)

  require 'patronus_fati'
end

task :database => [:environment] do
  DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite::memory:')
  DataMapper.repository(:default).adapter.resource_naming_convention = PatronusFati::NullTablePrefix
  DataMapper.finalize
  DataMapper.auto_upgrade!
end

desc "Start a pry session with the code loaded"
task :console => [:database, :environment] do
  require 'pry'
  pry
end
