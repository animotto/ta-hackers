class Promocode < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log('Specify promo code')
      return
    end

    begin
      code = @game.cmdRedeemPromoCode(@game.config['id'], @args[0])
    rescue Hackers::RequestError => e
      @logger.log(e)
    else
      @logger.log(code['message'])
    end
  end
end
