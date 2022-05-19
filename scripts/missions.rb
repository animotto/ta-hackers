# frozen_string_literal: true

class Missions < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify player ID")
      return
    end

    id = @args[0].to_i
    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    missions = Hackers::Missions.new(@game.api, @game.player, id)

    begin
      missions.load
    rescue Hackers::RequestError => e
      @logger.error(e)
      return
    end

    @shell.puts("\e[1;35m\u2022 Missions log\e[0m")
    if missions.empty?
      @shell.puts('  Empty')
      return
    end

    @shell.puts(
      format(
        "  \e[35m%-1s %-7s %-7s %-8s %-20s %s\e[0m",
        '',
        'ID',
        'Money',
        'Bitcoins',
        'Datetime',
        'Name',
      )
    )

    missions.each do |mission|
      mission_type = @game.missions_list.get(mission.id)

      status = String.new
      case mission.status
      when Hackers::Missions::AWAITS
        status = "\e[37m\u2690\e[0m" 
      when Hackers::Missions::FINISHED
        status = "\e[32m\u2691\e[0m"
      when Hackers::Missions::REJECTED
        status = "\e[31m\u2691\e[0m"
      end

      @shell.puts(
        format(
          '  %-1s %-7d %-7d %-8d %-20s %s',
          status,
          mission.id,
          mission.money,
          mission.bitcoins,
          mission.datetime,
          mission_type.name
        )
      )
    end
  end
end
