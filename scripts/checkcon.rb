class Checkcon < Sandbox::Script
  INTERVAL = 60
  
  def main
    loop do
      msg = "Check connectivity"
      if @game.cmdCheckCon
        @shell.log(msg, :success)
      else
        @shell.log(msg, :error)
      end
      sleep(INTERVAL)
    end
  end
end
