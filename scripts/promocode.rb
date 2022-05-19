# frozen_string_literal: true

class Promocode < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log('Specify promo code')
      return
    end

    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    begin
      response = @game.api.redeem_promocode(@args[0])
      @logger.log(response)
    rescue Hackers::RequestError => e
      @logger.log(e)
    end
  end
end
