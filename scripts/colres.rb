class Colres < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120
  
  def main
    if @game.sid.empty?
      @logger.log("No session ID")
      return
    end

    loop do
      net = @game.cmdNetGetForMaint
      net["nodes"].each do |k, v|
        next unless v["type"] == 11 || v["type"] == 13
        @game.cmdCollectNode(k)
        @logger.log("Node #{k} resources collected")
      end
    rescue Hackers::RequestError => e
      @logger.error("#{e}")
    ensure
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
    end
  end
end

