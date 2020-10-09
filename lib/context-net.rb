module Sandbox
  class ContextNet < ContextBase
    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
        "profile"  => ["profile", "Show profile"],
        "logs"     => ["logs", "Show logs"],
        "readme"   => ["readme", "Show readme"],
        "write"    => ["write <message>", "Write message to readme"],
        "remove"   => ["remove <id>", "Remove message from readme"],
        "clear"    => ["clear", "Clear readme"],
        "nodes"    => ["nodes", "Show nodes"],
        "create"   => ["create <type>", "Create node"],
        "upgrade"  => ["upgrade <id>", "Upgrade node"],
        "finish"   => ["finish <id>", "Finish node"],
        "cancel"   => ["cancel <id>", "Cancel node upgrade"],
        "delete"   => ["delete <id>", "Delete node"],
        "builders" => ["builders <id> <builders>", "Set node builders"],
        "collect"  => ["collect <id>", "Collect node resources"],
        "net"      => ["net", "Show network structure"],
     })
    end

    def exec(words)
      cmd = words[0].downcase

      case cmd

      when "profile", "readme", "write",
           "remove", "nodes", "logs",
           "net"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Network maintenance"
        begin
          net = @game.cmdNetGetForMaint
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)

        case cmd

        when "profile"
          builders = 0
          net["nodes"].each {|k, v| builders += v["builders"] if v["timer"].negative?}
          @shell.puts("\e[1;35m\u2022 Profile\e[0m")
          @shell.puts("  %-15s %d" % ["ID", net["profile"].id])
          @shell.puts("  %-15s %s" % ["Name", net["profile"].name])
          @shell.puts("  %-15s \e[33m$ %d\e[0m" % ["Money", net["profile"].money])
          @shell.puts("  %-15s \e[31m\u20bf %d\e[0m" % ["Bitcoins", net["profile"].bitcoins])
          @shell.puts("  %-15s %d" % ["Credits", net["profile"].credits])
          @shell.puts("  %-15s %d" % ["Experience", net["profile"].experience])
          @shell.puts("  %-15s %d" % ["Rank", net["profile"].rank])
          @shell.puts("  %-15s %s" % ["Builders", "\e[32m" + "\u25b0" * builders + "\e[37m" + "\u25b1" * (net["profile"].builders - builders) + "\e[0m"])
          @shell.puts("  %-15s %d" % ["X", net["profile"].x])
          @shell.puts("  %-15s %d" % ["Y", net["profile"].y])
          @shell.puts("  %-15s %d" % ["Country", net["profile"].country])
          @shell.puts("  %-15s %d" % ["Skin", net["profile"].skin])
          @shell.puts("  %-15s %d" % ["Level", @game.getLevelByExp(net["profile"].experience)])
          unless net["shield"]["type"].zero?
            @shell.puts("  %-15s %s (%d)" % ["Shield", @game.shieldTypes[net["shield"]["type"]]["name"], net["shield"]["timer"]])
          end
          @shell.puts("  Skins:") unless net["skins"].empty?
          net["skins"].each do |skin|
            @shell.puts("   %-3d %-15s" % [skin, @game.skinTypes[skin]["name"]])
          end
          return

        when "readme"
          @shell.puts("\e[1;35m\u2022 Readme\e[0m")
          net["readme"].each_with_index do |message, i|
            @shell.puts("  [#{i}] #{message}")
          end
          return

        when "write"
          if words[1].nil?
            @shell.puts("#{cmd}: Specify message")
            return
          end

          if @game.sid.empty?
            @shell.puts("#{cmd}: No session ID")
            return
          end

          msg = "Set readme"
          begin
            net["readme"].write(words[1])
            @game.cmdPlayerSetReadme(net["readme"])
          rescue
            @shell.logger.error("#{msg} (#{e})")
            return
          end

          @shell.logger.log(msg)
          @shell.puts("\e[1;35m\u2022 Readme\e[0m")
          net["readme"].each_with_index do |message, i|
            @shell.puts("  [#{i}] #{message}")
          end
          return

        when "remove"
          if words[1].nil?
            @shell.puts("#{cmd}: Specify message ID")
            return
          end

          id = words[1].to_i
          if net["readme"].id?(id)
            @shell.puts("#{cmd}: No such message ID")
            return
          end

          if @game.sid.empty?
            @shell.puts("#{cmd}: No session ID")
            return
          end

          msg = "Set readme"
          begin
            net["readme"].remove(id)
            @game.cmdPlayerSetReadme(net["readme"])
          rescue
            @shell.logger.error("#{msg} (#{e})")
            return
          end

          @shell.logger.log(msg)
          @shell.puts("\e[1;35m\u2022 Readme\e[0m")
          net["readme"].each_with_index do |message, i|
            @shell.puts("  [#{i}] #{message}")
          end
          return

        when "nodes"
          @shell.puts("\e[1;35m\u2022 Nodes\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-12s %-4s %-5s %-16s\e[0m" % [
              "ID",
              "Name",
              "Type",
              "Level",
              "Timer",
            ]
          )

          production = @game.nodeTypes.select {|k, v| v["titles"][0] == Trickster::Hackers::Game::PRODUCTION_TITLE}
          net["nodes"].each do |k, v|
            timer = String.new
            if v["timer"].negative?
              timer += "\e[32m" + "\u25b0" * v["builders"] + "\e[37m" + "\u25b1" * (net["profile"].builders - v["builders"]) + "\e[0m " unless v["builders"].nil?
              timer += @game.timerToDHMS(v["timer"] * -1)
            else
              if production.key?(v["type"])
                level = production[v["type"]]["levels"][v["level"]]
                case level["data"][0]
                  when Trickster::Hackers::Game::PRODUCTION_MONEY
                    timer += "\e[33m$ "
                  when Trickster::Hackers::Game::PRODUCTION_BITCOINS
                    timer += "\e[31m\u20bf "
                end
                produced = (level["data"][2].to_f / 60 / 60 * v["timer"]).to_i
                timer += produced < level["data"][1] ? produced.to_s : level["data"][1].to_s
                timer += "/" + level["data"][1].to_s
                timer += "\e[0m"
              end
            end
            @shell.puts(
              "  %-12d %-12s %-4d %-5d %-17s" % [
                k,
                @game.nodeTypes[v["type"]]["name"],
                v["type"],
                v["level"],
                timer,
              ]
            )
          end
          return

        when "logs"
          @shell.puts("\e[1;35m\u2022 Security\e[0m")
          @shell.puts(
            "  \e[35m%-7s %-10s %-19s %-10s %-5s %s\e[0m" % [
              "",
              "ID",
              "Date",
              "Attacker",
              "Level",
              "Name",
            ]
          )
          logsSecurity = net["logs"].select do |k, v|
            v["target"]["id"] == @game.config["id"]
          end
          logsSecurity = logsSecurity.to_a.reverse.to_h
          logsSecurity.each do |k, v|
            @shell.puts(
              "  %s%s%s %+-3d %-10s %-19s %-10s %-5d %s" % [
                v["success"] & Trickster::Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["success"] & Trickster::Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["success"] & Trickster::Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["rank"],
                k,
                v["date"],
                v["attacker"]["id"],
                v["attacker"]["level"],
                v["attacker"]["name"],
              ]
            )
          end          

          @shell.puts
          @shell.puts("\e[1;35m\u2022 Hacks\e[0m")
          @shell.puts(
            "  \e[35m%-7s %-10s %-19s %-10s %-5s %s\e[0m" % [
              "",
              "ID",
              "Date",
              "Target",
              "Level",
              "Name",
            ]
          )
          logsHacks = net["logs"].select do |k, v|
            v["attacker"]["id"] == @game.config["id"]
          end
          logsHacks = logsHacks.to_a.reverse.to_h
          logsHacks.each do |k, v|
            @shell.puts(
              "  %s%s%s %+-3d %-10s %-19s %-10s %-5d %s" % [
                v["success"] & Trickster::Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["success"] & Trickster::Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["success"] & Trickster::Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["rank"],
                k,
                v["date"],
                v["target"]["id"],
                v["target"]["level"],
                v["target"]["name"],
              ]
            )
          end
          return

        when "net"
          @shell.puts("\e[1;35m\u2022 Network structure\e[0m")
          @shell.puts(
            "  \e[35m%-5s %-12s %-12s %-5s %-4s %-4s %-4s %s\e[0m" % [
              "Index",
              "ID",
              "Name",
              "Type",
              "X",
              "Y",
              "Z",
              "Relations",
            ]
          )
          net["net"].each_index do |i|
            id = net["net"][i]["id"]
            type = net["nodes"][id]["type"]
            @shell.puts(
              "  %-5d %-12d %-12s %-5d %-+4d %-+4d %-+4d %s" % [
                i,
                id,
                @game.nodeTypes[type]["name"],
                type,
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

      when "clear"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Set readme"
        begin
          readme = Trickster::Hackers::Readme.new
          @game.cmdPlayerSetReadme(readme)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "create"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node type")
          return
        end
        type = words[1].to_i
        
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Create node"
        begin
          net = @game.cmdNetGetForMaint
          @game.cmdCreateNodeUpdateNet(type, net["net"])
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "delete"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i
        
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Delete node"
        begin
          net = @game.cmdNetGetForMaint
          @game.cmdDeleteNodeUpdateNet(id, net["net"])
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "upgrade"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i
        
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Upgrade node"
        begin
          @game.cmdUpgradeNode(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "finish"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i
        
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Finish node"
        begin
          @game.cmdFinishNode(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "cancel"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i

        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Cancel node"
        begin
          @game.cmdNodeCancel(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
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

        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Node set builders"
        begin
          @game.cmdNodeSetBuilders(id, builders)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "collect"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify node ID")
          return
        end
        id = words[1].to_i
        
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Collect node"
        begin
          @game.cmdCollectNode(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      end
      
      super(words)
    end
  end
end

