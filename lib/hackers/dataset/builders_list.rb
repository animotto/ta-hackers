# frozen_string_literal: true

module Hackers
  ##
  # Builders list
  class BuildersList < Dataset
    include Enumerable

    def initialize(*)
      super

      @builders = []
    end

    def load
      @raw_data = @api.builders_list
      parse
    end

    def each(&block)
      @builders.each(&block)
    end

    def get(amount)
      @builders.detect { |b| b.amount == amount }
    end

    private

    def parse
      serializer = Serializer::Builder.new(@raw_data)
      @builders = serializer.parse(0)
    end
  end
end
