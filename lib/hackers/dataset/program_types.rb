# frozen_string_literal: true

module Hackers
  module ProgramTypes
    ION_CANON = 3
    SHURIKEN = 4
    WORMS = 5
    BLASTER = 6
    SHOCK = 7
    DATA_LEECH = 8
    BATTERING_RAM = 9
    MANIAC = 10
    ICE_WALL = 11
    PROTECTOR = 12
    SENTRY = 13
    BLACK_ICE = 14
    GUARDIAN = 15
    CODE_GATE = 16
    TURRET = 17
    ACCESS = 18
    PORTAL = 19
    WRAITH = 20
    KRAKEN = 21
    AI_OFFENSIVE = 22
    AI_DEFENSIVE = 23
    AI_STEALTH = 24

    PROGRAMS = {
      ION_CANON => Programs::IonCanon,
      SHURIKEN => Programs::Shuriken,
      WORMS => Programs::Worms,
      BLASTER => Programs::Blaster,
      SHOCK => Programs::Shock,
      DATA_LEECH => Programs::DataLeech,
      BATTERING_RAM => Programs::BatteringRam,
      MANIAC => Programs::Maniac,
      ICE_WALL => Programs::IceWall,
      PROTECTOR => Programs::Protector,
      SENTRY => Programs::Sentry,
      BLACK_ICE => Programs::BlackIce,
      GUARDIAN => Programs::Guardian,
      CODE_GATE => Programs::CodeGate,
      TURRET => Programs::Turret,
      ACCESS => Programs::Access,
      PORTAL => Programs::Portal,
      WRAITH => Programs::Wraith,
      KRAKEN => Programs::Kraken,
      AI_OFFENSIVE => Programs::AIOffensive,
      AI_DEFENSIVE => Programs::AIDefensive,
      AI_STEALTH => Programs::AIStealth
    }.freeze

    ##
    # Returns program class by id
    def self.program(id)
      PROGRAMS[id]
    end

    ##
    # List
    class List < Dataset
      include Enumerable

      attr_reader :ion_canon, :shuriken, :worms, :blaster,
                  :shock, :data_leech, :battering_ram,
                  :maniac, :ice_wall, :protector, :sentry,
                  :black_ice, :guardian, :code_gate, :turret,
                  :access, :portal, :wraith, :kraken,
                  :ai_offensive, :ai_defensive, :ai_stealth

      def initialize(*)
        super

        @programs = []
      end

      def load
        @raw_data = @api.program_types
        parse
      end

      def exist?(type)
        @programs.any? { |p| p.type == type }
      end

      def each(&block)
        @programs.each(&block)
      end

      def get(type)
        @programs.detect { |p| p.type == type }
      end

      private

      def parse
        data = Serializer::Base.new(@raw_data)

        @programs.clear
        @programs << @ion_canon = IonCannon.new(data)
        @programs << @shuriken = Shuriken.new(data)
        @programs << @worms = Worms.new(data)
        @programs << @blaster = Blaster.new(data)
        @programs << @shock = Shock.new(data)
        @programs << @data_leech = DataLeech.new(data)
        @programs << @battering_ram = BatteringRam.new(data)
        @programs << @maniac = Maniac.new(data)
        @programs << @ice_wall = IceWall.new(data)
        @programs << @protector = Protector.new(data)
        @programs << @sentry = Sentry.new(data)
        @programs << @black_ice = BlackIce.new(data)
        @programs << @guardian = Guardian.new(data)
        @programs << @code_gate = CodeGate.new(data)
        @programs << @turret = Turret.new(data)
        @programs << @access = Access.new(data)
        @programs << @portal = Portal.new(data)
        @programs << @wraith = Wraith.new(data)
        @programs << @kraken = Kraken.new(data)
        @programs << @ai_offensive = AIOffensive.new(data)
        @programs << @ai_defensive = AIDefensive.new(data)
        @programs << @ai_stealth = AIStealth.new(data)
      end
    end

    ##
    # Type
    class Type
      def initialize(data)
        @data = data
      end

      def type
        self.class::ID
      end

      def levels
        records = @data.section(1).select { |r| r[1].to_i == type }
        records.map { |r| r[2].to_i }
      end

      def name
        record = find_record_general
        record[2]
      end

      def upgrade_cost(level)
        record = find_record_level(level)
        record[3].to_i
      end

      def experience_gained(level)
        record = find_record_level(level)
        record[4].to_i
      end

      def compilation_price(level)
        record = find_record_level(level)
        record[5].to_i
      end

      def compilation_time(level)
        record = find_record_level(level)
        record[6].to_i
      end

      def disk_space(level)
        record = find_record_level(level)
        record[7].to_i
      end

      def install_time(level)
        record = find_record_level(level)
        record[8].to_i / 10.0
      end

      def research_time(level)
        record = find_record_level(level)
        record[9].to_i
      end

      def required_evolver_level(level)
        record = find_record_level(level)
        record[17].to_i
      end

      private

      def find_record_general
        @data.section(0).detect { |r| r[0].to_i == type }
      end

      def find_record_level(level)
        @data.section(1).detect { |r| r[1].to_i == type && r[2].to_i == level }
      end
    end

    ##
    # Offensive
    class Offensive < Type
      def strength(level)
        record = find_record_level(level)
        record[11].to_i
      end

      def attack_speed(level)
        record = find_record_level(level)
        record[10].to_i / 10.0
      end
    end

    ##
    # Defensive
    class Defensive < Type
      def buffer(level)
        record = find_record_level(level)
        record[11].to_i
      end
    end

    ##
    # Stealth
    class Stealth < Type
      def visibility(level)
        record = find_record_level(level)
        record[13].to_i
      end
    end

    ##
    # AI
    class AI < Type
    end

    ##
    # Node
    class Node < Type
    end

    ##
    # Ion Canon
    class IonCannon < Offensive
      ID = ProgramTypes::ION_CANON
    end

    ##
    # Shuriken
    class Shuriken < Offensive
      ID = ProgramTypes::SHURIKEN
    end

    ##
    # Worms
    class Worms < Offensive
      ID = ProgramTypes::WORMS
    end

    ##
    # Blaster
    class Blaster < Offensive
      ID = ProgramTypes::BLASTER
    end

    ##
    # Shock
    class Shock < Offensive
      ID = ProgramTypes::SHOCK
    end

    ##
    # Battering Ram
    class BatteringRam < Offensive
      ID = ProgramTypes::BATTERING_RAM
    end

    ##
    # Maniac
    class Maniac < Offensive
      ID = ProgramTypes::MANIAC
    end

    ##
    # Kraken
    class Kraken < Offensive
      ID = ProgramTypes::KRAKEN
    end

    ##
    # Ice Wall
    class IceWall < Defensive
      ID = ProgramTypes::ICE_WALL
    end

    ##
    # Protector
    class Protector < Defensive
      ID = ProgramTypes::PROTECTOR
    end

    ##
    # Data Leech
    class DataLeech < Stealth
      ID = ProgramTypes::DATA_LEECH

      def download_boost(level)
        record = find_record_level(level)
        record[14].to_i
      end
    end

    ##
    # Access
    class Access < Stealth
      ID = ProgramTypes::ACCESS
    end

    ##
    # Portal
    class Portal < Stealth
      ID = ProgramTypes::PORTAL
    end

    ##
    # Wraith
    class Wraith < Stealth
      ID = ProgramTypes::WRAITH
    end

    ##
    # AI Offensive
    class AIOffensive < AI
      ID = ProgramTypes::AI_OFFENSIVE
    end

    ##
    # AI Defensive
    class AIDefensive < AI
      ID = ProgramTypes::AI_DEFENSIVE
    end

    ##
    # AI Stealth
    class AIStealth < AI
      ID = ProgramTypes::AI_STEALTH
    end

    ##
    # Sentry
    class Sentry < Node
      ID = ProgramTypes::SENTRY
    end

    ##
    # Black Ice
    class BlackIce < Node
      ID = ProgramTypes::BLACK_ICE
    end

    ##
    # Guardian
    class Guardian < Node
      ID = ProgramTypes::GUARDIAN
    end

    ##
    # Code Gate
    class CodeGate < Node
      ID = ProgramTypes::CODE_GATE
    end

    ##
    # Turret
    class Turret < Node
      ID = ProgramTypes::TURRET
    end
  end
end
