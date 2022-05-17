# frozen_string_literal: true

module Hackers
  ##
  # Rank list
  class RankList < Dataset
    include Enumerable

    TITLES = {
      1 => 'Noob',
      2 => 'Rookie',
      3 => 'Talent',
      4 => 'Skilled',
      5 => 'Experienced',
      6 => 'Advanced',
      7 => 'Senior',
      8 => 'Expert',
      9 => 'Veteran',
      10 => 'Master',
      11 => 'Elite'
    }.freeze

    Rank = Struct.new(
      :id,
      :rank_gain,
      :rank_maintain,
      :bonus_money,
      :bonus_bitcoins,
      :title
    )

    def initialize(*)
      super

      @ranks = []
    end

    def load
      @raw_data = @api.rank_list
      parse
    end

    def each(&block)
      @ranks.each(&block)
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      @ranks.clear
      data[0].each do |record|
        @ranks << Rank.new(
          record[0].to_i,
          record[1].to_i,
          record[2].to_i,
          record[3].to_i,
          record[4].to_i,
          TITLES[record[0].to_i]
        )
      end
    end
  end
end
