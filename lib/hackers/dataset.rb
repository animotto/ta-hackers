# frozen_string_literal: true

module Hackers
  ##
  # Data set
  class Dataset
    attr_reader :raw_data

    def initialize(api)
      @api = api
    end

    def loaded?
      !@raw_data.nil?
    end

    def load; end
  end

  ##
  # Application settings
  class AppSettings < Dataset
    def load
      @raw_data = @api.app_settings
    end

    def each(&block)
      @raw_data.keys.each(&block)
    end

    def get(key)
      @raw_data[key]
    end
  end

  ##
  # Language translations
  class LanguageTranslations < Dataset
    def load
      @raw_data = @api.language_translations
    end

    def get(key)
      @raw_data[key]
    end

    def each(&block)
      @raw_data.keys.each(&block)
    end
  end

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

  ##
  # Program types
  class ProgramTypes < Dataset
    def load
      @raw_data = @api.program_types
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

    def name(type)
      @raw_data[type]['name']
    end

    def cost(type, level)
      @raw_data[type]['levels'][level]['cost']
    end

    def experience(type, level)
      @raw_data[type]['levels'][level]['experience']
    end

    def price(type, level)
      @raw_data[type]['levels'][level]['price']
    end

    def compile(type, level)
      @raw_data[type]['levels'][level]['compile']
    end

    def disk(type, level)
      @raw_data[type]['levels'][level]['disk']
    end

    def install(type, level)
      @raw_data[type]['levels'][level]['install']
    end

    def upgrade(type, level)
      @raw_data[type]['levels'][level]['upgrade']
    end

    def rate(type, level)
      @raw_data[type]['levels'][level]['rate']
    end

    def strength(type, level)
      @raw_data[type]['levels'][level]['strength']
    end

    def evolver(type, level)
      @raw_data[type]['levels'][level]['evolver']
    end
  end

  ##
  # Missions list
  class MissionsList < Dataset
    def load
      @raw_data = @api.missions_list
    end

    def exist?(mission)
      @raw_data.key?(mission)
    end

    def each(&block)
      @raw_data.keys.each(&block)
    end

    def name(mission)
      @raw_data[mission]['name']
    end

    def group(mission)
      @raw_data[mission]['group']
    end

    def target(mission)
      @raw_data[mission]['target']
    end

    def x(mission)
      @raw_data[mission]['x']
    end

    def y(mission)
      @raw_data[mission]['y']
    end

    def country(mission)
      @raw_data[mission]['country']
    end

    def money(mission)
      @raw_data[mission]['money']
    end

    def bitcoins(mission)
      @raw_data[mission]['bitcoins']
    end

    def required_mission(mission)
      @raw_data[mission]['requirements']['mission']
    end

    def required_core(mission)
      @raw_data[mission]['requirements']['core']
    end

    def goals(mission)
      @raw_data[mission]['goals']
    end

    def reward_money(mission)
      @raw_data[mission]['reward']['money']
    end

    def reward_bitcoins(mission)
      @raw_data[mission]['reward']['bitcoins']
    end

    def message_begin(mission)
      @raw_data[mission]['messages']['begin']
    end

    def message_end(mission)
      @raw_data[mission]['messages']['end']
    end

    def message_news(mission)
      @raw_data[mission]['messages']['news']
    end
  end

  ##
  # Skin types
  class SkinTypes < Dataset
    def load
      @raw_data = @api.skin_types
    end

    def exist?(type)
      @raw_data.key?(type)
    end

    def each(&block)
      @raw_data.keys.each(&block)
    end

    def name(type)
      @raw_data[type]['name']
    end

    def price(type)
      @raw_data[type]['price']
    end

    def rank(type)
      @raw_data[type]['rank']
    end
  end
end
