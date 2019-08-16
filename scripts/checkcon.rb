class Checkcon < Sandbox::Script
  def main
    loop do
      msg = "Check connectivity"
      if @game.cmdCheckCon
        @shell.log(msg, :success)
      else
        @shell.log(msg, :error)
      end
      sleep(60)
    end
  end
end
