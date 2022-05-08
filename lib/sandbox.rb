# frozen_string_literal: true

require 'readline'
require 'json'
require 'base64'

require 'context'
require 'context-root'
require 'context-query'
require 'context-script'
require 'context-net'
require 'context-prog'
require 'context-mission'
require 'context-world'
require 'context-chat'
require 'context-buy'

module Sandbox
  ##
  # Shell
  class Shell
    DATA_DIR = 'data'

    attr_reader :logger
    attr_accessor :context, :reading

    def initialize(game)
      @game = game
      @context = '/'
      @contexts = {
        '/' => ContextRoot.new(@game, self),
        '/query' => ContextQuery.new(@game, self),
        '/net' => ContextNet.new(@game, self),
        '/prog' => ContextProg.new(@game, self),
        '/mission' => ContextMission.new(@game, self),
        '/world' => ContextWorld.new(@game, self),
        '/script' => ContextScript.new(@game, self),
        '/chat' => ContextChat.new(@game, self),
        '/buy' => ContextBuy.new(@game, self)
      }

      @logger = Logger.new(self)
      @logger.logPrefix = '\e[1;32m\u2714\e[22;32m '
      @logger.logSuffix = '\e[0m'
      @logger.errorPrefix = '\e[1;31m\u2718\e[22;31m '
      @logger.errorSuffix = '\e[0m'
      @logger.infoPrefix = '\e[1;37m\u2759\e[22;37m '
      @logger.infoSuffix = '\e[0m'

      Readline.completion_proc = proc do |text|
        @contexts[@context].completion(text)
      end

      @game.countriesList = Config.new("#{DATA_DIR}/countries.conf")
      @game.countriesList.load
    end

    def puts(data = '')
      $stdout.puts("\e[0G\e[J#{data}")
      Readline.refresh_line if @reading
    end

    def readline
      loop do
        prompt = "#{@context} \e[1;35m\u25b8\e[0m "
        @reading = true
        line = Readline.readline(prompt, true)
        @reading = false
        exit if line.nil?
        line.strip!
        Readline::HISTORY.pop if line.empty?
        next if line.empty?

        exec(line)
      end
    end

    def exec(line)
      words = line.scan(/['"][^'"]*['"]|[^\s'"]+/)
      words.map! do |word|
        word.sub(/^['"]/, '').sub(/['"]$/, '')
      end
      @contexts[@context].exec(words)
    end
  end

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
