require 'bundler/gem_tasks'

task :default do
  tasks = {
    docs: 'Document Generation',
    flog: 'Flog Report',
    rubocop: 'RuboCop Report',
    spec: 'RSpec Tests'
  }

  tasks.each do |task, title|
    next unless Rake::Task.task_defined?(task)

    puts format('%s:\n', title)
    Rake::Task[task].invoke
    puts
  end
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new(:docs)
rescue LoadError
end

begin
  require 'flog_cli'
  require 'path_expander'

  desc 'Analyze code complexity'
  task :flog do
    expander = PathExpander.new(['lib/'], '**/*.{rb,rake}')
    files = expander.process

    flog = FlogCLI.new(quiet: false, continue: false, parser: RubyParser,
                       score: true)
    flog.flog(*files)
    flog.report
  end
rescue LoadError
end

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new(:rubocop) do |task|
    task.formatters = %w(simple offenses)
    task.fail_on_error = false
    task.options = %w(--format html --out doc/rubocop.html lib/ spec/)
  end
rescue LoadError
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task :environment do
  base_path = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
  $LOAD_PATH.unshift(base_path) unless $LOAD_PATH.include?(base_path)

  require 'patronus_fati'
end

desc 'Start a pry session with the code loaded'
task :console => [:environment] do
  require 'pry'
  pry
end
