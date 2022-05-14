# frozen_string_literal: true

module Hackers
  ##
  # Skin types
  class SkinTypes < Dataset
    def load
      @raw_data = @api.skin_types
    end

    def exist?(type)
      @raw_data.key?(type)
    end

    def each(&block)
      @raw_data.keys.each(&block)
    end

    def name(type)
      @raw_data[type]['name']
    end

    def price(type)
      @raw_data[type]['price']
    end

    def rank(type)
      @raw_data[type]['rank']
    end
  end
end
