require 'thor'
require 'backport'
require 'open3'
require 'securerandom'
require 'socket'

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
        procid = SecureRandom.hex(8)
        Readapt::Error.procid = procid
        stdin, stdout, stderr = Open3.popen3('ruby', $0, 'target', procid)
        server = TCPServer.new(options[:host], options[:port])
        STDERR.puts "Readapt Debugger #{Readapt::VERSION} is listening HOST=#{options[:host]} PORT=#{options[:port]} PID=#{Process.pid}"
        connection = server.accept
        machine.prepare Backport::Server::Stdio.new(input: connection, output: stdin, adapter: Readapt::Input)
        machine.prepare Backport::Server::Stdio.new(input: stdout, output: connection, adapter: Readapt::Output)
        machine.prepare Backport::Server::Stdio.new(input: stderr, output: connection, adapter: Readapt::Error)
      end
    end

    desc 'stdio', 'Run a DAP process'
    def stdio
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
        procid = SecureRandom.hex(8)
        Readapt::Error.procid = procid
        stdin, stdout, stderr = Open3.popen3('ruby', $0, 'target', procid)
        STDERR.puts "Readapt Debugger #{Readapt::VERSION} is running"
        # machine.prepare Backport::Server::Stdio.new(input: STDIN, output: stdin, adapter: Readapt::Input)
        # machine.prepare Backport::Server::Stdio.new(input: stdout, output: STDOUT, adapter: Readapt::Output)
        machine.prepare Backport::Server::Stdio.new(input: STDIN, output: stdin, adapter: Readapt::Input)
        machine.prepare Backport::Server::Stdio.new(input: stdout, output: STDOUT, adapter: Readapt::Output)
        machine.prepare Backport::Server::Stdio.new(input: stderr, output: STDOUT, adapter: Readapt::Error)
      end
    end

    desc 'target [PROCID]', 'Run a target process'
    def target procid = nil
      STDOUT.sync = true
      STDERR.sync = true
      Readapt::Adapter.procid = procid
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
        machine.prepare Backport::Server::Stdio.new(input: STDIN, output: STDOUT, adapter: Readapt::Adapter)
      end
    end

    private

    def graceful_shutdown
      Backport.stop
      exit
    end
  end
end
