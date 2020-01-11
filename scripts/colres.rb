class Colres < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120
  
  def main
    loop do
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))

      begin
        net = @game.cmdNetGetForMaint
      rescue Trickster::Hackers::RequestError => e
        @shell.log("#{e}", :script)
        return
      end

      net["nodes"].each do |k, v|
        next unless v["type"] == 11 || v["type"] == 13
        begin
          @game.cmdCollectNode(k)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{e}", :script)
          return
        end
        
        @shell.log("Node #{k} resources collected", :script)
      end
    end
  end
end
