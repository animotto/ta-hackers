# frozen_string_literal: true

module Hackers
  ##
  # News list
  class NewsList < Dataset
    include Enumerable

    News = Struct.new(:datetime, :title, :body)

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
      data = Serializer.parseData(@raw_data)

      @news.clear
      data[0].each do |record|
        @news << News.new(
          record[1],
          record[2],
          record[3]
        )
      end
    end
  end
end
