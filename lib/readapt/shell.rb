require 'thor'

module Readapt
  class Shell < Thor
    desc 'server [FILE]', 'Run a DAP server'
    def serve file = nil
      Backport.run do
        debugger = Readapt::Debugger.new
        debugger.file = file
        Thread.new do
          Readapt::Adapter.host debugger
          Backport.prepare_tcp_server host: '127.0.0.1', port: 1234, adapter: Readapt::Adapter
          STDERR.puts "Readapt Debugger is listening PORT=1234"
        end
      end
    end
  end
end
