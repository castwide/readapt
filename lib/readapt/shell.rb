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
        stdin.sync = true
        stdout.sync = true
        stderr.sync = true
        stdin.binmode
        Readapt::Server.target_in = stdin
        output = Backport::Server::Stdio.new(input: stdout, output: stdin, adapter: Readapt::Output)
        error = Backport::Server::Stdio.new(input: stderr, output: stdin, adapter: Readapt::Error)
        server = Backport::Server::Tcpip.new(host: options[:host], port: options[:port], adapter: Readapt::Server)
        machine.prepare output
        machine.prepare error
        machine.prepare server
        STDERR.puts "Readapt Debugger #{Readapt::VERSION} is listening HOST=#{options[:host]} PORT=#{options[:port]} PID=#{Process.pid}"
        STDERR.flush
      end
    end

    # desc 'stdio', 'Run a DAP process'
    # def stdio
    #   STDOUT.sync = true
    #   STDERR.sync = true
    #   machine = Backport::Machine.new
    #   machine.run do
    #     Signal.trap("INT") do
    #       graceful_shutdown
    #     end
    #     Signal.trap("TERM") do
    #       graceful_shutdown
    #     end
    #     procid = SecureRandom.hex(8)
    #     Readapt::Error.procid = procid
    #     stdin, stdout, stderr = Open3.popen3('ruby', $0, 'target', procid)
    #     STDERR.puts "Readapt Debugger #{Readapt::VERSION} is running"
    #     # machine.prepare Backport::Server::Stdio.new(input: STDIN, output: stdin, adapter: Readapt::Input)
    #     # machine.prepare Backport::Server::Stdio.new(input: stdout, output: STDOUT, adapter: Readapt::Output)
    #     machine.prepare Backport::Server::Stdio.new(input: STDIN, output: stdin, adapter: Readapt::Input)
    #     machine.prepare Backport::Server::Stdio.new(input: stdout, output: STDOUT, adapter: Readapt::Output)
    #     machine.prepare Backport::Server::Stdio.new(input: stderr, output: STDOUT, adapter: Readapt::Error)
    #   end
    # end

    desc 'target [PROCID]', 'Run a target process'
    def target procid = nil
      STDIN.binmode
      STDOUT.binmode
      STDERR.binmode
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
        machine.prepare Backport::Server::Stdio.new(input: STDIN, output: STDERR, adapter: Readapt::Adapter)
      end
    end

    private

    def graceful_shutdown
      Backport.stop
      exit
    end
  end
end
