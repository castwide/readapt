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

    desc 'socket', 'Run a DAP server over TCP'
    option :host, type: :string, aliases: :h, description: 'The server host', default: '127.0.0.1'
    option :port, type: :numeric, aliases: :p, description: 'The server port', default: 1234
    def socket
      machine = Backport::Machine.new
      machine.run do
        prepare_machine machine
        server = Backport::Server::Tcpip.new(host: options[:host], port: options[:port], adapter: Readapt::Server)
        machine.prepare server
        STDERR.puts "Readapt Debugger #{Readapt::VERSION} is listening HOST=#{options[:host]} PORT=#{options[:port]} PID=#{Process.pid}"
      end
    end
    map serve: :socket

    desc 'stdio', 'Run a DAP server over STDIO'
    def stdio
      machine = Backport::Machine.new
      machine.run do
        prepare_machine machine
        server = Backport::Server::Stdio.new(adapter: Readapt::Server)
        machine.prepare server
      end
    end

    desc 'target [PROCID]', 'Run a target process'
    def target procid = nil
      STDIN.binmode
      STDOUT.binmode
      STDERR.binmode
      STDOUT.sync = true
      STDERR.sync = true
      Readapt::Adapter.procid = procid
      machine = Backport::Machine.new
      Signal.trap("INT") do
        graceful_shutdown machine
      end
      Signal.trap("TERM") do
        graceful_shutdown machine
      end
      machine.run do
        debugger = Readapt::Debugger.new
        Readapt::Adapter.host debugger
        machine.prepare Backport::Server::Stdio.new(input: STDIN, output: STDERR, adapter: Readapt::Adapter)
      end
    end

    private

    # @param machine [Backport::Machine]
    # @return [void]
    def prepare_machine machine
      STDOUT.sync = true
      STDERR.sync = true
      Signal.trap("INT") do
        graceful_shutdown machine
      end
      Signal.trap("TERM") do
        graceful_shutdown machine
      end
      procid = SecureRandom.hex(8)
      Readapt::Error.procid = procid
      stdin, stdout, stderr, thr = Open3.popen3('ruby', $0, 'target', procid)
      stdin.sync = true
      stdout.sync = true
      stderr.sync = true
      stdin.binmode
      Readapt::Server.target_in = stdin
      Readapt::Server.target_pid = thr[:pid]
      output = Backport::Server::Stdio.new(input: stdout, output: stdin, adapter: Readapt::Output)
      error = Backport::Server::Stdio.new(input: stderr, output: stdin, adapter: Readapt::Error)
      machine.prepare output
      machine.prepare error
      at_exit do
        begin
          Process.kill 'KILL', thr[:pid]
        rescue Errno::ESRCH
          # Ignore
        end
      end
    end

    # @param machine [Backport::Machine]
    # @return [void]
    def graceful_shutdown machine
      machine.stop
      exit
    end
  end
end
