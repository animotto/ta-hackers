# frozen_string_literal: true

require 'json'

module Sandbox
  ##
  # Config
  class Config < Hash
    attr_accessor :file

    def initialize(file)
      super
      @file = file
    end

    def load
      data = JSON.parse(File.read(@file))
      return unless data.instance_of?(Hash)

      merge!(data)
    end

    def save
      File.write(@file, JSON.pretty_generate(self))
    end
  end

  ##
  # Logger
  class Logger
    attr_accessor :logPrefix, :errorPrefix, :infoPrefix,
                  :logSuffix, :errorSuffix, :infoSuffix

    def initialize(shell)
      @shell = shell
      @logPrefix = String.new
      @logSuffix = String.new
      @errorPrefix = String.new
      @errorSuffix = String.new
      @infoPrefix = String.new
      @infoSuffix = String.new
    end

    def log(message)
      @shell.puts(@logPrefix + message.to_s + @logSuffix)
    end

    def error(message)
      @shell.puts(@errorPrefix + message.to_s + @errorSuffix)
    end

    def info(message)
      @shell.puts(@infoPrefix + message.to_s + @infoSuffix)
    end
  end

  ##
  # Parent class for scripts
  class Script
    ##
    # Creates new script:
    #   game    = Game
    #   shell   = Shell
    #   logger  = Logger
    #   args    = Arguments
    def initialize(game, shell, logger, args)
      @game = game
      @shell = shell
      @logger = logger
      @args = args
    end

    ##
    # Script entry point
    def main; end

    ##
    # Executes after the script finished
    def finish; end
  end
end
