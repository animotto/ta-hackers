class Fingoals < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120

  def main
    if @game.sid.empty?
      @logger.log("No session ID")
      return
    end

    loop do
      goals = @game.cmdGoalByPlayer
      goals.each do |id, goal|
        @logger.log("Goal #{id} finished with #{@game.goalsTypes[goal["type"]]["credits"]} credits")
        @game.cmdGoalUpdate(id, @game.goalsTypes[goal["type"]]["amount"])
      end
    rescue Hackers::RequestError => e
      @logger.error(e)
    ensure
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
    end
  end
end

