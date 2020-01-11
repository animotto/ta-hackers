class Antiafk < Sandbox::Script
  CHECKCON_INTERVAL = 60
  AUTH_INTERVAL_MIN = 840
  AUTH_INTERVAL_ADD = 180
  
  def main
    checkConLast = authLast = authInterval = 0
    loop do
      if (Time.now - authLast).to_i >= authInterval
        auth = @game.cmdAuthIdPassword
        @game.config["sid"] = auth["sid"]
        @game.cmdNetGetForMaint
        authLast = Time.now
        authInterval = AUTH_INTERVAL_MIN + rand(AUTH_INTERVAL_ADD)
      end

      if (Time.now - checkConLast).to_i >= CHECKCON_INTERVAL
        @game.cmdCheckCon
        checkConLast = Time.now
      end
    rescue Trickster::Hackers::RequestError => e
      @shell.log("#{e}", :script)
      sleep(10)
    ensure
      sleep(0.1)
    end
  end
end
