# frozen_string_literal: true

module Hackers
  ##
  # Language translations
  class LanguageTranslations < Dataset
    def load
      @raw_data = @api.language_translations
    end

    def get(key)
      @raw_data[key]
    end

    def each(&block)
      @raw_data.keys.each(&block)
    end
  end
end
