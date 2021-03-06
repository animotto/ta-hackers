module Sandbox
  class ContextBase
    attr_reader :commands

    def initialize(game, shell)
      @game = game
      @shell = shell
      @commands = {
        ".."      => ["..", "Return to previous context"],
        "path"    => ["path", "Current context path"],
        "echo"    => ["echo <var>", "Print configuration variables"],
        "set"     => ["set [var] [val]", "Set configuration variables"],
        "unset"   => ["unset <var>", "Unset configuration variables"],
        "save"    => ["save", "Save configuration"],
        "quit"    => ["quit", "Quit"],
      }
    end

    def completion(text)
      case Readline.line_buffer.lstrip
        when /^(echo|set|unset)\s+/
          return @game.config.keys.grep(/^#{Regexp.escape(text)}/)
      end
      @commands.keys.grep(/^#{Regexp.escape(text)}/)
    end

    def help(commands)
      @shell.puts "Available commands:"
      commands.each do |k, v|
        @shell.puts " %-28s%s" % [v[0], v[1]]
      end
    end
    
    def exec(words)
      cmd = words[0].downcase
      case cmd

      when "?"
        help(@commands)
        return
          
      when ".."
        return if @shell.context == "/"
        @shell.context.sub!(/\/\w+$/, "")
        @shell.context = "/" if @shell.context.empty?
        return

      when "path"
        @shell.puts "Current path #{@shell.context}"
        return
          
      when "quit"
        exit

      when "echo"
        if words[1].nil?
          @shell.puts "#{cmd}: Specify variable name"
          return
        end

        unless @game.config.key?(words[1])
          @shell.puts "No such variable"
          return
        end

        @shell.puts @game.config[words[1]]
        return

      when "set"
        if words[1].nil?
          @shell.puts "Configuration:"
          @game.config.each do |k, v|
            @shell.puts " %-16s .. %s" % [k, v]
          end
          return
        end

        if words[2].nil?
          @shell.puts "#{cmd}: Specify variable value"
          return
        end

        @game.config[words[1]] = words[2]
        return

      when "unset"
        if words[1].nil?
          @shell.puts "#{cmd}: Specify variable name"
          return
        end

        unless @game.config.key?(words[1])
          @shell.puts "No such variable"
          return
        end

        @game.config.delete(words[1])
        return

      when "save"
        begin
          @game.config.save
        rescue => e
          @shell.puts "#{cmd}: Can't save configuration (#{e})"
        end
        
      else
        @shell.puts "Unrecognized command #{cmd}"
        return
          
      end
    end
  end
end

