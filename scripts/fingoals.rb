# frozen_string_literal: true

class Fingoals < Sandbox::Script
  INTERVAL_MIN = 300
  INTERVAL_ADD = 120

  def main
    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    loop do
      @game.world.goals.load

      goals = @game.world.goals.to_a
      goals.each do |goal|
        goal_type = GAME.goal_types.get(goal.type)
        goal.update(goal_type.amount)
        @logger.log("Goal #{goal.name} (#{goal.id}) finished with #{goal_type.credits} credits")
      end
    rescue Hackers::RequestError => e
      @logger.error(e)
    ensure
      sleep(INTERVAL_MIN + rand(INTERVAL_ADD))
    end
  end
end
