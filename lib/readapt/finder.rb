require 'pathname'

module Readapt
  module Finder
    module_function

    def find program
      return program if File.exist?(program)
      which(program) || raise(LoadError, "#{program} is not a valid Ruby file or program")
    end

    def which program
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exe = File.join(path, program)
        return exe if File.file?(exe)
      end
      nil
    end
  end
end
