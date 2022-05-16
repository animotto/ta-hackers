# frozen_string_literal: true

module Hackers
  ##
  # Missions list
  class MissionsList < Dataset
    include Enumerable

    Mission = Struct.new(
      :id,
      :giver_name,
      :name,
      :message_info,
      :goals,
      :x,
      :y,
      :country,
      :required_missions,
      :required_core_level,
      :reward_money,
      :reward_bitcoins,
      :message_completion,
      :message_news,
      :topology,
      :nodes,
      :additional_money,
      :additional_bitcoins,
      :group
    )

    def initialize(*)
      super

      @missions = []
    end

    def load
      @raw_data = @api.missions_list
      parse
    end

    def exist?(mission)
      @missions.any? { |m| m.id == mission }
    end

    def get(mission)
      @missions.detect { |m| m.id == mission }
    end

    def each(&block)
      @missions.each(&block)
    end

    private

    def parse
      data = Serializer.parseData(@raw_data)

      @missions.clear
      data[0].each do |record|
        @missions << Mission.new(
          record[0].to_i,
          record[1],
          Serializer.normalizeData(record[2]),
          record[3],
          Serializer.normalizeData(record[4]).split(','),
          record[5].to_i,
          record[6].to_i,
          record[7].to_i,
          Serializer.normalizeData(record[9]).split(','),
          record[12].to_i,
          record[13].to_i,
          record[14].to_i,
          Serializer.normalizeData(record[17]),
          Serializer.normalizeData(record[19]),
          Serializer.normalizeData(record[21]),
          Serializer.normalizeData(record[22]),
          record[24].to_i,
          record[25].to_i,
          record[28]
        )
      end
    end
  end
end
