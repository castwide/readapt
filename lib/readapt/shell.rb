require 'thor'

module Readapt
  class Shell < Thor
    desc 'server [FILE]', 'Run a DAP server'
    def serve
      Backport.run do
        Signal.trap("INT") do
          Backport.stop
        end
        Signal.trap("TERM") do
          Backport.stop
        end
        debugger = Readapt::Debugger.new
        Thread.new do
          Readapt::Adapter.host debugger
          Backport.prepare_tcp_server host: '127.0.0.1', port: 1234, adapter: Readapt::Adapter
          STDERR.puts "Readapt Debugger is listening PORT=1234"
        end
      end
    end
  end
end
