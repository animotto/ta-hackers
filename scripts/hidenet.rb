class Hidenet < Sandbox::Script
  def main
    hide = @args[0]
    if hide.nil? || hide !~ /^(on|off)$/
      @logger.log("Specify on|off argument")
      return
    end

    begin
      net = @game.cmdNetGetForMaint
    rescue Trickster::Hackers::RequestError => e
      @logger.error("#{e}")
      return
    end

    coord = hide == "on" ? 999 : 1
    net["net"].each_index do |i|
      net["net"][i]["x"] = coord
      net["net"][i]["y"] = coord
      net["net"][i]["z"] = coord
    end

    begin
      @game.cmdUpdateNet(net["net"])
    rescue Trickster::Hackers::RequestError => e
      @logger.error("#{e}")
      return
    end
    
    @logger.log("Nodes coordinates updated to #{coord}")
  end
end
