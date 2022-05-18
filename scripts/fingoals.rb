class Fingoals < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120

  def main
    unless @game.connected?
      @logger.log('Not connected')
      return
    end

    loop do
      goals = @game.cmdGoalByPlayer
      goals.each do |id, goal|
        goal_type = GAME.goal_types.get(goal['type'])
        @game.cmdGoalUpdate(id, goal_type.amount)
        @logger.log("Goal #{id} finished with #{goal_type.credits} credits")
      end
    rescue Hackers::RequestError => e
      @logger.error(e)
    ensure
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
    end
  end
end

