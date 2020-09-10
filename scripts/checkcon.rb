class Checkcon < Sandbox::Script
  INTERVAL = 60
  
  def main
    loop do
      @game.cmdCheckCon
    rescue Trickster::Hackers::RequestError => e
      @logger.error("#{e}")
    ensure
      sleep(INTERVAL)
    end
  end
end
