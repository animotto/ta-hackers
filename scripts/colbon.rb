class Colbon < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120

  def main
    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    loop do
      @game.player.load unless @game.player.loaded?
      @game.world.load

      bonuses = @game.world.bonuses.to_a
      bonuses.each do |bonus|
        bonus.collect
        @logger.log("Bonus #{bonus.id} collected with #{bonus.amount} credits")
      end
    rescue Hackers::RequestError => e
      @logger.error(e)
    ensure
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
    end
  end
end
