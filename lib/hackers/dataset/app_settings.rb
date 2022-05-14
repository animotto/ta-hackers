# frozen_string_literal: true

module Hackers
  ##
  # Application settings
  class AppSettings < Dataset
    attr_reader :datetime

    def initialize(*)
      super

      @settings = {}
      @languages = {}
    end

    def load
      @raw_data = @api.app_settings
      parse
    end

    def each(&block)
      @settings.keys.each(&block)
    end

    def get(key)
      @settings[key]
    end

    def languages
      @languages.keys
    end

    def language(name)
      @languages[name]
    end

    private

    def parse
      serializer = Serializer.new(@raw_data)
      data = serializer.fields

      data[0][0..10].each do |record|
        @settings[record[1]] = record[2] =~ /^\d+$/ ? record[2].to_i : record[2]
      end

      @datetime = data[0][11][0]

      languages = data[0][12]
      languages.each do |language|
        code, value = language.split(':', 2)
        @languages[code] = value.to_i
      end

      data[0][13..].each do |record|
        @settings[record[0]] = record[1] =~ /^\d+$/ ? record[1].to_i : record[1]
      end
    end
  end
end
