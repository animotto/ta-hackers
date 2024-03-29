# frozen_string_literal: true

class Checkcon < Sandbox::Script
  INTERVAL = 60

  def main
    loop do
      @game.check_connectivity
    rescue Hackers::RequestError => e
      @logger.error(e)
    ensure
      sleep(INTERVAL)
    end
  end
end
