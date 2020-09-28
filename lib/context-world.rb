module Sandbox
  class ContextWorld < ContextBase
    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "targets" => ["targets", "Show targets"],
                         "new" => ["new", "Get new targets"],
                         "bonuses" => ["bonuses", "Show bonuses"],
                         "collect" => ["collect <id>", "Collect bonus"],
                         "goals" => ["goals", "Show goals"],
                         "update" => ["update <id> <record>", "Update goal"],
                         "reject" => ["reject <id>", "Reject goal"],
                       })
    end

    def exec(words)
      cmd = words[0].downcase
      case cmd

      when "targets", "bonuses", "goals"
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
        
        msg = "World"
        begin
          world = @game.cmdPlayerWorld(net["profile"]["country"])
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)

        case cmd

        when "targets"
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

        when "bonuses"
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

        when "goals"
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
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Get new targets"
        begin
          targets = @game.cmdGetNewTargets
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
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
        if @game.sid.empty?
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
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return        

      when "update"
        if @game.sid.empty?
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
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "reject"
        if @game.sid.empty?
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

