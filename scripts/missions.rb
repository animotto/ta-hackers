class Missions < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify player ID")
      return
    end

    id = @args[0].to_i
    if @game.sid.empty?
      @logger.log("No session ID")
      return
    end

    begin
      missions = @game.cmdPlayerMissionsGetLog(id)
    rescue Hackers::RequestError => e
      @logger.error(e)
      return
    end

    @shell.puts("Missions log for #{id}")
    @shell.puts(
      "  %-1s %-7s %-7s %-8s %-20s" % [
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
        when Hackers::Game::MISSION_AWAITS
         status = "\e[37m\u2690\e[0m"
        when Hackers::Game::MISSION_FINISHED
         status = "\e[32m\u2691\e[0m"
        when Hackers::Game::MISSION_REJECTED
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
  end
end

