class Autohack < Sandbox::Script
  def main
    if @args[0].nil?
      @shell.log("Specify the number of hosts", :script)
      return
    end

    n = 0
    loop do
      begin
        world = @game.cmdPlayerWorld(0)
      rescue Trickster::Hackers::RequestError => e
        @shell.log("#{e.type}: #{e.description}", :script)
        return
      end
      
      if world["targets"].empty?
        @shell.log("Get new targets", :script)
        begin
          @game.cmdGetNewTargets
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{e.type}: #{e.description}", :script)
          return
        end
        
        redo
      end
    
      world["targets"].each do |k, v|
        @shell.log("Attack #{k} / #{v["name"]}", :script)

        begin
          net = @game.cmdNetGetForAttack(k)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{e.type}: #{e.description}", :script)
          return
        end
        sleep(rand(4..9))

        begin
          update = @game.cmdFightUpdate(k, {
                                          money: 0,
                                          bitcoin: 0,
                                          nodes: "",
                                          loots: "",
                                          success: 0,
                                          programs: "",
                                        })
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{e.type}: #{e.description}", :script)
          return
        end
        sleep(rand(35..95))

        version = [
          @game.config["version"],
          @game.appSettings["node types"],
          @game.appSettings["program types"],
        ].join(",")
        begin
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
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{e.type}: #{e.description}", :script)
          return
        end
        sleep(rand(5..12))

        begin
          leave = @game.cmdNetLeave(k)
        rescue Trickster::Hackers::RequestError => e
          @shell.log("#{e.type}: #{e.description}", :script)
          return
        end

        n += 1
        return if n >= @args[0].to_i
        sleep(rand(420..950))
      end
    end
  end
end
