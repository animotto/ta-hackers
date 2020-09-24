class Replay < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify replay ID")
      return
    end

    id = @args[0].to_i
    begin
      replay = @game.cmdFightGetReplay(id)
    rescue Trickster::Hackers::RequestError => e
      @logger.error(e)
      return
    end

    @logger.log("\u25cf Profiles")
    @logger.log("#{replay["profiles"]["attacker"]["id"]} (#{replay["profiles"]["attacker"]["name"]}) -> #{replay["profiles"]["target"]["id"]} (#{replay["profiles"]["target"]["name"]})")

    @logger.log("\u25cf Programs")
    replay["programs"].each do |program|
      @logger.log("#{@game.programTypes[program["type"]]["name"]}: #{program["amount"]} (#{program["level"]})")
    end

    @logger.log("\u25cf Trace")
    replay["trace"].each do |t|
      m = "#{t["type"]}: #{t["time"]}"
      m += " -> #{t["node"]}" unless t["node"].nil?
      m += " (#{@game.programTypes[t["program"]]["name"]})" unless t["program"].nil?
      m += " (#{t["index"]})" unless t["index"].nil?
      @logger.log(m)
    end
  end
end

