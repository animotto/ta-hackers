class Checkcon < Sandbox::Script
  INTERVAL = 60
  
  def main
    loop do
      @game.cmdCheckCon
    rescue Trickster::Hackers::RequestError => e
      @shell.log("#{e.type}: #{e.description}", :script)
    ensure
      sleep(INTERVAL)
    end
  end
end
