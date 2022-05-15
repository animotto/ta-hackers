# frozen_string_literal: true

module Hackers
  module Nodes
    ##
    # Node
    class Node
      attr_reader :id, :type, :level, :timer, :builders,
                  :x, :y, :z, :relations

      def initialize(data, topology)
        @data = data
        @topology = topology

        parse
      end

      private

      def parse
        @id = @data[0].to_i
        @type = @data[2].to_i
        @level = @data[3].to_i
        @timer = @data[4].to_i
        @builders = @data.dig(5).to_i

        @relations = @topology[@id][:rels]
        @x = @topology[@id][:x]
        @y = @topology[@id][:y]
        @z = @topology[@id][:z]
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
    # Core
    class Core < Business
    end

    ##
    # Connection
    class Connection < Business
    end

    ##
    # Farm
    class Farm < Business
    end

    ##
    # Database
    class Database < Business
    end

    ##
    # Bitcoin Mine
    class BitcoinMine < Business
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
