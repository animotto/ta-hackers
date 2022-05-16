class Replayinfo < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify replay ID")
      return
    end
    id = @args[0].to_i

    begin
      info = @game.cmdFightGetReplayInfo(id)
    rescue Hackers::RequestError => e
      @logger.error(e)
      return
    end

    unless info["ok"]
      @logger.error("No such replay")
      return
    end

    @shell.puts("Replay info: #{id}")
    @shell.puts(" %-15s %s" % ["Datetime", info["datetime"]])
    @shell.puts(" %-15s %s%s%s" % [
      "Success",
      info["success"] & Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
      info["success"] & Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
      info["success"] & Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
    ])
    @shell.puts(" %-15s %+d" % ["Rank", info["rank"]])
    @shell.puts(" %-15s %d" % ["Money", info["money"]])
    @shell.puts(" %-15s %d" % ["Bitcoins", info["bitcoins"]])
    @shell.puts(" %-15s %s" % ["Test", info["test"]])
    @shell.puts(" Attacker:")
    @shell.puts("  %-15s %d" % ["ID", info["attacker"]["id"]])
    @shell.puts("  %-15s %s" % ["Name", info["attacker"]["name"]])
    @shell.puts("  %-15s %d (%s)" % ["Country", info["attacker"]["country"], @game.countries_list.name(info["attacker"]["country"])])
    @shell.puts("  %-15s %d" % ["Level", info["attacker"]["level"]])
    @shell.puts(" Target:")
    @shell.puts("  %-15s %d" % ["ID", info["target"]["id"]])
    @shell.puts("  %-15s %s" % ["Name", info["target"]["name"]])
    @shell.puts("  %-15s %d (%s)" % ["Country", info["target"]["country"], @game.countries_list.name(info["target"]["country"])])
    @shell.puts("  %-15s %d" % ["Level", info["target"]["level"]])
  end
end

