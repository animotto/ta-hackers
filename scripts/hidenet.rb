class Hidenet < Sandbox::Script
  COORD_MIN = 1
  COORD_MAX = 999

  def main
    hide = @args[0]
    if hide.nil? || hide !~ /^(on|off)$/
      @logger.log('Specify on|off argument')
      return
    end

    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    @game.player.load
    net = @game.player.net
    topology = net.topology

    coord = hide == 'on' ? COORD_MAX : COORD_MIN
    net.each do |node|
      node.move(coord, coord, coord)
    end

    net.update

    @logger.log("Node coordinates have been updated to #{coord}")
  rescue Hackers::RequestError => e
    @logger.error(e)
  end
end
