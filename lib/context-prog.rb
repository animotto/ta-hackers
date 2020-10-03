module Sandbox
  class ContextProg < ContextBase
    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "list" => ["list", "Show programs list"],
                         "create" => ["create <type>", "Create program"],
                         "upgrade" => ["upgrade <id>", "Upgrade program"],
                         "finish" => ["finish <id>", "Finish program"],
                         "edit" => ["edit <type,amount>", "Edit programs"],
                         "queue" => ["queue", "Show programs queue"],
                         "sync" => ["sync <type,amount>", "Set programs queue"],
                       })
    end

    def exec(words)
      cmd = words[0].downcase

      case cmd

      when "list", "queue"
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

        when "list"
          @shell.puts("\e[1;35m\u2022 Programs\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-12s %-4s %-6s %-5s %-12s\e[0m" % [
              "ID",
              "Name",
              "Type",
              "Amount",
              "Level",
              "Timer",
            ]
          )
          net["programs"].each do |k, v|
            timer = String.new
            if v["timer"].negative?
              timer = @game.timerToDHMS(v["timer"] * -1)
            end
            @shell.puts(
              "  %-12d %-12s %-4d %-6d %-5d %-12s" % [
                k,
                @game.programTypes[v["type"]]["name"],
                v["type"],
                v["amount"],
                v["level"],
                timer,
              ]
            )
          end
          return

        when "queue"
          @shell.puts("\e[1;35m\u2022 Programs queue\e[0m")
          @shell.puts(
            "  \e[35m%-12s %-4s %-6s %-5s\e[0m" % [
              "Name",
              "Type",
              "Amount",
              "Timer",
            ]
          )

          total = 0
          net["queue"].each do |queue|
            id, program = net["programs"].detect {|k, v| v["type"] == queue["type"]}
            compile = @game.programTypes[queue["type"]]["levels"][program["level"]]["compile"]
            total += queue["amount"] * compile - queue["timer"]
            @shell.puts(
              "  %-12s %-4d %-6d %-5d" % [
                @game.programTypes[queue["type"]]["name"],
                queue["type"],
                queue["amount"],
                compile - queue["timer"],
              ]
            )
          end
          @shell.puts
          @shell.puts("  \e[35mSequence: #{@game.syncSeq}\e[0m")
          unless total.zero?
            @shell.puts("  \e[35mTotal: #{@game.timerToDHMS(total)}\e[0m")
          end
          return

        end

      when "sync"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        if words.length < 2
          @shell.puts("#{cmd}: Specify queue data")
          return
        end

        msg = "Sync queue"
        programs = Hash.new
        words[1..-1].each do |data|
          data = data.split(",")
          if data.length != 2
            @shell.puts("#{cmd}: Invalid queue data")
            return
          end
          programs[data[0].to_i] = data[1].to_i
        end

        begin
          sync = @game.cmdQueueSync(programs)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)

        @shell.puts("\e[1;35m\u2022 Programs queue\e[0m")
        @shell.puts(
          "  \e[35m%-12s %-4s %-6s %-5s\e[0m" % [
            "Name",
            "Type",
            "Amount",
            "Timer",
          ]
        )

        total = 0
        sync["queue"].each do |queue|
            id, program = sync["programs"].detect {|k, v| v["type"] == queue["type"]}
            compile = @game.programTypes[queue["type"]]["levels"][program["level"]]["compile"]
            total += queue["amount"] * compile - queue["timer"]
          @shell.puts(
            "  %-12s %-4d %-6d %-5d" % [
              @game.programTypes[queue["type"]]["name"],
              queue["type"],
              queue["amount"],
              compile - queue["timer"],
            ]
          )
        end
        @shell.puts
        @shell.puts("  \e[35mSequence: #{@game.syncSeq}\e[0m")
        unless total.zero?
          @shell.puts("  \e[35mTotal: #{@game.timerToDHMS(total)}\e[0m")
        end
        return

      when "create"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        if words.length < 2
          @shell.puts("#{cmd}: Specify program type")
          return
        end

        type = words[1].to_i
        msg = "Create program"
        begin
          id = @game.cmdCreateProgram(type)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "upgrade"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        if words.length < 2
          @shell.puts("#{cmd}: Specify program type")
          return
        end

        id = words[1].to_i
        msg = "Upgrade program"
        begin
          @game.cmdUpgradeProgram(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "finish"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        if words.length < 2
          @shell.puts("#{cmd}: Specify program type")
          return
        end

        id = words[1].to_i
        msg = "Finish program"
        begin
          @game.cmdFinishProgram(id)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "edit"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        if words.length < 2
          @shell.puts("#{cmd}: Specify programs data")
          return
        end

        msg = "Delete program"
        programs = Hash.new
        words[1..-1].each do |data|
          data = data.split(",")
          if data.length != 2
            @shell.puts("#{cmd}: Invalid programs data")
            return
          end
          programs[data[0].to_i] = data[1].to_i
        end

        begin
          programs = @game.cmdDeleteProgram(programs)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)

        @shell.puts("\e[1;35m\u2022 Programs\e[0m")
        @shell.puts(
          "  \e[35m%-12s %-4s %-6s\e[0m" % [
            "Name",
            "Type",
            "Amount",
          ]
        )
        programs.each do |k, v|
          @shell.puts(
            "  %-12s %-4d %-6d" % [
              @game.programTypes[k]["name"],
              k,
              v["amount"],
            ]
          )
        end
        return

      end
      
      super(words)
    end
  end
end

