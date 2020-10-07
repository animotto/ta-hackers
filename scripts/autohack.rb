class Autohack < Sandbox::Script
  BLACKLIST = [
    127,
  ]

  def main
    if @args[0].nil?
      @logger.log("Specify the number of hosts")
      return
    end

    if @game.sid.empty?
      @logger.log("No session ID")
      return
    end
    
    n = 0
    world = @game.cmdPlayerWorld(0)
    targets = world["targets"]

    loop do
      targets.each do |k, v|
        next if BLACKLIST.include?(k)
        @logger.log("Attack #{k} / #{v["name"]}")

        begin
          net = @game.cmdNetGetForAttack(k)
          sleep(rand(4..9))

          update = @game.cmdFightUpdate(k, {
                                          money: 0,
                                          bitcoin: 0,
                                          nodes: "",
                                          loots: "",
                                          success: Trickster::Hackers::Game::SUCCESS_FAIL,
                                          programs: "",
                                        })
          sleep(rand(35..95))

          version = [
            @game.config["version"],
            @game.appSettings["node types"],
            @game.appSettings["program types"],
          ].join(",")
          success = Trickster::Hackers::Game::SUCCESS_CORE | Trickster::Hackers::Game::SUCCESS_RESOURCES | Trickster::Hackers::Game::SUCCESS_CONTROL
          fight = @game.cmdFight(k, {
                                   money: net["profile"].money,
                                   bitcoin: net["profile"].bitcoins,
                                   nodes: "",
                                   loots: "",
                                   success: success,
                                   programs: "",
                                   summary: "",
                                   version: version,
                                   replay: "",
                                 })
          sleep(rand(5..12))

          leave = @game.cmdNetLeave(k)
          @game.cmdNetGetForMaint
        rescue => e
          @logger.error("#{e}")
          sleep(rand(165..295))
          next
        end

        n += 1
        return if n == @args[0].to_i
        sleep(rand(15..25))
      end

      begin
        new = @game.cmdGetNewTargets
        targets = new["targets"]
      rescue Trickster::Hackers::RequestError => e
        if e.type == "Net::ReadTimeout"
          @logger.error("Get new targets timeout")
          retry
        end
        @logger.error("Get new targets (#{e})")
        return
      end
    end
  end
end

