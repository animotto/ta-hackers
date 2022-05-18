# frozen_string_literal: true

module Hackers
  module Nodes
    ##
    # Node
    class Node
      attr_accessor :id, :type, :level, :timer, :builders,
                    :x, :y, :z, :relations

      def initialize(api, player)
        @api = api
        @player = player

        @x = 0
        @y = 0
        @z = 0
        @relations = []
      end

      def upgrade
        @api.upgrade_node(@id)
      end

      def finish
        @api.finish_node(@id)
      end

      def cancel
        @api.cancel_node(@id)
      end

      def set_builders(amount)
        @api.node_set_builders(@id, amount)
      end

      def create(type)
        net = @player.net
        node = NodeTypes.node(type)
        node = node.new(@api, @player)
        net.add(node)
        connect(node)

        raw_data = @api.create_node_update_net(type, net.topology.generate)
        data = Serializer.parseData(raw_data)

        node.id = data.dig(0, 0, 0).to_i
        net.update
      end

      def delete
        net = @player.net
        net.each do |node|
          node.relations.delete_if { |n| n.id == @id }
        end
        net.delete(self)
        @api.delete_node_update_net(@id, net.topology.generate)
      end

      def move(x, y, z)
        @x = x
        @y = y
        @z = z
      end

      def connect(node)
        return if @relations.include?(node)

        @relations << node
      end

      def disconnect(node)
        @relations.delete_if { |r| r.id == node.id }
      end

      def parse(data)
        @id = data[0].to_i
        @type = data[2].to_i
        @level = data[3].to_i
        @timer = data[4].to_i
        @builders = data.dig(5).to_i
      end
    end

    ##
    # Business
    class Business < Node
    end

    ##
    # Hacking
    class Hacking < Node
    end

    ##
    # Security
    class Security < Node
    end

    ##
    # AI
    class AI < Node
    end

    ##
    # Production
    class Production < Business
      def collect
        raw_data = @api.collect_node(@id)
        data = Serializer.parseData(raw_data)
      end
    end

    ##
    # Core
    class Core < Business
    end

    ##
    # Connection
    class Connection < Business
    end

    ##
    # Farm
    class Farm < Production
      def collect
        data = super
        @player.profile.money = data.dig(0, 0, 1).to_i
      end
    end

    ##
    # Database
    class Database < Business
    end

    ##
    # Bitcoin Mine
    class BitcoinMine < Production
      def collect
        data = super
        @player.profile.bitcoins = data.dig(0, 0, 1).to_i
      end
    end

    ##
    # Bitcoin Mixer
    class BitcoinMixer < Business
    end

    ##
    # Sentry
    class Sentry < Security
    end

    ##
    # Black Ice
    class BlackIce < Security
    end

    ##
    # Guardian
    class Guardian < Security
    end

    ##
    # Scanner
    class Scanner < Security
    end

    ##
    # Code Gate
    class CodeGate < Security
    end

    ##
    # Turret
    class Turret < Security
    end

    ##
    # Compiler
    class Compiler < Hacking
    end

    ##
    # Evolver
    class Evolver < Hacking
    end

    ##
    # Library
    class Library < Hacking
    end

    ##
    # AI Offensive
    class AIOffensive < AI
    end

    ##
    # AI Defensive
    class AIDefensive < AI
    end

    ##
    # AI Stealth
    class AIStealth < AI
    end
  end
end
