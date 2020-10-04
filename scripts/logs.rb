class Logs < Sandbox::Script
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
      logs = @game.cmdFightByFBFriend(id)
    rescue Trickster::Hackers::RequestError => e
      @logger.error(e)
      return
    end

    @shell.puts("Logs for #{id}")
    @shell.puts

    @shell.puts("\u2022 Security")
    @shell.puts(
      "  %-7s %-10s %-19s %-10s %-5s %s" % [
        "",
        "ID",
        "Date",
        "Attacker",
        "Level",
        "Name",
      ]
    )
    security = logs.select do |k, v|
      v["target"]["id"] == id
    end
    security = security.to_a.reverse.to_h
    security.each do |k, v|
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
    @shell.puts("\u2022 Hacks")
    @shell.puts(
      "  %-7s %-10s %-19s %-10s %-5s %s" % [
        "",
        "ID",
        "Date",
        "Target",
        "Level",
        "Name",
      ]
    )
    hacks = logs.select do |k, v|
      v["attacker"]["id"] == id
    end
    hacks = hacks.to_a.reverse.to_h
    hacks.each do |k, v|
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
  end
end

