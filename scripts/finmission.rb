class Finmission < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify mission ID")
      return
    end

    id = @args[0].to_i
    unless @game.missionsList.key?(id)
      @logger.log("No such mission")
      return
    end

    if @game.sid.empty?
      @logger.log("No session ID")
      return
    end

    begin
      log = @game.cmdPlayerMissionsGetLog
      unless log.key?(id)
        @logger.log("Mission #{id} not started")
        return
      end

      money = @game.missionsList[id]["money"] - log[id]["money"]
      bitcoins = @game.missionsList[id]["bitcoins"] - log[id]["bitcoins"]

      mission = @game.cmdGetMissionFight(id)
      currencies = Hash.new
      nodes = mission["nodes"].select {|k, v| [7, 11, 12, 13, 14].include?(v["type"])}
      nodes.each do |k, v|
        currencies[k] = 0
      end
      data = {
        :money => money,
        :bitcoins => bitcoins,
        :finished => Trickster::Hackers::Game::MISSION_FINISHED,
        :currencies => currencies,
        :programs => mission["programs"],
      }
      @game.cmdPlayerMissionUpdate(id, data)
      @logger.log("Mission #{id} finished")
      @logger.log("Money: #{@game.missionsList[id]["reward"]["money"]} + #{money}")
      @logger.log("Bitcoins: #{@game.missionsList[id]["reward"]["bitcoins"]} + #{bitcoins}")
    rescue Trickster::Hackers::RequestError => e
      @logger.error(e)
      return
    end
  end
end

