# frozen_string_literal: true

module Hackers
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
end
