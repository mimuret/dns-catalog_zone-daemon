require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |test|
  test.libs << 'test'
  test.test_files = Dir['test/**/t_*.rb']
  test.verbose = true
end
