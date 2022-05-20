# frozen_string_literal: true

module Hackers
  ##
  # News list
  class NewsList < Dataset
    include Enumerable

    def initialize(*)
      super

      @news = []
    end

    def load
      @raw_data = @api.news
      parse
    end

    def each(&block)
      @news.each(&block)
    end

    private

    def parse
      serializer = Serializer::News.new(@raw_data)
      @news = serializer.parse(0)
    end
  end
end
