# frozen_string_literal: true

module Hackers
  class ShieldTypes < Dataset
    include Enumerable

    Shield = Struct.new(
      :id,
      :hours,
      :price,
      :title,
      :description
    )

    def initialize(*)
      super

      @shields = []
    end

    def load
      @raw_data = @api.shield_types
      parse
    end

    def each(&block)
      @shields.each(&block)
    end

    def get(shield)
      @shields.detect { |s| s.id == shield }
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      @shields.clear
      data[0].each do |record|
        @shields << Shield.new(
          record[0].to_i,
          record[1].to_i,
          record[3].to_i,
          record[4],
          record[5],
        )
      end
    end
  end
end
