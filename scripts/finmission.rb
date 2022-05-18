class Finmission < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify mission ID")
      return
    end

    id = @args[0].to_i
    unless @game.missions_list.exist?(id)
      @logger.log("No such mission")
      return
    end

    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    begin
      log = @game.cmdPlayerMissionsGetLog
      unless log.key?(id)
        @logger.log("Mission #{id} not started")
        return
      end

      money = @game.missions_list.money(id) - log[id]["money"]
      bitcoins = @game.missions_list.bitcoins(id) - log[id]["bitcoins"]

      mission = @game.cmdGetMissionFight(id)
      currencies = Hash.new
      nodes = mission["nodes"].select {|k, v| [7, 11, 12, 13, 14].include?(v["type"])}
      nodes.each do |k, v|
        currencies[k] = 0
      end
      data = {
        :money => money,
        :bitcoins => bitcoins,
        :finished => Hackers::Game::MISSION_FINISHED,
        :currencies => currencies,
        :programs => mission["programs"],
      }
      @game.cmdPlayerMissionUpdate(id, data)
      @logger.log("Mission #{id} finished")
      @logger.log("Money: #{@game.missions_list.reward_money(id)} + #{money}")
      @logger.log("Bitcoins: #{@game.missions_list.reward_bitcoins(id)} + #{bitcoins}")
    rescue Hackers::RequestError => e
      @logger.error(e)
      return
    end
  end
end

