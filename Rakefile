require 'rake/testtask'

task :default => :test
Rake::TestTask.new

Rake::TestTask.new(:performance) do |t|
  t.pattern = 'test/bench*.rb'
end

