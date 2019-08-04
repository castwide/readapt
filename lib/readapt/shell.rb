require 'thor'

module Readapt
  class Shell < Thor
    desc 'server', 'Run a DAP server'
    def server
      Backport.run do
        debugger = Readapt::Debugger.new
        Thread.new do
          Readapt::Adapter.host debugger
          Backport.prepare_tcp_server host: '127.0.0.1', port: 1234, adapter: Readapt::Adapter
          STDERR.puts "Readapt Debugger is listening"
        end
      end
    end
  end
end
