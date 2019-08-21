class Colbon < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120
  
  def main
    loop do
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
      unless net = @game.cmdNetGetForMaint
        @shell.log("Can't get network data", :script)
        next
      end
      unless world = @game.cmdPlayerWorld(net["profile"]["country"])
        @shell.log("Can't get world data", :script)
        next
      end

      world["bonuses"].each do |k, v|
        unless @game.cmdBonusCollect(k)
          @shell.log("Can't collect bonus #{k}", :script)
        else
          @shell.log("Bonus #{k} collected with #{v["amount"]} credits", :script)
        end
      end
    end
  end
end
