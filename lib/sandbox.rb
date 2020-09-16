require "readline"
require "thread"
require "json"
require "base64"
    
require "context"
require "context-root"
require "context-query"
require "context-script"
require "context-net"
require "context-world"
require "context-chat"

module Sandbox
  class Shell
    attr_reader :logger
    attr_accessor :context, :reading

    def initialize(game)
      @game = game
      @context = "/"
      @contexts = {
        "/" => ContextRoot.new(@game, self),
        "/query" => ContextQuery.new(@game, self),
        "/net" => ContextNet.new(@game, self),
        "/world" => ContextWorld.new(@game, self),
        "/script" => ContextScript.new(@game, self),
        "/chat" => ContextChat.new(@game, self),
      }

      @logger = Logger.new(self)
      @logger.logPrefix = "\e[1;32m\u2714\e[22;32m "
      @logger.logSuffix = "\e[0m"
      @logger.errorPrefix = "\e[1;31m\u2718\e[22;31m "
      @logger.errorSuffix = "\e[0m"
      @logger.infoPrefix = "\e[1;37m\u2759\e[22;37m "
      @logger.infoSuffix = "\e[0m"

      Readline.completion_proc = Proc.new do |text|
        @contexts[@context].commands.keys.grep(/^#{Regexp.escape(text)}/)
      end
    end

    def puts(data = "")
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
        word.sub(/^['"]/, "").sub(/['"]$/, "")
      end
      @contexts[@context].exec(words)
    end
  end

  class Config < Hash
    attr_reader :file

    def initialize(file)
      @file = file
    end

    def load
      data = JSON.parse(File.read(@file))
      return unless data.class == Hash
      self.merge!(data)
    end

    def save
      File.write(@file, JSON.pretty_generate(self))
    end
  end

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
      @shell.puts(@logPrefix + message + @logSuffix)
    end

    def error(message)
      @shell.puts(@errorPrefix + message + @errorSuffix)
    end

    def info(message)
      @shell.puts(@infoPrefix + message + @infoSuffix)
    end
  end

  class Script
    def initialize(game, shell, logger, args)
      @game = game
      @shell = shell
      @logger = logger
      @args = args
    end

    def main
    end
  end
end
