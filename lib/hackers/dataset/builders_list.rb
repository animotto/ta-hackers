# frozen_string_literal: true

module Hackers
  class BuildersList < Dataset
    include Enumerable

    Builder = Struct.new(:amount, :price)

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
      data = Serializer.parseData(@raw_data)

      @builders.clear
      data[0].each do |record|
        @builders << Builder.new(
          record[0].to_i,
          record[1].to_i
        )
      end
    end
  end
end
