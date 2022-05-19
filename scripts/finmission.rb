# frozen_string_literal: true

class Finmission < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log('Specify mission ID')
      return
    end

    id = @args[0].to_i
    unless @game.missions_list.exist?(id)
      @logger.log('No such mission')
      return
    end

    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    begin
      @game.missions.load

      unless @game.missions.exist?(id)
        @logger.log("Mission #{id} is not started")
        return
      end

      mission = @game.missions.get(id)
      mission_type = @game.missions_list.get(id)

      mission.attack
      mission.money = mission_type.additional_money
      mission.bitcoins = mission_type.additional_bitcoins
      mission.finish
      mission.update

      @logger.log("Mission #{mission_type.name} (#{id}) has been finished")
      @logger.log("Money: #{mission_type.reward_money} + #{mission_type.additional_money}")
      @logger.log("Bitcoins: #{mission_type.reward_bitcoins} + #{mission_type.additional_bitcoins}")
    rescue Hackers::RequestError => e
      @logger.error(e)
      return
    end
  end
end
