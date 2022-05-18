class Autohack < Sandbox::Script
  BLACKLIST = [
    127
  ]

  def main
    if @args[0].nil?
      @logger.log('Specify the number of hosts')
      return
    end

    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    n = 0
    @game.world.load
    targets = @game.world.targets

    loop do
      targets.each do |target|
        next if BLACKLIST.include?(k)
        @logger.log("Attack #{target.id} / #{target.name}")

        begin
          net = @game.cmdNetGetForAttack(target.id)
          sleep(rand(4..9))

          update = @game.cmdFightUpdate(
            target.id,
            {
              money: 0,
              bitcoin: 0,
              nodes: '',
              loots: '',
              success: Hackers::Game::SUCCESS_FAIL,
              programs: ''
            }
          )

          sleep(rand(35..95))

          version = [
            @game.config['version'],
            @game.app_settings.get('node types'),
            @game.app_settings.get('program types'),
          ].join(',')

          success = Hackers::Game::SUCCESS_CORE | Hackers::Game::SUCCESS_RESOURCES | Hackers::Game::SUCCESS_CONTROL
          fight = @game.cmdFight(
            target.id,
            {
              money: net['profile'].money,
              bitcoin: net['profile'].bitcoins,
              nodes: ''
              loots: ''
              success: success,
              programs: ''
              summary: ''
              version: version,
              replay: ''
            }
          )

          sleep(rand(5..12))

          leave = @game.cmdNetLeave(target.id)
          @game.player.load
        rescue => e
          @logger.error(e)
          sleep(rand(165..295))
          next
        end

        n += 1
        return if n == @args[0].to_i
        sleep(rand(15..25))
      end

      begin
        targets.new
      rescue Hackers::RequestError => e
        if e.type == 'Net::ReadTimeout'
          @logger.error('Get new targets timeout')
          retry
        end

        @logger.error("Get new targets (#{e})")
        return
      end
    end
  end
end
