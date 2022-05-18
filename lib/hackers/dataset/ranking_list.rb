# frozen_string_literal: true

module Hackers
  ##
  # Ranking list
  class RankingList < Dataset
    Player = Struct.new(
      :id,
      :name,
      :experience,
      :country,
      :rank
    )

    Country = Struct.new(:id, :rank)

    attr_reader :nearby, :country, :world, :countries

    def initialize(api, player)
      super(api)

      @player = player

      @nearby = []
      @country = []
      @world = []
      @countries = []
    end

    def load
      @raw_data = @api.ranking(@player.profile.country)
      parse
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      list = [@nearby, @country, @world]
      list.each { |l| l.clear }
      list.each_with_index do |l, i|
        data[i].each do |record|
          l << Player.new(
            record[0].to_i,
            record[1],
            record[2].to_i,
            record[3].to_i,
            record[4].to_i
          )
        end
      end

      @countries.clear
      data[3].each do |record|
        @countries << Country.new(
          record[0].to_i,
          record[1].to_i
        )
      end
    end
  end
end
