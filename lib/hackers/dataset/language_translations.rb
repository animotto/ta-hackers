# frozen_string_literal: true

module Hackers
  ##
  # Language translations
  class LanguageTranslations < Dataset
    def initialize(*)
      super

      @translations = {}
    end

    def load
      @raw_data = @api.language_translations
      parse
    end

    def get(key)
      @translations[key]
    end

    def each(&block)
      @translations.keys.each(&block)
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      data[0].each do |record|
        @translations[record[0]] = record[1]
      end
    end
  end
end
