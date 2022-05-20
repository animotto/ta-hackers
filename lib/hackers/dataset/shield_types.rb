# frozen_string_literal: true

module Hackers
  ##
  # Shield types
  class ShieldTypes < Dataset
    include Enumerable

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
      serializer = Serializer::ShieldType.new(@raw_data)
      @shields = serializer.parse(0)
    end
  end
end
