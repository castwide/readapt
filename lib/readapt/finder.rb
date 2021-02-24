require 'pathname'

module Readapt
  # Methods to find a program in the current directory or one of the
  # environment paths.
  #
  module Finder
    module_function

    # Get the program's fully qualified path. Search first in the current
    # directory, then the environment paths.
    #
    # @raise [LoadError] if the program was not found
    #
    # @param program [String] The name of the program
    # @return [String] The fully qualified path
    def find program
      return program if File.exist?(program)
      which(program) || raise(LoadError, "#{program} is not a valid Ruby file or program")
    end

    # Search the environment paths for the given program.
    #
    # @param program [String] The name of the program
    # @return [String] The fully qualified path, or nil if it was not found
    def which program
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exe = File.join(path, program)
        return exe if File.file?(exe)
      end
      nil
    end
  end
end
