class Autohack < Sandbox::Script
  def main
    if @args[0].nil?
      @shell.log("Specify the number of hosts", :script)
      return
    end

    unless @game.config["sid"]
      @shell.log("No session ID", :script)
      return
    end
    
    n = 0
    loop do
      begin
        world = @game.cmdPlayerWorld(0)
        if world["targets"].empty?
          @shell.log("Get new targets", :script)
          @game.cmdGetNewTargets
          redo
        end
      rescue Trickster::Hackers::RequestError => e
        @shell.log("#{e}", :script)
        return
      end
        
      world["targets"].each do |k, v|
        @shell.log("Attack #{k} / #{v["name"]}", :script)

        begin
          net = @game.cmdNetGetForAttack(k)
          sleep(rand(4..9))

          update = @game.cmdFightUpdate(k, {
                                          money: 0,
                                          bitcoin: 0,
                                          nodes: "",
                                          loots: "",
                                          success: 0,
                                          programs: "",
                                        })
          sleep(rand(35..95))

          version = [
            @game.config["version"],
            @game.appSettings["node types"],
            @game.appSettings["program types"],
          ].join(",")
          fight = @game.cmdFight(k, {
                                   money: 0,
                                   bitcoin: 0,
                                   nodes: "",
                                   loots: "",
                                   success: 23,
                                   programs: "",
                                   summary: "",
                                   version: version,
                                   replay: "",
                                 })
          sleep(rand(5..12))

          leave = @game.cmdNetLeave(k)
          @game.cmdNetGetForMaint
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{e}", :script)
          return
        end

        n += 1
        return if n >= @args[0].to_i
        sleep(rand(420..950))
      end
    end
  end
end
