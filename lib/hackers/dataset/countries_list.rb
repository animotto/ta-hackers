# frozen_string_literal: true

require 'json'

module Hackers
  class CountriesList < Dataset
    include Enumerable

    UNKNOWN = 'Unknown'

    Country = Struct.new(:id, :name)

    def initialize(*)
      super

      @countries = []
    end

    def load
      parse
    end

    def each(&block)
      @countries.each(&block)
    end

    def name(id)
      country = @countries.detect { |c| c.id == id }
      return UNKNOWN if country.nil?

      country.name
    end

    private

    def parse
      data = JSON.parse(@raw_data)

      @countries.clear
      data.each do |k, v|
        @countries << Country.new(k.to_i, v)
      end
    end
  end
end
