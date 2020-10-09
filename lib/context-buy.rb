module Sandbox
  class ContextBuy < ContextBase
    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
        "skin"      => ["skin <type>", "Buy skin"],
        "shield"    => ["shield <type>", "Buy shield"],
        "builder"   => ["builder", "Buy builder"],
        "money"     => ["money <perc>", "Buy money"],
        "bitcoins"  => ["bitcoins <perc>", "Buy bitcoins"],
      })
    end

    def exec(words)
      cmd = words[0].downcase

      case cmd

      when "skin"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        skin = words[1]
        if skin.nil?
          @shell.puts("#{cmd}: Specify skin type")
          return
        end

        msg = "Buy skin"
        begin
          @game.cmdPlayerBuySkin(skin)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "shield"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        shield = words[1]
        if shield.nil?
          @shell.puts("#{cmd}: Specify shield type")
          return
        end

        msg = "Buy shield"
        begin
          @game.cmdShieldBuy(shield)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "builder"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        msg = "Buy builder"
        begin
          @game.cmdPlayerBuyBuilder
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      when "money", "bitcoins"
        if @game.sid.empty?
          @shell.puts("#{cmd}: No session ID")
          return
        end

        perc = words[1]
        if perc.nil?
          @shell.puts("#{cmd}: Specify currency percentage")
          return
        end

        case cmd
          when "money"
            currency = 0
          when "bitcoins"
            currency = 1
        end

        msg = "Buy currency"
        begin
          data = @game.cmdPlayerBuyCurrencyPerc(currency, perc)
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return
        end
        @shell.logger.log(msg)
        return

      end
      
      super(words)
    end
  end
end

