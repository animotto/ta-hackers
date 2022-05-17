# frozen_string_literal: true

module Hackers
  ##
  # Goal types
  class GoalTypes < Dataset
    include Enumerable

    Goal = Struct.new(
      :id,
      :name,
      :amount,
      :credits,
      :title,
      :description
    )

    def initialize(*)
      super

      @goals = []
    end

    def load
      @raw_data = @api.goal_types
      parse
    end

    def each(&block)
      @goals.each(&block)
    end

    def get(goal)
      @goals.detect { |g| g.id == goal }
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      @goals.clear
      data[0].each do |record|
        @goals << Goal.new(
          record[0].to_i,
          record[1],
          record[2].to_i,
          record[3].to_i,
          record[7],
          record[8]
        )
      end
    end
  end
end
