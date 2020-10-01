module Sandbox
  class ContextMission < ContextBase
    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "list" => ["list", "Show missions log"],
                         "start" => ["start <id>", "Start mission"],
                         "reject" => ["reject <id>", "Reject mission"],
                       })
    end

    def exec(words)
      cmd = words[0].downcase

      case cmd

      when "list"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Missions get log"
        begin
          missions = @game.cmdPlayerMissionsGetLog
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)

        @shell.puts("\e[1;35m\u2022 Missions log\e[0m")
        @shell.puts(
          "  \e[35m%-1s %-7s %-7s %-8s %-20s\e[0m" % [
            "",
            "ID",
            "Money",
            "Bitcoins",
            "Datetime",
          ]
        )
        missions.each do |k, v|
          status = String.new
          case v["finished"]
            when Trickster::Hackers::Game::MISSION_AWAITS
             status = "\e[37m\u2690\e[0m" 
            when Trickster::Hackers::Game::MISSION_FINISHED
             status = "\e[32m\u2691\e[0m"
            when Trickster::Hackers::Game::MISSION_REJECTED
             status = "\e[31m\u2691\e[0m"
          end
          @shell.puts(
            "  %-1s %-7d %-7d %-8d %-20s" % [
              status,
              k,
              v["money"],
              v["bitcoins"],
              v["datetime"],
            ]
          )
          end
        return

      when "start"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        if words[1].nil?
          @shell.puts("#{cmd}: Specify mission ID")
          return
        end
        id = words[1].to_i
        unless @game.missionsList.key?(id)
          @shell.puts("#{cmd}: No such mission")
          return
        end

        msg = "Mission message delivered"
        begin
          missions = @game.cmdPlayerMissionMessageDelivered(id)
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
          @shell.puts("#{cmd}: Specify mission ID")
          return
        end
        id = words[1].to_i
        unless @game.missionsList.key?(id)
          @shell.puts("#{cmd}: No such mission")
          return
        end

        msg = "Mission reject"
        begin
          missions = @game.cmdPlayerMissionReject(id)
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

