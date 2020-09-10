class Colres < Sandbox::Script
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

      net["nodes"].each do |k, v|
        next unless v["type"] == 11 || v["type"] == 13
        begin
          @game.cmdCollectNode(k)
        rescue Trickster::Hackers::RequestError => e
          @logger.error("#{e}")
          return
        end
        
        @logger.log("Node #{k} resources collected")
      end
    end
  end
end
