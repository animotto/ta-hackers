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

    def initialize(api, player, id = nil)
      super(api)

      @player = player
      @id = id

      @missions = []
    end

    def load
      id = @id.nil? ? @api.id : @id
      @raw_data = @api.missions_log(id)
      data = Serializer.parseData(@raw_data)
      @data = data[0]
      parse
    end

    def each(&block)
      @missions.each(&block)
    end

    def empty?
      @missions.empty?
    end

    def exist?(mission)
      @missions.any? { |m| m.id == mission }
    end

    def get(mission)
      @missions.detect { |m| m.id == mission }
    end

    ##
    # TODO: Local objects syncrhonization - we need to add the mission to the list
    def start(mission)
      @api.start_mission(mission)
    end

    def parse
      return if @data.nil?

      @missions.clear
      @data.each do |record|
        mission = Mission.new(@api, @player)
        mission.parse(record)
        @missions << mission
      end
    end
  end

  ##
  # Mission
  class Mission
    Currency = Struct.new(:node, :amount)

    attr_reader :id, :status, :datetime, :currencies,
                :net, :programs

    attr_accessor :money, :bitcoins

    def initialize(api, player)
      @api = api
      @player = player

      @net = Network::Network.new(@api, @player)
      @programs = Network::Programs.new(@api)
      @currencies = []
    end

    def awaits?
      @status == Missions::AWAITS
    end

    def finished?
      @status == Missions::FINISHED
    end

    def rejected?
      @status == Missions::REJECTED
    end

    def finish
      @status = Missions::FINISHED
    end

    def reject
      @api.reject_mission(@id)
    end

    def attack
      raw_data = @api.attack_mission(@id)
      data = Serializer.parseData(raw_data)

      net_data = Serializer.normalizeData(data.dig(0, 0, 0))
      net_data = Serializer.parseData(net_data)
      @net.parse(
        net_data[0],
        data.dig(1, 0, 0)
      )

      @programs.parse(data[3])
    end

    def update
      currencies = @currencies.map { |c| [c.node, c.amount].join('X') }.join('Y')

      @api.update_mission(
        @id,
        @money,
        @bitcoins,
        @status,
        currencies,
        @programs.generate
      )
    end

    def parse(data)
      @id = data[1].to_i
      @money = data[2].to_i
      @bitcoins = data[3].to_i
      @status = data[4].to_i
      @datetime = data[5]

      unless data[7].nil?
        @currencies.clear
        currencies = data[7].split('Y')
        currencies.each do |currency|
          node, amount = currency.split('X')
          @currencies << Currency.new(
            node.to_i,
            amount.to_i
          )
        end
      end
    end
  end
end
