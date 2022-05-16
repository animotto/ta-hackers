# frozen_string_literal: true

module Hackers
  class ExperienceList < Dataset
    include Enumerable

    Level = Struct.new(:level, :experience)

    def initialize(*)
      super

      @levels = []
    end

    def load
      @raw_data = @api.experience_list
      parse
    end

    def each(&block)
      @levels.each(&block)
    end

    ##
    # Returns level by experience value
    def level(experience)
      value = 0
      @levels.each do |l|
        break if l.experience >= experience

        value = l.level
      end

      value
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      @levels.clear
      data[0].each do |record|
        @levels << Level.new(
          record[1].to_i,
          record[2].to_i,
        )
      end
    end
  end
end
