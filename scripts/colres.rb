# frozen_string_literal: true

class Colres < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120
  PERCENT = 90

  def main
    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    loop do
      @game.player.load
      @game.player.net.each do |node|
        next unless node.kind_of?(Hackers::Nodes::Production)

        node_type = @game.node_types.get(node.type)
        total_time = node_type.production_limit(node.level).to_f / node_type.production_speed(node.level) * 60 * 60
        percent = node.timer / total_time * 100
        next if percent < PERCENT

        money = @game.player.profile.money
        bitcoins = @game.player.profile.bitcoins

        node.collect
        case node_type.production_currency(node.level)
        when Hackers::Network::CURRENCY_MONEY
          currency = '$'
          collected = @game.player.profile.money - money
        when Hackers::Network::CURRENCY_BITCOINS
          currency = "\u20bf"
          collected = @game.player.profile.bitcoins - bitcoins
        end

        @logger.log("Node #{node_type.name} (#{node.id}) collected #{collected}#{currency}")
      end
    rescue Hackers::RequestError => e
      @logger.error(e)
    ensure
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
    end
  end
end
