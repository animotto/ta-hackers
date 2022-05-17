# frozen_string_literal: true

module Hackers
  module Programs
    ##
    # Program
    class Program
      attr_reader :id, :type, :level, :timer

      attr_accessor :amount

      def initialize(api, programs, id = 0, type = 0, level = 0, amount= 0, timer = 0)
        @api = api
        @programs = api
        @id = id
        @type = type
        @level = level
        @amount = amount
        @timer = timer
      end

      def upgrade
        @api.upgrade_program(@id)
      end

      def finish
        @api.finish_program(@id)
      end

      def parse(data)
        @id = data[0].to_i
        @type = data[2].to_i
        @level = data[3].to_i
        @amount = data[4].to_i
        @timer = data[5].to_i
      end
    end

    ##
    # Offensive
    class Offensive < Program
    end

    ##
    # Defensive
    class Defensive < Program
    end

    ##
    # Stealth
    class Stealth < Program
    end

    ##
    # AI
    class AI < Program
      def revive
        raw_data = @api.revive_ai(@id)
        data = Serializer.parseData(raw_data)

        @programs.parse(data[0])
      end
    end

    ##
    # Node
    class Node < Program
    end

    ##
    # Ion Canon
    class IonCanon < Offensive
    end

    ##
    # Shuriken
    class Shuriken < Offensive
    end

    ##
    # Worms
    class Worms < Offensive
    end

    ##
    # Blaster
    class Blaster < Offensive
    end

    ##
    # Shock
    class Shock < Offensive
    end

    ##
    # Battering Ram
    class BatteringRam < Offensive
    end

    ##
    # Maniac
    class Maniac < Offensive
    end

    ##
    # Kraken
    class Kraken < Offensive
    end

    ##
    # Ice Wall
    class IceWall < Defensive
    end

    ##
    # Protector
    class Protector < Defensive
    end

    ##
    # Data Leech
    class DataLeech < Stealth
    end

    ##
    # Access
    class Access < Stealth
    end

    ##
    # Portal
    class Portal < Stealth
    end

    ##
    # Wraith
    class Wraith < Stealth
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

    ##
    # Sentry
    class Sentry < Node
    end

    ##
    # Black Ice
    class BlackIce < Node
    end

    ##
    # Guardian
    class Guardian < Node
    end

    ##
    # Code Gate
    class CodeGate < Node
    end

    ##
    # Turret
    class Turret < Node
    end
  end
end
