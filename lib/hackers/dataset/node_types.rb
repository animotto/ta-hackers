# frozen_string_literal: true

module Hackers
  ##
  # Node types
  class NodeTypes < Dataset
    PRODUCTION_TITLE = 'CurrencyProduction'

    def load
      @raw_data = @api.node_types
    end

    def exist?(type)
      @raw_data.key?(type)
    end

    def each(&block)
      @raw_data.keys.each(&block)
    end

    def levels(type)
      @raw_data[type]['levels'].keys
    end

    def production?(type)
      @raw_data[type]['titles'][0] == PRODUCTION_TITLE
    end

    def name(type)
      @raw_data[type]['name']
    end

    def cost(type, level)
      @raw_data[type]['levels'][level]['cost']
    end

    def core(type, level)
      @raw_data[type]['levels'][level]['core']
    end

    def experience(type, level)
      @raw_data[type]['levels'][level]['experience']
    end

    def upgrade(type, level)
      @raw_data[type]['levels'][level]['upgrade']
    end

    def connections(type, level)
      @raw_data[type]['levels'][level]['connections']
    end

    def slots(type, level)
      @raw_data[type]['levels'][level]['slots']
    end

    def firewall(type, level)
      @raw_data[type]['levels'][level]['firewall']
    end

    def limit(type, level)
      @raw_data[type]['limits'][level]
    end

    def data(type, level)
      @raw_data[type]['levels'][level]['data']
    end
  end
end
