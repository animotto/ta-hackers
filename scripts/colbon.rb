class Colbon < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120
  
  def main
    if @game.sid.empty?
      @logger.log("No session ID")
      return
    end

    loop do
      net = @game.cmdNetGetForMaint
      world = @game.cmdPlayerWorld(net["profile"].country)
      world["bonuses"].each do |k, v|
        @game.cmdBonusCollect(k)
        @logger.log("Bonus #{k} collected with #{v["amount"]} credits")
      end
    rescue Trickster::Hacker::RequestError => e
      @logger.error("#{e}")
    ensure
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
    end
  end
end

