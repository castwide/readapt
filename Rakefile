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

namespace :install do
  desc 'Install on Windows'
  task :win do
    Dir.mktmpdir do |tmp|
      gemfile = File.join(tmp, 'readapt.gem')
      system("gem build readapt.gemspec -o #{gemfile}") &&
        system("gem install #{gemfile}")
    end
  end
end
