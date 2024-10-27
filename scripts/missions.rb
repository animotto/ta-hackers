# frozen_string_literal: true

class Missions < Sandbox::Script
  FLAGON_CHAR = "\u2691"
  FLAGOFF_CHAR = "\u2690"

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

    items = []
    missions.each do |mission|
      mission_type = @game.missions_list.get(mission.id)

      status = String.new
      case mission.status
      when Hackers::Missions::AWAITS
        status = ColorTerm.white(FLAGOFF_CHAR)
      when Hackers::Missions::FINISHED
        status = ColorTerm.green(FLAGON_CHAR)
      when Hackers::Missions::REJECTED
        status = ColorTerm.red(FLAGON_CHAR)
      end

      items << [
          status,
          mission.id,
          mission.money,
          mission.bitcoins,
          mission.datetime,
          mission_type.name
      ]
    end

    table = Printer::Table.new(
      'Missions log',
      ['', 'ID', 'Money', 'Bitcoins', 'Datetime', 'Name'],
      items
    )
    @shell.puts(table)
  end
end
