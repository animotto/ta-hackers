class Colres < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120
  
  def main
    loop do
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
      unless net = @game.cmdNetGetForMaint
        @shell.log("Can't get network data", :script)
        next
      end
      net["nodes"].each do |k, v|
        next unless v["type"] == 11 || v["type"] == 13
        unless @game.cmdCollect(k)
          @shell.log("Can't collect node {k}")
        else
          @shell.log("Node #{k} resources collected", :script)
        end
      end
    end
  end
end
