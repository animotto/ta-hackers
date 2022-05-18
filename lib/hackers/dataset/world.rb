# frozen_string_literal: true

module Hackers
  module World
    ##
    # World
    class World < Dataset
      BestPlayer = Struct.new(
        :id,
        :name,
        :experience,
        :country,
        :rank
      )

      attr_reader :targets, :bonuses, :goals, :best_player,
                  :fight_map

      def initialize(api, game)
        super(api)

        @game = game

        @targets = Targets.new(@api, @game, self)
        @bonuses = Bonuses.new(@api)
        @goals = Goals.new(@api, @game)
        @fight_map = FightMap.new
      end

      def load
        @raw_data = @api.world(@game.player.profile.country)
        parse
      end

      private

      def parse
        data = Serializer.parseData(@raw_data)

        @targets.parse(data[0], data[10..])
        @bonuses.parse(data[1])
        @game.player.profile.money = data.dig(2, 0, 0).to_i
        @goals.parse(data[4])
        @best_player = BestPlayer.new(
          data.dig(6, 0, 0).to_i,
          data.dig(6, 0, 1),
          data.dig(6, 0, 2).to_i,
          data.dig(6, 0, 3).to_i,
          data.dig(6, 0, 4).to_i
        )
        @fight_map.parse(data[9])
      end
    end

    ##
    # Targets
    class Targets
      include Enumerable

      Target = Struct.new(
        :id,
        :name,
        :experience,
        :x,
        :y,
        :country,
        :skin,
        :profile,
        :net
      )

      def initialize(api, game, world)
        @api = api
        @game = game
        @world = world

        @targets = []
      end

      def each(&block)
        @targets.each(&block)
      end

      def empty?
        @targets.empty?
      end

      def new
        raw_data = @api.new_targets
        data = Serializer.parseData(raw_data)

        parse(data[0], [])
        @world.bonuses.parse(data[1])
        @game.player.profile.money = data.dig(2, 0, 0).to_i
        @world.goals.parse(data[4])
      end

      def parse(data_targets, data_players)
        @targets.clear
        i = 0
        data_targets.each do |record|
          @targets << Target.new(
            record[0].to_i,
            record[1],
            record[2].to_i,
            record[3].to_i,
            record[4].to_i,
            record[5].to_i,
            record[6].to_i,
            Network::Profile.new,
            Network::Network.new(@api, @game.player)
          )

          unless data_players.empty?
            @targets.last.profile.parse(data_players.dig(i, 0))
            @targets.last.net.parse(data_players.dig(i + 1), [])
            i += 2
          end
        end
      end
    end

    ##
    # Bonuses
    class Bonuses
      include Enumerable

      def initialize(api)
        @api = api

        @bonuses = []
      end

      def each(&block)
        @bonuses.each(&block)
      end

      def exist?(bonus)
        @bonuses.any? { |b| b.id == bonus }
      end

      def empty?
        @bonuses.empty?
      end

      def get(bonus)
        @bonuses.detect { |b| b.id == bonus }
      end

      def remove(bonus)
        @bonuses.delete_if { |b| b.id == bonus }
      end

      def parse(data)
        return if data.nil?

        @bonuses.clear
        data.each do |record|
          @bonuses << Bonus.new(
            @api,
            self,
            record[0].to_i,
            record[2].to_i,
            record[3].to_i,
            record[4].to_i
          )
        end
      end
    end

    ##
    # Bonus
    class Bonus
      attr_reader :id, :amount, :x, :y

      def initialize(api, bonuses, id, amount, x, y)
        @api = api
        @bonuses = bonuses
        @id = id
        @amount = amount
        @x = x
        @y = y
      end

      def collect
        @api.collect_bonus(@id)
        @bonuses.remove(@id)
      end
    end

    ##
    # Goals
    class Goals
      include Enumerable

      def initialize(api, game)
        @api = api
        @game = game

        @goals = []
      end

      def each(&block)
        @goals.each(&block)
      end

      def exist?(goal)
        @goals.any? { |g| g.id == goal }
      end

      def empty?
        @goals.empty?
      end

      def get(goal)
        @goals.detect { |g| g.id == goal }
      end

      def remove(goal)
        @goals.delete_if { |g| g.id == goal }
      end

      def parse(data)
        return if data.nil?

        @goals.clear
        data.each do |record|
          @goals << Goal.new(
            @api,
            @game,
            self,
            record[0].to_i,
            record[1],
            record[2].to_i,
            record[3].to_i
          )
        end
      end
    end

    ##
    # Goal
    class Goal
      attr_reader :id, :name, :type, :finished

      def initialize(api, game, goals, id, name, type, finished)
        @api = api
        @game = game
        @goals = goals
        @id = id
        @name = name
        @type = type
        @finished = finished
      end

      def update(finished)
        raw_data = @api.update_goal(@id, finished)
        data = Serializer.parseData(raw_data)

        @game.player.profile.credits = data.dig(0, 0, 1).to_i
        @goals.remove(@id) if data.dig(0, 0, 0) == 'finished'
      end

      def reject
        @api.reject_goal(@id)
        @goals.remove(@id)
      end
    end

    ##
    # Fight map
    class FightMap
      include Enumerable

      Item = Struct.new(
        :timestamp,
        :x1,
        :y1,
        :x2,
        :y3
      )

      def initialize
        @fights = []
      end

      def each(&block)
        @fights.each(&block)
      end

      def parse(data)
        @fights.clear
        data.each do |record|
          @fights << Item.new(
            record[0].to_i,
            record[1].to_i,
            record[2].to_i,
            record[3].to_i,
            record[4].to_i
          )
        end
      end
    end
  end
end
