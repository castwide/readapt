# frozen_string_literal: true

require 'readapt/message/base'
require 'readapt/message/initialize'
require 'readapt/message/launch'
require 'readapt/message/set_breakpoints'
require 'readapt/message/set_exception_breakpoints'
require 'readapt/message/configuration_done'
require 'readapt/message/threads'
require 'readapt/message/stack_trace'
require 'readapt/message/scopes'
require 'readapt/message/continue'
require 'readapt/message/variables'
require 'readapt/message/next'
require 'readapt/message/step_in'
require 'readapt/message/step_out'
require 'readapt/message/disconnect'

module Readapt
  module Message
    @@messages = {}
    @@seq = 0

    def self.register name, klass
      @@messages[name] = klass
    end

    def self.process arguments, inspector
      message = @@messages[arguments['command']].new(arguments['arguments'], inspector)
      message.run
      message
    rescue Exception => e
      STDERR.puts "Skipping error: #{e.message}"
      STDERR.puts "Received: #{arguments}"
      STDERR.puts e.backtrace
    end

    register 'initialize', Message::Initialize
    register 'launch', Message::Launch
    register 'setBreakpoints', Message::SetBreakpoints
    register 'setExceptionBreakpoints', Message::SetExceptionBreakpoints
    register 'configurationDone', Message::ConfigurationDone
    register 'threads', Message::Threads
    register 'stackTrace', Message::StackTrace
    register 'scopes', Message::Scopes
    register 'continue', Message::Continue
    register 'variables', Message::Variables
    register 'next', Message::Next
    register 'stepIn', Message::StepIn
    register 'stepOut', Message::StepOut
    register 'disconnect', Message::Disconnect
  end
end
