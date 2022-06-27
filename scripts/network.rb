# frozen_string_literal: true

class Network < Sandbox::Script
  def main
    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    if @args[0].nil?
      @logger.log('Specify player ID')
      return
    end

    id = @args[0].to_i

    begin
      target = @game.attack_test(id)
    rescue Hackers::RequestError => e
      @logger.error(e)
      return
    end

    table = Printer::Network.new(target.net, @game)
    @shell.puts(table)
  end
end
