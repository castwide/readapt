module Readapt
  module Server
    # @return [Backport::Server::Stdio]
    attr_accessor :output

    attr_accessor :error

    def receiving data
      error.clients.each do |c|
        c.adapter.write data
      end
    end
  end
end
