# frozen_string_literal: true

module Hackers
  ##
  # Missions
  class Missions < Dataset
    include Enumerable

    AWAITS = 0
    FINISHED = 1
    REJECTED = 2

    attr_accessor :data

    def initialize(*)
      super

      @missions = []
    end

    def load
      @raw_data = @api.missions_log
      data = Serializer.parseData(@raw_data)
      @data = data[0]
      parse
    end

    def each(&block)
      @missions.each(&block)
    end

    def exist?(mission)
      @missions.any? { |m| m.id == mission }
    end

    def get(mission)
      @missions.detect { |m| m.id == mission }
    end

    def start(mission)
      @api.start_mission(mission)
    end

    def parse
      @missions.clear
      @data.each do |record|
        mission = Mission.new(@api)
        mission.parse(record)
        @missions << mission
      end
    end
  end

  ##
  # Mission
  class Mission
    attr_reader :id, :money, :bitcoins, :status,
                :datetime, :currencies

    def initialize(api)
      @api = api
    end

    def awaits?
      @status == AWAITS
    end

    def finished?
      @status == FINISHED
    end

    def rejected?
      @status == REJECTED
    end

    def reject
      @api.reject_mission(@id)
    end

    def parse(data)
      @id = data[1].to_i
      @money = data[2].to_i
      @bitcoins = data[3].to_i
      @status = data[4].to_i
      @datetime = data[5]
      @currencies = data[7]
    end
  end
end
