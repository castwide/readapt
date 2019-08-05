require 'thor'
require 'socket'

module Readapt
  class Shell < Thor
    map %w[--version -v] => :version

    desc "--version, -v", "Print the version"
    def version
      puts Readapt::VERSION
    end

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
        end
        stdout = TCPSocket.new '127.0.0.1', 1234
        stderr = TCPSocket.new '127.0.0.1', 1234
        STDERR.puts "Readapt Debugger is listening PORT=1234"
        STDOUT.reopen stdout
        STDERR.reopen stderr
      end
    end
  end
end
