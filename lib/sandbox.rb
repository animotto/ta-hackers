module Sandbox
  class Shell
    require "readline"
    require "thread"
    require "json"
    require "base64"
    
    attr_accessor :context

    def initialize(game)
      @game = game
      @context = "/"
      @contexts = {
        "/" => ContextRoot.new(@game, self),
        "/query" => ContextQuery.new(@game, self),
        "/net" => ContextNet.new(@game, self),
        "/script" => ContextScript.new(@game, self),
        "/chat" => ContextChat.new(@game, self),
      }
    end

    def puts(data = "")
      $stdout.puts("\e[0G\e[J#{data}")
      Readline.refresh_line
    end

    def log(data, type = :info)
      case type
      when :error
        data = "\e[1;31m\u2718\e[22;31m #{data}\e[0m"
      when :success
        data = "\e[1;32m\u2714\e[22;32m #{data}\e[0m"
      when :data
        data = "\e[1;35m\u2731\e[22;35m #{data}\e[0m"
      when :script
        data = "\e[1;36m\u273f\e[22;36m #{data}\e[0m"
      when :chat
        data = "\e[1;33m\u2764\e[22;33m #{data}\e[0m"
      else
        data = "\e[1;37m\u2759\e[22;37m #{data}\e[0m"
      end

      puts data
    end
    
    def readline
      loop do
        prompt = "#{@context} \e[1;35m\u25b8\e[0m "
        line = Readline.readline(prompt, true)
        exit if line.nil?
        line.strip!
        Readline::HISTORY.pop if line.empty?
        next if line.empty?
        words = line.split(/\s+/)
        exec(words)
      end
    end
    
    def exec(words)
      @contexts[@context].exec(words)
    end
  end

  class ContextBase
    def initialize(game, shell)
      @game = game
      @shell = shell
      @commands = {
        ".." => "Return to previous context",
        "path" => "Current context path",
        "set [var] [val]" => "Set configuration variables",
        "unset <var>" => "Unset configuration variables",
        "quit" => "Quit",
      }
    end

    def help(commands)
      @shell.puts "Available commands:"
      commands.each do |k, v|
        @shell.puts " %-24s%s" % [k, v]
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

        @game.config[words[1].downcase] = words[2]
        return

      when "unset"
        if words[1].nil?
          @shell.puts "#{cmd}: Specify variable name"
          return
        end

        @game.config.delete(words[1])
        return
        
      else
        @shell.puts "Unrecognized command #{cmd}"
        return
          
      end
    end
  end

  class ContextRoot < ContextBase
    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "[query]" => "Analyze queries and data dumps",
                         "[net]" => "Network",
                         "[script]" => "Scripts",
                         "[chat]" => "Internal chat",
                         "connect" => "Connect to the server",
                         "trans" => "Language translations",
                         "settings" => "Application settings",
                       })
    end
    
    def exec(words)
      cmd = words[0].downcase
      case cmd

      when "query", "net", "script", "chat"
        @shell.context = "/#{cmd}"
        return

      when "trans"
        if @game.transLang.empty?
          @shell.puts "#{cmd}: No language translations"
          return
        end

        @shell.puts "Language translations:"
        @game.transLang.each do |k, v|
          @shell.puts " %-32s .. %s" % [k, v]
        end
        return
        
      when "settings"
        if @game.appSettings.empty?
          @shell.puts "#{cmd}: No application settings"
          return
        end

        @shell.puts "Application settings:"
        @game.appSettings.each do |k, v|
          @shell.puts " %-32s .. %s" % [k, v]
        end
        return

      when "connect"
        msg = "Language translations"
        if @game.transLang = @game.cmdTransLang
          @shell.log(msg, :success)
        else
          @shell.log(msg, :error)
          return
        end
 
        msg = "Application settings"
        if @game.appSettings = @game.cmdAppSettings
          @shell.log(msg, :success)
        else
          @shell.log(msg, :error)
          return
        end

        msg = "Authenticate"
        if auth = @game.cmdAuthIdPassword
          @shell.log(msg, :success)
        else
          @shell.log(msg, :error)
          return
        end

        @game.config["sid"] = auth["sid"]        
        return
        
      end
      
      super(words)
    end
  end

  class ContextQuery < ContextBase
    DUMPS_DIR = "dumps"

    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "qr <arg1> .. <argN>" => "Raw query",
                         "qc <arg1> .. <argN>" => "Hashed query",
                         "qs <arg1> .. <argN>" => "Session query",
                         "dumps" => "List dumps",
                         "show <id>" => "Show dump",
                         "del <id>" => "Delete dump",
                         "rename <id> <name>" => "Rename dump",
                         "note <id> <name>" => "Set a note for the dump",
                         "list" => "List dump files",
                         "export <file>" => "Export dumps to the file",
                         "import <file>" => "Import dumps from the file",
                         "rm <file>" => "Delete dump file",
                       })
      @dumps = Array.new
    end
    
    def exec(words)
      cmd = words[0].downcase
      case cmd
          
      when "qr", "qc", "qs"
        data = words[1..-1]
        data.each_index do |i|
          @game.config.each do |k, v|
            data[i].gsub!("%#{k}%".upcase, v.to_s)
          end
        end
        
        url = data.join("&")
        if cmd == "qs" && @game.config["sid"].nil?
          @shell.puts "#{cmd}: No session ID"
          return
        end

        response = @game.request(url, (cmd == "qc" || cmd == "qs"), (cmd == "qs"))
        query = @game.makeUrl(url, (cmd == "qc" || cmd == "qs"), (cmd == "qs"))
        msg = "Query: #{query}"
        unless response
          @shell.log(msg, :error)
          return
        end

        @shell.log(msg, :success)
        @shell.log(response, :data)
        @dumps.append({
                        "name" => "Dump#{@dumps.length}",
                        "note" => "",
                        "datetime" => Time.now.to_s,
                        "query" => query,
                        "data" => Base64.encode64(response),
                      })
        return

      when "dumps"
        if @dumps.empty?
          @shell.puts("#{cmd}: No dumps")
          return
        end

        @shell.puts("Dumps:")
        @dumps.each_index do |i|
          @shell.puts(
            "[%d] %s: %s" % [
              i, @dumps[i]["datetime"], @dumps[i]["name"]
            ]
          )
        end
        return

      when "show"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify dump ID")
          return
        end
        
        id = words[1].to_i
        if @dumps[id].nil?
          @shell.puts("#{cmd}: No such dump")
          return
        end

        @dumps[id].each do |k, v|
          if k == "data"
            val = Base64.decode64(v)
          else
            val = v
          end
          @shell.puts("\e[1;32m#{k.capitalize}: \e[22;36m#{val}\e[0m")
        end
        return

      when "del"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify dump ID")
          return
        end
        
        id = words[1].to_i
        if @dumps[id].nil?
          @shell.puts("#{cmd}: No such dump")
          return
        end

        @dumps.delete_at(id)
        return        

      when "rename"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify dump ID")
          return
        end
        
        id = words[1].to_i
        if @dumps[id].nil?
          @shell.puts("#{cmd}: No such dump")
          return
        end

        name = words[2..-1].join(" ")
        if name.nil? || name.empty?
          @shell.puts("#{cmd}: Specify dump name")
          return
        end

        @dumps[id]["name"] = name
        return

      when "note"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify dump ID")
          return
        end
        
        id = words[1].to_i
        if @dumps[id].nil?
          @shell.puts("#{cmd}: No such dump")
          return
        end

        note = words[2..-1].join(" ")
        if note.nil? || note.empty?
          @shell.puts("#{cmd}: Specify dump note")
          return
        end

        @dumps[id]["note"] = note
        return
        
      when "list"
        files = Array.new
        Dir.each_child("#{DUMPS_DIR}") do |child|
          next unless File.file?("#{DUMPS_DIR}/#{child}") && child =~ /\.dump$/
          child.sub!(".dump", "")
          files.append(child)
        end

        if files.empty?
          @shell.puts("#{cmd}: No dump files")
          return
        end

        @shell.puts("Dump files:")
        files.each do |file|
          @shell.puts(" #{file}")
        end
        return
        
      when "export"
        file = words[1]
        if file.nil?
          @shell.puts("#{cmd}: Specify file name")
          return
        end

        if @dumps.empty?
          @shell.puts("#{cmd}: No dumps")
          return
        end
        
        File.write("#{DUMPS_DIR}/#{file}.dump", JSON::generate(@dumps))
        return

      when "import"
        file = words[1]
        if file.nil?
          @shell.puts("#{cmd}: Specify file name")
          return
        end

        fname = "#{DUMPS_DIR}/#{file}.dump"
        unless File.exists?(fname)
          @shell.puts("#{cmd}: No such file")
          return
        end

        dump = File.read(fname)
        begin
          @dumps = JSON::parse(dump)
        rescue JSON::ParserError => e
          @shell.puts("#{cmd}: Invalid dump format")
          @shell.puts
          @shell.puts(e)
        end
        return

      when "rm"
        file = words[1]
        if file.nil?
          @shell.puts("#{cmd}: Specify file name")
          return
        end

        fname = "#{DUMPS_DIR}/#{file}.dump"
        unless File.exists?(fname)
          @shell.puts("#{cmd}: No such file")
          return
        end

        File.delete(fname)
        return
        
      end
      
      super(words)
    end
  end

  class ContextNet < ContextBase
    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "profile" => "Show profile",
                         "readme" => "Show readme",
                         "node" => "Show nodes",
                         "collect <id>" => "Collect node resources",
                         "prog" => "Show programs",
                         "log" => "Show logs",
                       })
    end

    def exec(words)
      cmd = words[0].downcase

      case cmd

      when "profile", "readme", "node", "prog", "log"
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Network maintenance"
        if net = @game.cmdNetGetForMaint
          @shell.log(msg, :success)
        else
          @shell.log(msg, :error)
          return
        end

        case cmd

        when "profile"
          @shell.puts("\e[1;35m\u2022 Profile\e[0m")
          net["profile"].each do |k, v|
            @shell.puts("  %s: %s" % [k.capitalize, v])
          end
          return

        when "readme"
          @shell.puts("\e[1;35m\u2022 Readme\e[0m")
          @shell.puts("  #{net["readme"]}")
          return

        when "node"
          @shell.puts("\e[1;35m\u2022 Nodes\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-4s %-5s %-12s %-12s\e[0m" % [
              "ID",
              "Type",
              "Level",
              "Time",
              "Name",
            ]
          )

          net["nodes"].each do |k, v|
            name = Trickster::Hackers::NODES_TYPES[v["type"]]
            name = "UNKNOWN" if name.nil?
            @shell.puts(
              "  %-12d %-4d %-5d %-12d %-12s" % [
                k,
                v["type"],
                v["level"],
                v["time"],
                name,
              ]
            )
          end
          return

        when "prog"
          @shell.puts("\e[1;35m\u2022 Programs\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-4s %-6s %-5s %-12s\e[0m" % [
              "ID",
              "Type",
              "Amount",
              "Level",
              "Name",
            ]
          )
          net["programs"].each do |k, v|
            name = Trickster::Hackers::PROGRAMS_TYPES[v["type"]]
            name = "UNKNOWN" if name.nil?
            @shell.puts(
              "  %-12d %-4d %-6d %-5d %-12s" % [
                k,
                v["type"],
                v["amount"],
                v["level"],
                name,
              ]
            )
          end
          return

        when "log"
          @shell.puts("\e[1;35m\u2022 Security log\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-19s %-12s %s\e[0m" % [
              "ID",
              "Date",
              "Attacker",
              "Name",
            ]
          )
          logsSecurity = net["logs"].select do |k, v|
            v["target"] == @game.config["id"]
          end
          logsSecurity = logsSecurity.to_a.reverse.to_h
          logsSecurity.each do |k, v|
            @shell.puts(
              "  %-12s %-19s %-12s %s" % [
                k,
                v["date"],
                v["id"],
                v["idName"],
              ]
            )
          end          

          @shell.puts
          @shell.puts("\e[1;35m\u2022 Hacks\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-19s %-12s %s\e[0m" % [
              "ID",
              "Date",
              "Target",
              "Name",
            ]
          )
          logsHacks = net["logs"].select do |k, v|
            v["id"] == @game.config["id"]
          end
          logsHacks = logsHacks.to_a.reverse.to_h
          logsHacks.each do |k, v|
            @shell.puts(
              "  %-12s %-19s %-12s %s" % [
                k,
                v["date"],
                v["target"],
                v["targetName"],
              ]
            )
          end
          return
          
        end
        return

      when "collect"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i
        
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Collect"
        if @game.cmdCollect(id)
          @shell.log(msg, :success)
        else
          @shell.log(msg, :error)
        end
        return
        
      end
      
      super(words)
    end
  end
  
  class ContextScript < ContextBase
    SCRIPTS_DIR = "scripts"

    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "run <name>" => "Run the script",
                         "list" => "List scripts",
                         "jobs" => "List active scripts",
                         "kill <id>" => "Kill the script",
                       })
      @jobs = Hash.new
      @jobCounter = 0;
    end

    def exec(words)
      cmd = words[0].downcase
      case cmd

      when "run"
        script = words[1]
        if script.nil?
          @shell.puts("#{cmd}: Specify script name")
          return
        end

        fname = "#{SCRIPTS_DIR}/#{script}.rb"
        unless File.exists?(fname)
          @shell.puts("#{cmd}: No such script")
          return
        end

        Thread.new {run(script, words[2..-1])}
        return

      when "list"
        scripts = Array.new
        Dir.each_child(SCRIPTS_DIR) do |child|
          next unless File.file?("#{SCRIPTS_DIR}/#{child}") && child =~ /\.rb$/
          child.sub!(".rb", "")
          scripts.append(child)
        end

        if scripts.empty?
          @shell.puts("#{cmd}: No scripts")
          return
        end

        @shell.puts("Scripts:")
        scripts.each do |script|
          @shell.puts(" #{script}")
        end
        return

      when "jobs"
        if @jobs.empty?
          @shell.puts("#{cmd}: No active jobs")
          return
        end

        @shell.puts("Active jobs:")
        @jobs.each do |k, v|
          @shell.puts(" [%d] %s" % [k, @jobs[k][0]])
        end
        return

      when "kill"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify job ID")
          return
        end

        job = words[1].to_i
        unless @jobs.key?(job)
          @shell.puts("#{cmd}: No such job")
          return
        end

        @shell.log("Killed: #{@jobs[job][0]}", :script)
        @jobs[job][1].kill
        Object.send(:remove_const, @jobs[job][0].capitalize)
        @jobs.delete(job)
        return
        
      end
            
      super(words)
    end

    def run(script, args)
      @jobId = @jobCounter += 1
      @jobs[@jobCounter] = [
                     script,
                     Thread.current,
                   ]
      fname = "#{SCRIPTS_DIR}/#{script}.rb"
      @shell.log("Run: #{script}", :script)
      begin
        load "#{fname}"
        eval("#{script.capitalize}.new(@game, @shell, args).main")
        @shell.log("Done: #{script}", :script)
      rescue => e
        @shell.log("Error: #{script} (#{e})", :script)
      end
      Object.send(:remove_const, script.capitalize)
      @jobs.delete(@jobId)
    end
  end
  
  class ContextChat < ContextBase
    def initialize(game, shell)
      @rooms = Hash.new
      super(game, shell)
      @commands.merge!({
                         "open <room>" => "Open room",
                         "close <room>" => "Close room",
                         "list" => "List opened rooms",
                         "say <room> <text>" => "Say to the room",
                         "talk <room>" => "Talk in the room"
                       })
      @mutex = Mutex.new
    end

    def exec(words)
      cmd = words[0].downcase
      case cmd

      when "open"
        if @game.config["sid"].nil? || @game.appSettings.empty?
          @shell.puts "#{cmd}: Not connected"
          return
        end

        if words[1].nil?
          @shell.puts "#{cmd}: Specify room ID"
          return
        end

        room = words[1].to_i
        if @rooms.key?(room)
          @shell.puts("#{cmd}: Room #{room} already opened")
          return
        end
        
        @rooms[room] = [
          Thread.new {chat(room)},
          String.new,
        ]
        return

      when "list"
        if @rooms.empty?
          @shell.puts "#{cmd}: No opened rooms"
          return
        end
        
        @shell.puts "Opened rooms:"
        @rooms.each_key do |k|
          @shell.puts " \e[1;33m\u2022\e[0m %d" % k
        end
        return
        
      when "close"
        if words[1].nil?
          @shell.puts "#{cmd}: Specify room ID"
          return
        end

        room = words[1].to_i
        unless @rooms.key?(room)
          @shell.puts "#{cmd}: No such opened room"
          return
        end

        @rooms[room][0].kill
        @rooms.delete(room)
        return

      when "say"
        if words[1].nil?
          @shell.puts "#{cmd}: Specify room ID"
          return
        end

        room = words[1].to_i
        if words[2].nil?
          @shell.puts "#{cmd}: Specify message"
          return
        end

        unless @rooms.key?(room)
          @shell.puts("#{cmd}: No such opened room")
          return
        end

        response = nil
        @mutex.synchronize do
          response = @game.cmdChatSend(
            room,
            words[2..-1].join(" "),
            @rooms[room][1],
          )
          unless response
            @shell.log("Chat send", :error)
            return
          end

          logMessages(room, response)
        end
        return

      when "talk"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify room ID")
          return
        end

        room = words[1].to_i
        unless @rooms.key?(room)
          @shell.puts("#{cmd}: No such opened room")
          return
        end

        @shell.puts("Enter ! to quit")
        loop do
          message = Readline.readline("#{room} \e[1;33m\u2765\e[0m ", true)
          break if message.nil?
          message.strip!
          Readline::HISTORY.pop if message.empty?
          next if message.empty?
          break if message == "!"
          response = nil
          @mutex.synchronize do
            response = @game.cmdChatSend(
              room,
              message,
              @rooms[room][1],
            )
            unless response
              @shell.log("Chat send", :error)
              next
            end

            logMessages(room, response)
          end
        end
        return
        
      end

      super(words)
    end

    def logMessages(room, messages)
      messages.each do |message|
        @shell.log(
          "(%d) %s: %s" % [
            room,
            message["nick"],
            message["message"],
          ],
          :chat,
        )
        @rooms[room][1] = message["datetime"]
      end
    end
    
    def chat(room)
      loop do
        response = nil
        @mutex.synchronize do
          messages = @game.cmdChatDisplay(room, @rooms[room][1])
          if messages
            logMessages(room, messages)
          else
            @shell.log("Chat display (#{room.to_s})", :error)
          end
        end

        sleep(@game.appSettings["chat_refresh_interval"].to_i)
      end
    rescue
      @shell.log("Chat room #{room} terminated", :error)
      @rooms.delete(room)
    end
  end

  class Script
    def initialize(game, shell, args)
      @game = game
      @shell = shell
      @args = args
    end

    def main
    end
  end
end
