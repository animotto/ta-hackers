class Logs < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify player ID")
      return
    end

    id = @args[0].to_i
    begin
      logs = @game.cmdFightByFBFriend(id)
    rescue Trickster::Hackers::RequestError => e
      @logger.error(e)
      return
    end

    @logger.log("\u25cf Security")
    security = logs.select do |k, v|
      v["target"]["id"] == id
    end
    security = security.to_a.reverse.to_h
    security.each do |k, v|
      @logger.log(
        "%s%s%s %+-3d %-12s %-19s %-12s %s (%d)" % [
          v["success"] & Trickster::Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\u25b2",
          v["success"] & Trickster::Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\u25b2",
          v["success"] & Trickster::Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\u25b2",
          v["rank"],
          k,
          v["date"],
          v["attacker"]["id"],
          v["attacker"]["name"],
          v["attacker"]["level"],
        ]
      )
    end          

    @logger.log("\u25cf Hacks")
    hacks = logs.select do |k, v|
      v["attacker"]["id"] == id
    end
    hacks = hacks.to_a.reverse.to_h
    hacks.each do |k, v|
      @logger.log(
        "%s%s%s %+-3d %-12s %-19s %-12s %s (%d)" % [
          v["success"] & Trickster::Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\u25b2",
          v["success"] & Trickster::Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\u25b2",
          v["success"] & Trickster::Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\u25b2",
          v["rank"],
          k,
          v["date"],
          v["target"]["id"],
          v["target"]["name"],
          v["target"]["level"],
        ]
      )
    end
  end
end

