class Colres < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120

  def main
    unless @game.connected?
      @logger.log('Not connected')
      return
    end

    loop do
      @game.player.load

      @game.player.net.each do |node|
        next unless node.kind_of?(Hackers::Nodes::Production)

        node_type = @game.node_types.get(node.type)
        node.collect
        @logger.log("Node #{node_type.name} (#{node.id}) resources collected")
      end
    rescue Hackers::RequestError => e
      @logger.error(e)
    ensure
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
    end
  end
end
