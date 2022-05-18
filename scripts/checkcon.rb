class Checkcon < Sandbox::Script
  INTERVAL = 60

  def main
    loop do
      @game.cmdCheckCon
    rescue Hackers::RequestError => e
      @logger.error("#{e}")
    ensure
      sleep(INTERVAL)
    end
  end
end
