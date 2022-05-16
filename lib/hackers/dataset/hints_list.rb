# frozen_string_literal: true

module Hackers
  class HintsList < Dataset
    include Enumerable

    Hint = Struct.new(:id, :description)

    def initialize(*)
      super

      @hints = []
    end

    def load
      @raw_data = @api.hints_list
      parse
    end

    def each(&block)
      @hints.each(&block)
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      @hints.clear
      data[0].each do |record|
        @hints << Hint.new(
          record[0].to_i,
          record[1]
        )
      end
    end
  end
end
