# frozen_string_literal: true

module Hackers
  module NodeTypes
    CORE = 7
    CONNECTION = 8
    FARM = 11
    DATABASE = 12
    BITCOIN_MINE = 13
    BITCOIN_MIXER = 14
    SENTRY = 15
    BLACK_ICE = 16
    GUARDIAN = 17
    SCANNER = 18
    CODE_GATE = 21
    COMPILER = 22
    EVOLVER = 23
    LIBRARY = 24
    TURRENT = 26
    AI_OFFENSIVE = 27
    AI_DEFENSIVE = 28
    AI_STEALTH = 29

    NODES = {
      CORE => Nodes::Core,
      CONNECTION => Nodes::Connection,
      FARM => Nodes::Farm,
      DATABASE => Nodes::Database,
      BITCOIN_MINE => Nodes::BitcoinMine,
      BITCOIN_MIXER => Nodes::BitcoinMixer,
      SENTRY => Nodes::Sentry,
      BLACK_ICE => Nodes::BlackIce,
      GUARDIAN => Nodes::Guardian,
      SCANNER => Nodes::Scanner,
      CODE_GATE => Nodes::CodeGate,
      COMPILER => Nodes::Compiler,
      EVOLVER => Nodes::Evolver,
      LIBRARY => Nodes::Library,
      TURRENT => Nodes::Turret,
      AI_OFFENSIVE => Nodes::AIOffensive,
      AI_DEFENSIVE => Nodes::AIDefensive,
      AI_STEALTH => Nodes::AIStealth
    }.freeze

    ##
    # Returns node class by id
    def self.node(id)
      NODES[id]
    end

    ##
    # List
    class List < Dataset

      attr_reader :core, :connection, :farm, :database,
        :bitcoin_mine, :bitcoin_mixer, :sentry,
        :black_ice, :guardian, :scanner, :code_gate,
        :compiler, :evolver, :library, :turret,
        :ai_offensive, :ai_defensive, :ai_stealth

      def initialize(*)
        super

        @nodes = []
      end

      def load
        @raw_data = @api.node_types
        parse
      end

      def exist?(type)
        @nodes.any? { |n| n.type == type }
      end

      def each(&block)
        @nodes.each(&block)
      end

      def get(type)
        @nodes.detect { |n| n.type == type }
      end

      private

      def parse
        data = Serializer.parseData(@raw_data)

        @nodes.clear
        @nodes << @core = Core.new(data)
        @nodes << @connection = Connection.new(data)
        @nodes << @farm = Farm.new(data)
        @nodes << @database = Database.new(data)
        @nodes << @bitcoin_mine = BitcoinMine.new(data)
        @nodes << @bitcoin_mixer = BitcoinMixer.new(data)
        @nodes << @sentry = Sentry.new(data)
        @nodes << @black_ice = BlackIce.new(data)
        @nodes << @guardian = Guardian.new(data)
        @nodes << @scanner = Scanner.new(data)
        @nodes << @code_gate = CodeGate.new(data)
        @nodes << @compiler = Compiler.new(data)
        @nodes << @evolver = Evolver.new(data)
        @nodes << @library = Library.new(data)
        @nodes << @turret = Turret.new(data)
        @nodes << @ai_offensive = AIOffensive.new(data)
        @nodes << @ai_defensive = AIDefensive.new(data)
        @nodes << @ai_stealth = AIStealth.new(data)
      end
    end

    ##
    # Type
    class Type
      attr_reader :data

      def initialize(data)
        @data = data
      end

      def type
        self.class::TYPE
      end

      def name
        record = find_record_general
        record[1]
      end

      def levels
        records = @data[1].select { |r| r[1].to_i == type }
        records.map { |r| r[2].to_i }
      end

      def upgrade_cost(level)
        record = find_record_level(level)
        record[3].to_i
      end

      def upgrade_currency(level)
        record = find_record_level(level)
        record[4].to_i
      end

      def required_core_level(level)
        record = find_record_level(level)
        record[5].to_i
      end

      def experience_gained(level)
        record = find_record_level(level)
        record[6].to_i
      end

      def completion_time(level)
        record = find_record_level(level)
        record[7].to_i
      end

      def node_connections(level)
        record = find_record_level(level)
        record[8].to_i
      end

      def program_slots(level)
        record = find_record_level(level)
        record[9].to_i
      end

      def firewall(level)
        record = find_record_level(level)
        record[10].to_i
      end

      def limit(core_level)
        record = find_record_limit(core_level)
        record[3].to_i
      end

      private

      def find_record_general
        @data[0].detect { |r| r[0].to_i == type }
      end

      def find_record_level(level)
        @data[1].detect { |r| r[1].to_i == type && r[2].to_i == level }
      end

      def find_record_limit(core_level)
        @data[2].detect { |r| r[1].to_i == type && r[2].to_i == core_level }
      end
    end

    ##
    # Business
    class Business < Type
    end

    ##
    # Production
    class Production < Business
      def production_currency(level)
        record = find_record_level(level)
        record[13].to_i
      end

      def production_limit(level)
        record = find_record_level(level)
        record[14].to_i
      end

      def production_speed(level)
        record = find_record_level(level)
        record[15].to_i
      end
    end

    ##
    # Security
    class Security < Type
    end

    ##
    # Hacking node
    class Hacking < Type
    end

    ##
    # AI node
    class AI < Type
    end

    ##
    # Core
    class Core < Type
      TYPE = NodeTypes::CORE

      alias :min_connections :required_core_level

      def max_nodes(level)
        record = find_record_level(level)
        record[13].to_i
      end

      def capacity_money(level)
        record = find_record_level(level)
        record[14].to_i
      end

      def capacity_bitcoins(level)
        record = find_record_level(level)
        record[15].to_i
      end
    end

    ##
    # Connection
    class Connection < Type
      TYPE = NodeTypes::CONNECTION
    end

    ##
    # Farm
    class Farm < Production
      TYPE = NodeTypes::FARM

      def exfiltration_amount(level)
        record = find_record_level(level)
        record[16].to_i
      end
    end

    ##
    # Database
    class Database < Business
      TYPE = NodeTypes::DATABASE

      def capacity(level)
        record = find_record_level(level)
        record[14].to_i
      end

      def exfiltration_amount(level)
        record = find_record_level(level)
        record[15].to_i
      end
    end

    ##
    # Bitcoin Mine
    class BitcoinMine < Production
      TYPE = NodeTypes::BITCOIN_MINE

      def exfiltration_amount(level)
        record = find_record_level(level)
        record[16].to_i
      end
    end

    ##
    # Bitcoin Mixer
    class BitcoinMixer < Business
      TYPE = NodeTypes::BITCOIN_MIXER

      def capacity(level)
        record = find_record_level(level)
        record[14].to_i
      end

      def exfiltration_amount(level)
        record = find_record_level(level)
        record[15].to_i
      end
    end

    ##
    # Sentry
    class Sentry < Security
      TYPE = NodeTypes::SENTRY
    end

    ##
    # Black Ice
    class BlackIce < Security
      TYPE = NodeTypes::BLACK_ICE
    end

    ##
    # Guardian
    class Guardian < Security
      TYPE = NodeTypes::GUARDIAN
    end

    ##
    # Scanner
    class Scanner < Security
      TYPE = NodeTypes::SCANNER
    end

    ##
    # CodeGate
    class CodeGate < Security
      TYPE = NodeTypes::CODE_GATE
    end

    ##
    # Compiler
    class Compiler < Hacking
      TYPE = NodeTypes::COMPILER
    end

    ##
    # Evolver
    class Evolver < Hacking
      TYPE = NodeTypes::EVOLVER
    end

    ##
    # Library
    class Library < Hacking
      TYPE = NodeTypes::LIBRARY
    end

    ##
    # Turret
    class Turret < Security
      TYPE = NodeTypes::TURRENT
    end

    ##
    # AIOffensive
    class AIOffensive < AI
      TYPE = NodeTypes::AI_OFFENSIVE
    end

    ##
    # AIDefensive
    class AIDefensive < AI
      TYPE = NodeTypes::AI_DEFENSIVE
    end

    ##
    # AIStealth
    class AIStealth < AI
      TYPE = NodeTypes::AI_STEALTH
    end
  end
end
