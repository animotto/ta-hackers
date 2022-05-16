# frozen_string_literal: true

module Hackers
  ##
  # Skin types
  class SkinTypes < Dataset
    include Enumerable

    Skin = Struct.new(:id, :name, :price, :rank)

    def initialize(*)
      super

      @skins = []
    end

    def load
      @raw_data = @api.skin_types
      parse
    end

    def exist?(skin)
      @skins.any? { |s| s.id == skin }
    end

    def get(skin)
      @skins.detect { |s| s.id == skin }
    end

    def each(&block)
      @skins.each(&block)
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      @skins.clear
      data[0].each do |record|
        @skins << Skin.new(
          record[0].to_i,
          record[1],
          record[2].to_i,
          record[3].to_i
        )
      end
    end
  end
end
