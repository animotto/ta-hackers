module Sandbox
  class Shell
    require "readline"
    require "thread"
    require "json"
    require "base64"
    
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

      Readline.completion_proc = Proc.new do |text|
        @contexts[@context].commands.keys.grep(/^#{Regexp.escape(text)}/)
      end
    end

    def puts(data = "")
      $stdout.puts("\e[0G\e[J#{data}")
      Readline.refresh_line if @reading
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

  class ContextBase
    attr_reader :commands

    def initialize(game, shell)
      @game = game
      @shell = shell
      @commands = {
        ".." => ["..", "Return to previous context"],
        "path" => ["path", "Current context path"],
        "set" => ["set [var] [val]", "Set configuration variables"],
        "unset" => ["unset <var>", "Unset configuration variables"],
        "quit" => ["quit", "Quit"],
      }
    end

    def help(commands)
      @shell.puts "Available commands:"
      commands.each do |k, v|
        @shell.puts " %-24s%s" % [v[0], v[1]]
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
                         "query" => ["[query]", "Analyze queries and data dumps"],
                         "net" => ["[net]", "Network"],
                         "world" => ["[world]", "World"],
                         "script" => ["[script]", "Scripts"],
                         "chat" => ["[chat]", "Internal chat"],
                         "connect" => ["connect", "Connect to the server"],
                         "trans" => ["trans", "Language translations"],
                         "settings" => ["settings", "Application settings"],
                         "nodes" => ["nodes", "Node types"],
                         "progs" => ["progs", "Program types"],
                         "missions" => ["missions", "Missions list"],
                         "skins" => ["skins", "Skin types"],
                         "news" => ["news", "News"],
                         "hints" => ["hints", "Hints list"],
                         "experience" => ["experience", "Experience list"],
                         "builders" => ["builders", "Builders list"],
                         "goals" => ["goals", "Goals types"],
                         "shields" => ["shields", "Shield types"],
                         "ranks" => ["ranks", "Rank list"],
                         "new" => ["new", "Create new account"],
                         "rename" => ["rename <name>", "Set new name"],
                         "info" => ["info <id>", "Get player info"],
                         "detail" => ["detail <id>", "Get detail player network"],
                         "hq" => ["hq <x> <y> <country>", "Set player HQ"],
                         "skin" => ["skin <skin>", "Set player skin"],
                         "top" => ["top <country>", "Show top ranking"],
                         "cpgen" => ["cpgen", "Cp generate code"],
                         "cpuse" => ["cpuse <code>", "Cp use code"],
                       })
    end
    
    def exec(words)
      cmd = words[0].downcase
      case cmd

      when "query", "net", "world", "script", "chat"
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

      when "nodes"
        if @game.nodeTypes.empty?
          @shell.puts "#{cmd}: No node types"
          return
        end

        @shell.puts "Node types:"
        @game.nodeTypes.each do |k, v|
          @shell.puts " %-2s .. %s" % [k, v["name"]]
        end
        return

      when "progs"
        if @game.programTypes.empty?
          @shell.puts "#{cmd}: No program types"
          return
        end

        @shell.puts "Program types:"
        @game.programTypes.each do |k, v|
          @shell.puts " %-2s .. %s" % [k, v["name"]]
        end
        return

      when "missions"
        if @game.missionsList.empty?
          @shell.puts "#{cmd}: No missions list"
          return
        end

        @shell.puts "Missions list:"
        @game.missionsList.each do |k, v|
          @shell.puts " %-7s .. %s, %s, %s" % [
                        k,
                        v["name"],
                        v["target"],
                        v["goal"],
                      ]
        end
        return

      when "skins"
        if @game.skinTypes.empty?
          @shell.puts "#{cmd}: No skin types"
          return
        end

        @shell.puts "Skin types:"
        @game.skinTypes.each do |k, v|
          @shell.puts " %-7d .. %s, %d, %d" % [
                        k,
                        v["name"],
                        v["price"],
                        v["rank"],
                      ]
        end
        return

      when "news"
        msg = "News"
        begin
          news = @game.cmdNewsGetList
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        news.each do |k, v|
          @shell.puts "\e[34m%s \e[33m%s\e[0m" % [
                        v["date"],
                        v["title"],
                      ]
          @shell.puts "\e[35m%s\e[0m" % [
                        v["body"],
                      ]
          @shell.puts
        end
        return

      when "hints"
        if @game.hintsList.empty?
          @shell.puts "#{cmd}: No hints list"
          return
        end

        @game.hintsList.each do |k, v|
          @shell.puts " %-7d .. %s" % [
                        k,
                        v["description"],
                      ]
        end
        return

      when "experience"
        if @game.experienceList.empty?
          @shell.puts "#{cmd}: No experience list"
          return
        end

        @game.experienceList.each do |k, v|
          @shell.puts " %-7d .. %s" % [
                        k,
                        v["experience"],
                      ]
        end
        return

      when "builders"
        if @game.buildersList.empty?
          @shell.puts "#{cmd}: No builders list"
          return
        end

        @game.buildersList.each do |k, v|
          @shell.puts " %-7d .. %s" % [
                        k,
                        v["price"],
                      ]
        end
        return

      when "goals"
        if @game.goalsTypes.empty?
          @shell.puts "#{cmd}: No goals types"
          return
        end

        @game.goalsTypes.each do |k, v|
          @shell.puts " %-20s .. %d, %s, %s" % [
                        k,
                        v["amount"],
                        v["name"],
                        v["description"],
                      ]
        end
        return

      when "shields"
        if @game.shieldTypes.empty?
          @shell.puts "#{cmd}: No shield types"
          return
        end

        @game.shieldTypes.each do |k, v|
          @shell.puts " %-7d .. %d, %s, %s" % [
                        k,
                        v["price"],
                        v["name"],
                        v["description"],
                      ]
        end
        return

      when "ranks"
        if @game.rankList.empty?
          @shell.puts "#{cmd}: No rank list"
          return
        end

        @game.rankList.each do |k, v|
          @shell.puts " %-7d .. %d" % [
                        k,
                        v["rank"],
                      ]
        end
        return

      when "connect"
        msg = "Language translations"
        begin
          @game.transLang = @game.cmdTransLang
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
 
        msg = "Application settings"
        begin
          @game.appSettings = @game.cmdAppSettings
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        msg = "Node types and levels"
        begin
          @game.nodeTypes = @game.cmdGetNodeTypes
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        msg = "Program types and levels"
        begin
          @game.programTypes = @game.cmdGetProgramTypes
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        msg = "Missions list"
        begin
          @game.missionsList = @game.cmdGetMissionsList
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        msg = "Skin types"
        begin
          @game.skinTypes = @game.cmdSkinTypesGetList
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        
        msg = "Hints list"
        begin
          @game.hintsList = @game.cmdHintsGetList
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        msg = "Experience list"
        begin
          @game.experienceList = @game.cmdGetExperienceList
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        msg = "Builders list"
        begin
          @game.buildersList = @game.cmdBuildersCountGetList
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        msg = "Goals types"
        begin
          @game.goalsTypes = @game.cmdGoalTypesGetList
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        msg = "Shield types"
        begin
          @game.shieldTypes = @game.cmdShieldTypesGetList
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        
        msg = "Rank list"
        begin
          @game.rankList = @game.cmdRankGetList
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        msg = "Authenticate"
        begin
          auth = @game.cmdAuthIdPassword
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        @game.config["sid"] = auth["sid"]        
        return

      when "new"
        msg = "Player create"
        begin
          player = @game.cmdPlayerCreate
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        @shell.puts("\e[1;35m\u2022 New account\e[0m")
        @shell.puts("  ID: #{player["id"]}")
        @shell.puts("  Password: #{player["password"]}")
        @shell.puts("  Session ID: #{player["sid"]}")
        return

      when "rename"
        name = words[1]
        if name.nil?
          @shell.puts("#{cmd}: Specify name")
          return
        end

        msg = "Player set name"
        begin
          @game.cmdPlayerSetName(@game.config["id"], name)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return

      when "info"
        id = words[1]
        if id.nil?
          @shell.puts("#{cmd}: Specify ID")
          return
        end

        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end
        
        msg = "Player get info"
        begin
          info = @game.cmdPlayerGetInfo(id)
          info["level"] = @game.getLevelByExp(info["experience"])
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        @shell.puts("\e[1;35m\u2022 Player info\e[0m")
        info.each do |k, v|
          @shell.puts("  %s: %s" % [k.capitalize, v])
        end
        return

      when "detail"
        id = words[1]
        if id.nil?
          @shell.puts("#{cmd}: Specify ID")
          return
        end

        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end
        
        msg = "Get net details world"
        begin
          detail = @game.cmdGetNetDetailsWorld(id)
          detail["profile"]["level"] = @game.getLevelByExp(detail["profile"]["experience"])
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        @shell.puts("\e[1;35m\u2022 Detail player network\e[0m")
        detail["profile"].each do |k, v|
          @shell.puts("  %s: %s" % [k.capitalize, v])
        end
        @shell.puts
        @shell.puts(
          "  \e[35m%-12s %-4s %-5s %-12s %-12s\e[0m" % [
            "ID",
            "Type",
            "Level",
            "Time",
            "Name",
          ]
        )
        detail["nodes"].each do |k, v|
          @shell.puts(
            "  %-12d %-4d %-5d %-12d %-12s" % [
              k,
              v["type"],
              v["level"],
              v["time"],
              @game.nodeTypes[v["type"]]["name"],
            ]
          )
        end
        return

      when "hq"
        x = words[1]
        y = words[2]
        country = words[3]
        if x.nil? || y.nil? || country.nil?
          @shell.puts("#{cmd}: Specify x, y, country")
          return
        end

        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end
        
        msg = "Set player HQ"
        begin
          @game.cmdSetPlayerHqCountry(@game.config["id"], x, y, country)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return

      when "skin"
        skin = words[1]
        if skin.nil?
          @shell.puts("#{cmd}: Specify skin")
          return
        end

        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end
        
        msg = "Player set skin"
        begin
          response = @game.cmdPlayerSetSkin(skin)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return

      when "top"
        country = words[1]
        if country.nil?
          @shell.puts("#{cmd}: Specify country")
          return
        end

        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end
        
        msg = "Ranking get all"
        begin
          top = @game.cmdRankingGetAll(country)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        types = {
          "nearby" => "Players nearby",
          "country" => "Top country players",
          "world" => "Top world players",
        }

        types.each do |type, title|
          @shell.puts("\e[1;35m\u2022 #{title}\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-25s %-12s %-7s %-12s\e[0m" % [
              "ID",
              "Name",
              "Experience",
              "Country",
              "Rank",
            ]
          )
          top[type].each do |player|
            @shell.puts(
              "  %-12s %-25s %-12s %-7s %-12s" % [
                player["id"],
                player["name"],
                player["experience"],
                player["country"],
                player["rank"],
              ]
            )
          end
          @shell.puts()
        end

        @shell.puts("\e[1;35m\u2022 Top countries\e[0m")
        @shell.puts(
          "  \e[35m%-7s %-12s\e[0m" % [
            "Country",
            "Rank",
          ]
        )
        top["countries"].each do |player|
          @shell.puts(
            "  %-7s %-12s" % [
              player["country"],
              player["rank"],
            ]
          )
        end
        return

      when "cpgen"
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end
        
        msg = "Cp generate code"
        begin
          code = @game.cmdCpGenerateCode(@game.config["id"], @game.config["platform"])
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        @shell.puts("\e[1;35m\u2022 Generated code\e[0m")
        @shell.puts("  Code: #{code}")
        return

      when "cpuse"
        code = words[1]
        if code.nil?
          @shell.puts("#{cmd}: Specify code")
          return
        end

        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end
        
        msg = "Cp use code"
        begin
          data = @game.cmdCpUseCode(@game.config["id"], code, @game.config["platform"])
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        @shell.puts("\e[1;35m\u2022 Account credentials\e[0m")
        @shell.puts("  ID: #{data["id"]}")
        @shell.puts("  Password: #{data["password"]}")
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
                         "qr" => ["qr <arg1> .. <argN>", "Raw query"],
                         "qc" => ["qc <arg1> .. <argN>", "Hashed query"],
                         "qs" => ["qs <arg1> .. <argN>", "Session query"],
                         "dumps" => ["dumps", "List dumps"],
                         "show" => ["show <id>", "Show dump"],
                         "del" => ["del <id>", "Delete dump"],
                         "rename" => ["rename <id> <name>", "Rename dump"],
                         "note" => ["note <id> <name>", "Set a note for the dump"],
                         "list" => ["list", "List dump files"],
                         "export" => ["export <file>", "Export dumps to the file"],
                         "import" => ["import <file>", "Import dumps from the file"],
                         "rm" => ["rm <file>", "Delete dump file"],
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

        query = @game.makeUrl(url, (cmd == "qc" || cmd == "qs"), (cmd == "qs"))
        msg = "Query: #{query}"
        begin
          response = @game.request(url, (cmd == "qc" || cmd == "qs"), (cmd == "qs"))
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
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
        Dir.children("#{DUMPS_DIR}").sort.each do |child|
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
                         "profile" => ["profile", "Show profile"],
                         "readme" => ["readme", "Show readme"],
                         "node" => ["node", "Show nodes"],
                         "create" => ["create <type>", "Create node"],
                         "delete" => ["delete <id>", "Delete node"],
                         "upgrade" => ["upgrade <id>", "Upgrade node"],
                         "finish" => ["finish <id>", "Finish node"],
                         "builders" => ["builders <id> <builders>", "Set node builders"],
                         "collect" => ["collect <id>", "Collect node resources"],
                         "prog" => ["prog", "Show programs"],
                         "log" => ["log", "Show logs"],
                         "net" => ["net", "Show network structure"],
                         "missions" => ["missions", "Show missions log"],
                       })
    end

    def exec(words)
      cmd = words[0].downcase

      case cmd

      when "profile", "readme", "node", "prog", "log", "net"
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Network maintenance"
        begin
          net = @game.cmdNetGetForMaint
          net["profile"]["level"] = @game.getLevelByExp(net["profile"]["experience"])
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        case cmd

        when "profile"
          @shell.puts("\e[1;35m\u2022 Profile\e[0m")
          net["profile"].each do |k, v|
            @shell.puts("  %s: %s" % [k.capitalize, v])
          end
          return

        when "readme"
          @shell.puts("\e[1;35m\u2022 Readme\e[0m")
          net["readme"].each do |item|
            @shell.puts("  #{item}")
          end
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
            @shell.puts(
              "  %-12d %-4d %-5d %-12d %-12s" % [
                k,
                v["type"],
                v["level"],
                v["time"],
                @game.nodeTypes[v["type"]]["name"],
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
            @shell.puts(
              "  %-12d %-4d %-6d %-5d %-12s" % [
                k,
                v["type"],
                v["amount"],
                v["level"],
                @game.programTypes[v["type"]]["name"],
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

        when "net"
          @shell.puts("\e[1;35m\u2022 Network structure\e[0m")
          @shell.puts(
            "  \e[35m%-5s %-12s %-4s %-4s %-4s %s\e[0m" % [
              "Index",
              "ID",
              "X",
              "Y",
              "Z",
              "Relations",
            ]
          )
          net["net"].each_index do |i|
            @shell.puts(
              "  %-5d %-12d %-+4d %-+4d %-+4d %s" % [
                i,
                net["net"][i]["id"],
                net["net"][i]["x"],
                net["net"][i]["y"],
                net["net"][i]["z"],
                net["net"][i]["rels"],
              ]
            )
          end
          return
          
        end
        return

      when "create"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node type")
          return
        end
        type = words[1].to_i
        
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Create node"
        begin
          net = @game.cmdNetGetForMaint
          @game.cmdCreateNodeUpdateNet(type, net["net"])
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return

      when "delete"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i
        
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Delete node"
        begin
          net = @game.cmdNetGetForMaint
          @game.cmdDeleteNodeUpdateNet(id, net["net"])
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return

      when "upgrade"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i
        
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Upgrade node"
        begin
          @game.cmdUpgradeNode(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return

      when "finish"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i
        
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Finish node"
        begin
          @game.cmdFinishNode(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return

      when "builders"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i

        if words[2].nil?
          @shell.puts("#{cmd}: Specify number of builders")
          return
        end
        builders = words[2].to_i
        
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Node set builders"
        begin
          @game.cmdNodeSetBuilders(id, builders)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
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

        msg = "Collect node"
        begin
          @game.cmdCollectNode(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return

      when "missions"
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Player missions get log"
        begin
          missions = @game.cmdPlayerMissionsGetLog
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        @shell.puts("\e[1;35m\u2022 Missions log\e[0m")
        @shell.puts(
          "  \e[35m%-7s %-7s %-7s %-20s\e[0m" % [
            "ID",
            "Money",
            "Bitcoin",
            "Date",
          ]
        )
        missions.each do |k, v|
          @shell.puts(
            "  %-7d %-7d %-7d %-20s" % [
              k,
              v["money"],
              v["bitcoin"],
              v["date"],
            ]
          )
          end
        return

      end
      
      super(words)
    end
  end

  class ContextWorld < ContextBase
    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "target" => ["target", "Show targets"],
                         "new" => ["new", "Get new targets"],
                         "bonus" => ["bonus", "Show bonuses"],
                         "collect" => ["collect <id>", "Collect bonus"],
                         "goal" => ["goal", "Show goals"],
                         "update" => ["update <id> <record>", "Update goal"],
                         "reject" => ["reject <id>", "Reject goal"],
                       })
    end

    def exec(words)
      cmd = words[0].downcase
      case cmd

      when "target", "bonus", "goal"
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Network maintenance"
        begin
          net = @game.cmdNetGetForMaint
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        
        msg = "World"
        begin
          world = @game.cmdPlayerWorld(net["profile"]["country"])
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)

        case cmd

        when "target"        
          @shell.puts("\e[1;35m\u2022 Targets\e[0m")
          @shell.puts(
            "  \e[35m%-12s %s\e[0m" % [
              "ID",
              "Name",
            ]
          )
          world["targets"].each do |k, v|
            @shell.puts(
              "  %-12d %s" % [
                k,
                v["name"],
              ]
            )
          end
          return

        when "bonus"        
          @shell.puts("\e[1;35m\u2022 Bonuses\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-2s\e[0m" % [
              "ID",
              "Amount",
            ]
          )
          world["bonuses"].each do |k, v|
            @shell.puts(
              "  %-12d %-2d" % [
                k,
                v["amount"],
              ]
            )
          end
          return

        when "goal"        
          @shell.puts("\e[1;35m\u2022 Goals\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-8s %s\e[0m" % [
              "ID",
              "Finished",
              "Type",
            ]
          )
          world["goals"].each do |k, v|
            @shell.puts(
              "  %-12d %-8s %s" % [
                k,
                v["finished"],
                v["type"],
              ]
            )
          end
          return
          
        end

      when "new"
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Get new targets"
        begin
          targets = @game.cmdGetNewTargets
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        @shell.puts("\e[1;35m\u2022 Targets\e[0m")
        @shell.puts(
          "  \e[35m%-12s %s\e[0m" % [
            "ID",
            "Name",
          ]
        )
        targets.each do |k, v|
          @shell.puts(
            "  %-12d %s" % [
              k,
              v["name"],
            ]
          )
        end
        return

      when "collect"
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        if words[1].nil?
          @shell.puts("#{cmd}: Specify bonus ID")
          return
        end
        id = words[1].to_i
        
        msg = "Bonus collect"
        begin
          @game.cmdBonusCollect(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return        

      when "update"
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        if words[1].nil?
          @shell.puts("#{cmd}: Specify goal ID")
          return
        end
        id = words[1].to_i
        
        if words[2].nil?
          @shell.puts("#{cmd}: Specify record")
          return
        end
        record = words[2].to_i
        
        msg = "Goal update"
        begin
          @game.cmdGoalUpdate(id, record)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
        return

      when "reject"
        if @game.config["sid"].nil?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        if words[1].nil?
          @shell.puts("#{cmd}: Specify goal ID")
          return
        end
        id = words[1].to_i
        
        msg = "Goal reject"
        begin
          @game.cmdGoalReject(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{msg} (#{e})", :error)
          return
        end
        @shell.log(msg, :success)
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
                         "run" => ["run <name>", "Run the script"],
                         "list" => ["list", "List scripts"],
                         "jobs" => ["jobs", "List active scripts"],
                         "kill" => ["kill <id>", "Kill the script"],
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
        Dir.children(SCRIPTS_DIR).sort.each do |child|
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
        script = @jobs[job][0]
        name = script.capitalize
        @jobs.delete(job)
        Object.send(:remove_const, name) unless @jobs.each_value.detect {|j| j[0] == script}
        return
        
      end
            
      super(words)
    end

    def run(script, args)
      job = @jobCounter += 1
      @jobs[job] = [
        script,
        Thread.current,
      ]
      fname = "#{SCRIPTS_DIR}/#{script}.rb"
      @shell.log("Run: #{script}", :script)
      
      begin
        name = script.capitalize
        load "#{fname}" unless Object.const_defined?(name)
        eval("#{name}.new(@game, @shell, args).main")
      rescue => e
        @shell.log("Error: #{script} (#{e.message})", :script)
      else
        @shell.log("Done: #{script}", :script)
      end

      @jobs.delete(job)
      Object.send(:remove_const, name) unless @jobs.each_value.detect {|j| j[0] == script}
    end
  end
  
  class ContextChat < ContextBase
    def initialize(game, shell)
      @rooms = Hash.new
      super(game, shell)
      @commands.merge!({
                         "open" => ["open <room>", "Open room"],
                         "close" => ["close <room>", "Close room"],
                         "list" => ["list", "List opened rooms"],
                         "say" => ["say <room> <text>", "Say to the room"],
                         "talk" => ["talk <room>", "Talk in the room"],
                         "users" => ["users <room>", "Show users list in the room"],
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
          begin
            response = @game.cmdChatSend(
              room,
              words[2..-1].join(" "),
              @rooms[room][1],
            )
          rescue Trickster::Hackers::RequestError => e
            @shell.log("Chat send (#{e})", :error)
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
          @shell.reading = true
          message = Readline.readline("#{room} \e[1;33m\u2765\e[0m ", true)
          @shell.reading = false
          break if message.nil?
          message.strip!
          Readline::HISTORY.pop if message.empty?
          next if message.empty?
          break if message == "!"
          response = nil
          @mutex.synchronize do
            begin
              response = @game.cmdChatSend(
                room,
                message,
                @rooms[room][1],
              )
            rescue Trickster::Hackers::RequestError => e
              @shell.log("Chat send (#{e})", :error)
              next
            end
            logMessages(room, response)
          end
        end
        return
        
    when "users"
      if @game.config["sid"].nil? || @game.appSettings.empty?
        @shell.puts "#{cmd}: Not connected"
        return
      end

      if words[1].nil?
        @shell.puts("#{cmd}: Specify room ID")
        return
      end

      messages = nil
      @mutex.synchronize do
        messages = @game.cmdChatDisplay(words[1])
      rescue Trickster::Hackers::RequestError => e
        @shell.log("Chat display (#{e})", :error)
        return
      end

      if messages.empty?
        @shell.puts "No users in room #{words[1]}"
        return
      end

      messages.uniq! {|m| m["id"]}
      @shell.puts "Users:"
      messages.each do |message|
        @shell.puts " %-30s .. %d" % [message["nick"], message["id"]]
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
        @mutex.synchronize do
          messages = @game.cmdChatDisplay(room, @rooms[room][1])
        rescue Trickster::Hackers::RequestError => e
          @shell.log("Chat display (#{e})", :error)
        else
          logMessages(room, messages)
        end
        
        sleep(@game.appSettings["chat_refresh_interval"].to_i)
      end
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
