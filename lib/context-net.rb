module Sandbox
  class ContextNet < ContextBase
    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "profile" => ["profile", "Show profile"],
                         "readme" => ["readme", "Show readme"],
                         "nodes" => ["nodes", "Show nodes"],
                         "create" => ["create <type>", "Create node"],
                         "delete" => ["delete <id>", "Delete node"],
                         "upgrade" => ["upgrade <id>", "Upgrade node"],
                         "finish" => ["finish <id>", "Finish node"],
                         "builders" => ["builders <id> <builders>", "Set node builders"],
                         "collect" => ["collect <id>", "Collect node resources"],
                         "progs" => ["progs", "Show programs"],
                         "logs" => ["logs", "Show logs"],
                         "net" => ["net", "Show network structure"],
                         "missions" => ["missions", "Show missions log"],
                       })
    end

    def exec(words)
      cmd = words[0].downcase

      case cmd

      when "profile", "readme", "nodes", "progs", "logs", "net"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Network maintenance"
        begin
          net = @game.cmdNetGetForMaint
          net["profile"]["level"] = @game.getLevelByExp(net["profile"]["experience"])
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)

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

        when "nodes"
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

        when "progs"
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

        when "logs"
          @shell.puts("\e[1;35m\u2022 Security\e[0m")
          @shell.puts(
            "      \e[35m%-12s %-19s %-12s %s\e[0m" % [
              "ID",
              "Date",
              "Attacker",
              "Name",
            ]
          )
          logsSecurity = net["logs"].select do |k, v|
            v["target"]["id"] == @game.config["id"]
          end
          logsSecurity = logsSecurity.to_a.reverse.to_h
          logsSecurity.each do |k, v|
            @shell.puts(
              "  %s%s%s %-12s %-19s %-12s %s" % [
                v["success"] & Trickster::Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["success"] & Trickster::Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["success"] & Trickster::Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                k,
                v["date"],
                v["attacker"]["id"],
                v["attacker"]["name"],
              ]
            )
          end          

          @shell.puts
          @shell.puts("\e[1;35m\u2022 Hacks\e[0m")
          @shell.puts(
            "      \e[35m%-12s %-19s %-12s %s\e[0m" % [
              "ID",
              "Date",
              "Target",
              "Name",
            ]
          )
          logsHacks = net["logs"].select do |k, v|
            v["attacker"]["id"] == @game.config["id"]
          end
          logsHacks = logsHacks.to_a.reverse.to_h
          logsHacks.each do |k, v|
            @shell.puts(
              "  %s%s%s %-12s %-19s %-12s %s" % [
                v["success"] & Trickster::Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["success"] & Trickster::Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                v["success"] & Trickster::Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
                k,
                v["date"],
                v["target"]["id"],
                v["target"]["name"],
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

      when "missions"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Player missions get log"
        begin
          missions = @game.cmdPlayerMissionsGetLog
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)

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
end

