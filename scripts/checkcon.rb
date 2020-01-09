class Checkcon < Sandbox::Script
  INTERVAL = 60
  
  def main
    loop do
      sleep(INTERVAL)

      msg = "Check connectivity"
      begin
        @game.cmdCheckCon
      rescue Trickster::Hackers::RequestError => e
        @shell.log("#{e.type}: #{e.description}", :script)
        return
      end
      @shell.log(msg, :success)
    end
  end
end
