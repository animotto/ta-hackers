# frozen_string_literal: true

class Replayinfo < Sandbox::Script
  SUCCESS_CHAR = "\u25b2"
  FAIL_CHAR = "\u25b3"

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
      'Success',
      (info['success'] & Hackers::Network::SUCCESS_CORE).zero? ? FAIL_CHAR : ColorTerm.green(SUCCESS_CHAR),
      (info['success'] & Hackers::Network::SUCCESS_RESOURCES).zero? ? FAIL_CHAR : ColorTerm.green(SUCCESS_CHAR),
      (info['success'] & Hackers::Network::SUCCESS_CONTROL).zero? ? FAIL_CHAR : ColorTerm.green(SUCCESS_CHAR)
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

