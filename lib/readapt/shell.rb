require 'thor'
require 'socket'
require 'stringio'
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
      machine = Backport::Machine.new
      machine.run do
        Signal.trap("INT") do
          Backport.stop
        end
        Signal.trap("TERM") do
          Backport.stop
        end
        debugger = Readapt::Debugger.new(machine)
        Readapt::Adapter.host debugger
        machine.prepare Backport::Server::Tcpip.new(host: options[:host], port: options[:port], adapter: Readapt::Adapter)
        STDERR.puts "Readapt Debugger #{Readapt::VERSION} is listening HOST=#{options[:host]} PORT=#{options[:port]} PID=#{Process.pid}"
        # Redirect STDOUT and STDERR through the adapter protocol
        # @todo This feature does not always work with STDERR, e.g, when
        #   running RSpec
        cats = ['stdout', 'stderr']
        [STDOUT, STDERR].each do |io|
          cat = cats.shift
          io.instance_eval do
            define_singleton_method :write do |*args, &block|
              debugger.output args.join, cat
            end
          end
        end
      end
    end
  end
end
