require 'backport'

require "readapt/version"
require 'readapt/location'
require 'readapt/breakpoint'
require 'readapt/breakpoints'
require 'readapt/frame'
require 'readapt/monitor'
require 'readapt/snapshot'
require 'readapt/debugger'
require 'readapt/inspector'
require 'readapt/message'
require 'readapt/variable'
require 'readapt/adapter'
require 'readapt/readapt'
require 'readapt/shell'

STDOUT.sync
STDERR.sync

module Readapt
  class Error < StandardError; end
  # Your code goes here...
end

Readapt.module_exec do
  if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    define_singleton_method :normalize_path do |path|
      path[0].upcase + path[1..-1].gsub('\\', '/')
    end
  else
    define_singleton_method :normalize_path do |path|
      path
    end
  end
end
