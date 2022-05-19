# frozen_string_literal: true

class Antiafk < Sandbox::Script
  CHECKCON_INTERVAL = 60
  AUTH_INTERVAL_MIN = 840
  AUTH_INTERVAL_ADD = 180

  def main
    checkcon_last = auth_last = auth_interval = 0
    loop do
      if (Time.now - auth_last).to_i >= auth_interval
        @game.auth
        @game.player.load
        auth_last = Time.now
        auth_interval = AUTH_INTERVAL_MIN + rand(AUTH_INTERVAL_ADD)
      end

      if (Time.now - checkcon_last).to_i >= CHECKCON_INTERVAL
        @game.check_connectivity
        checkcon_last = Time.now
      end
    rescue Hackers::RequestError => e
      @logger.error(e)
      sleep(10)
    ensure
      sleep(1)
    end
  end
end
