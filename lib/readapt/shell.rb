require 'thor'
require 'backport'

module Readapt
  class Shell < Thor
    map %w[--version -v] => :version

    desc "--version, -v", "Print the version"
    def version
      puts Readapt::VERSION
    end

    desc 'serve', 'Run a DAP server'
    option :host, type: :string, aliases: :h, description: 'The server host', default: '127.0.0.1'
    option :port, type: :numeric, aliases: :p, description: 'The server port', default: 1234
    def serve
      STDOUT.sync = true
      STDERR.sync = true
      machine = Backport::Machine.new
      machine.run do
        Signal.trap("INT") do
          graceful_shutdown
        end
        Signal.trap("TERM") do
          graceful_shutdown
        end
        debugger = Readapt::Debugger.new(machine)
        Readapt::Adapter.host debugger
        machine.prepare Backport::Server::Tcpip.new(host: options[:host], port: options[:port], adapter: Readapt::Adapter)
        STDERR.puts "Readapt Debugger #{Readapt::VERSION} is listening HOST=#{options[:host]} PORT=#{options[:port]} PID=#{Process.pid}"
      end
    end

    private

    def graceful_shutdown
      Backport.stop
      exit
    end
  end
end
