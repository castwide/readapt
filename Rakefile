require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"
require 'readapt/version'
require 'tmpdir'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

# Compile tasks
Rake::ExtensionTask.new "readapt" do |ext|
  ext.lib_dir = "lib/readapt"
end
