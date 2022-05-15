# frozen_string_literal: true

module Hackers
  module Programs
    ##
    # Programs
    class Program
      attr_reader :id, :type, :level, :amount, :timer

      def initialize(data)
        @data = data

        parse
      end

      private

      def parse
        @id = @data[0].to_i
        @type = @data[2].to_i
        @level = @data[3].to_i
        @amount = @data[4].to_i
        @timer = @data[5].to_i
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
