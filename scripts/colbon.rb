class Colbon < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120
  
  def main
    loop do
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))

      begin
        net = @game.cmdNetGetForMaint
      rescue Trickster::Hackers::RequestError => e
        @logger.error("#{e}")
        return
      end

      begin
        world = @game.cmdPlayerWorld(net["profile"]["country"])
      rescue Trickster::Hackers::RequestError => e
        @logger.error("#{e}")
        return
      end

      world["bonuses"].each do |k, v|
        begin
          @game.cmdBonusCollect(k)
        rescue Trickster::Hackers::RequestError => e
          @logger.error("#{e}")
          return
        end

        @logger.log("Bonus #{k} collected with #{v["amount"]} credits")
      end
    end
  end
end
