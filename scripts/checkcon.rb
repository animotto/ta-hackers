class Checkcon < Sandbox::Script
  INTERVAL = 60
  
  def main
    loop do
      @game.cmdCheckCon
    rescue Trickster::Hackers::RequestError => e
      @shell.log("#{e}", :script)
    ensure
      sleep(INTERVAL)
    end
  end
end
