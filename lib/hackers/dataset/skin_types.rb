# frozen_string_literal: true

module Hackers
  ##
  # Skin types
  class SkinTypes < Dataset
    def initialize(*)
      super

      @skins = {}
    end

    def load
      @raw_data = @api.skin_types
      parse
    end

    def exist?(type)
      @skins.key?(type)
    end

    def each(&block)
      @skins.keys.each(&block)
    end

    def name(type)
      @skins[type][:name]
    end

    def price(type)
      @skins[type][:price]
    end

    def rank(type)
      @skins[type][:rank]
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      data[0].each do |record|
        @skins[record[0].to_i] = {
          name: record[1],
          price: record[2].to_i,
          rank: record[3].to_i
        }
      end
    end
  end
end
