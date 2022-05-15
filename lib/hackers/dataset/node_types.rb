# frozen_string_literal: true

module Hackers
  ##
  # Node types
  class NodeTypes < Dataset
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

      @nodes << @core = NodeTypeCore.new(data)
      @nodes << @connection = NodeTypeConnection.new(data)
      @nodes << @farm = NodeTypeFarm.new(data)
      @nodes << @database = NodeTypeDatabase.new(data)
      @nodes << @bitcoin_mine = NodeTypeBitcoinMine.new(data)
      @nodes << @bitcoin_mixer = NodeTypeBitcoinMixer.new(data)
      @nodes << @sentry = NodeTypeSentry.new(data)
      @nodes << @black_ice = NodeTypeBlackIce.new(data)
      @nodes << @guardian = NodeTypeGuardian.new(data)
      @nodes << @scanner = NodeTypeScanner.new(data)
      @nodes << @code_gate = NodeTypeCodeGate.new(data)
      @nodes << @compiler = NodeTypeCompiler.new(data)
      @nodes << @evolver = NodeTypeEvolver.new(data)
      @nodes << @library = NodeTypeLibrary.new(data)
      @nodes << @turret = NodeTypeTurret.new(data)
      @nodes << @ai_offensive = NodeTypeAIOffensive.new(data)
      @nodes << @ai_defensive = NodeTypeAIDefensive.new(data)
      @nodes << @ai_stealth = NodeTypeAIStealth.new(data)
    end
  end

  ##
  # Node type
  class NodeType
    PRODUCTION_CURRENCY = 'CurrencyProduction'

    attr_reader :data

    def initialize(data)
      @data = data
    end

    def type
      self.class::TYPE
    end

    def production?
      record = find_record_general
      record[2] == PRODUCTION_CURRENCY
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
  # Business node
  class BusinessNode < NodeType
  end

  ##
  # Production node
  class ProductionNode < BusinessNode
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
  # Security node
  class SecurityNode < NodeType
  end

  ##
  # Hacking node
  class HackingNode < NodeType
  end

  ##
  # AI node
  class AINode < NodeType
  end

  ##
  # Node type Core
  class NodeTypeCore < NodeType
    TYPE = NodeTypes::CORE

    alias :min_connections :required_core_level

    def max_nodes(level)
      record = find_record_level(level)
      record[13].to_i
    end
  end

  ##
  # Node type Connection
  class NodeTypeConnection < NodeType
    TYPE = NodeTypes::CONNECTION
  end

  ##
  # Node type Farm
  class NodeTypeFarm < ProductionNode
    TYPE = NodeTypes::FARM

    def exfiltration_amount(level)
      record = find_record_level(level)
      record[16].to_i
    end
  end

  ##
  # Node type Database
  class NodeTypeDatabase < BusinessNode
    TYPE = NodeTypes::DATABASE

    def exfiltration_amount(level)
      record = find_record_level(level)
      record[15].to_i
    end
  end

  ##
  # Node type Bitcoin Mine
  class NodeTypeBitcoinMine < ProductionNode
    TYPE = NodeTypes::BITCOIN_MINE

    def exfiltration_amount(level)
      record = find_record_level(level)
      record[16].to_i
    end
  end

  ##
  # Node type Bitcoin Mixer
  class NodeTypeBitcoinMixer < BusinessNode
    TYPE = NodeTypes::BITCOIN_MIXER

    def exfiltration_amount(level)
      record = find_record_level(level)
      record[15].to_i
    end
  end

  ##
  # Node type Sentry
  class NodeTypeSentry < SecurityNode
    TYPE = NodeTypes::SENTRY
  end

  ##
  # Node type Black Ice
  class NodeTypeBlackIce < SecurityNode
    TYPE = NodeTypes::BLACK_ICE
  end

  ##
  # Node type Guardian
  class NodeTypeGuardian < SecurityNode
    TYPE = NodeTypes::GUARDIAN
  end

  ##
  # Node type Scanner
  class NodeTypeScanner < SecurityNode
    TYPE = NodeTypes::SCANNER
  end

  ##
  # Node type CodeGate
  class NodeTypeCodeGate < SecurityNode
    TYPE = NodeTypes::CODE_GATE
  end

  ##
  # Node type Compiler
  class NodeTypeCompiler < HackingNode
    TYPE = NodeTypes::COMPILER
  end

  ##
  # Node type Evolver
  class NodeTypeEvolver < HackingNode
    TYPE = NodeTypes::EVOLVER
  end

  ##
  # Node type Library
  class NodeTypeLibrary < HackingNode
    TYPE = NodeTypes::LIBRARY
  end

  ##
  # Node type Turret
  class NodeTypeTurret < SecurityNode
    TYPE = NodeTypes::TURRENT
  end

  ##
  # Node type AIOffensive
  class NodeTypeAIOffensive < AINode
    TYPE = NodeTypes::AI_OFFENSIVE
  end

  ##
  # Node type AIDefensive
  class NodeTypeAIDefensive < AINode
    TYPE = NodeTypes::AI_DEFENSIVE
  end

  ##
  # Node type AIStealth
  class NodeTypeAIStealth < AINode
    TYPE = NodeTypes::AI_STEALTH
  end
end
