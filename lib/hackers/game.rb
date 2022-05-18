# frozen_string_literal: true

module Hackers
  ##
  # Game API implementation
  class Game
    attr_reader :api, :app_settings, :node_types,
                :language_translations, :program_types,
                :missions_list, :skin_types, :player,
                :chat, :hints_list, :experience_list,
                :builders_list, :goal_types, :shield_types,
                :rank_list, :countries_list, :world,
                :missions, :news_list

    attr_accessor :config

    def initialize(config)
      @config = config

      api_config = {}
      api_config[:host] = @config['host'] if @config.key?('host')
      api_config[:port] = @config['port'] if @config.key?('port')
      api_config[:ssl] = @config.key?('ssl')
      api_config[:path] = @config['url'] if @config.key?('url')
      api_config[:salt] = @config['salt'] if @config.key?('salt')
      api_config[:version] = @config['version'] if @config.key?('version')
      api_config[:language] = @config['language'] if @config.key?('language')
      api_config[:platform] = @config['platform'] if @config.key?('platform')

      @api = API.new(**api_config)
      @api.id = @config['id']
      @api.password = @config['password']

      @countries_list = CountriesList.new(@api)
      @app_settings = AppSettings.new(@api)
      @language_translations = LanguageTranslations.new(@api)
      @node_types = NodeTypes::List.new(@api)
      @program_types = ProgramTypes::List.new(@api)
      @missions_list = MissionsList.new(@api)
      @skin_types = SkinTypes.new(@api)
      @hints_list = HintsList.new(@api)
      @experience_list = ExperienceList.new(@api)
      @builders_list = BuildersList.new(@api)
      @goal_types = GoalTypes.new(@api)
      @shield_types = ShieldTypes.new(@api)
      @rank_list = RankList.new(@api)
      @player = Network::Player.new(@api)
      @world = World::World.new(@api, self)
      @chat = Chat.new(@api)
      @missions = Missions.new(@api)
      @news_list = NewsList.new(@api)
    end

    ##
    # Returns true if there is an API session id
    def connected?
      @api.sid?
    end

    ##
    # Authenticates by id and password
    def auth
      raw_data = @api.auth
      data = Serializer.parseData(raw_data)

      @player.tutorial = data.dig(0, 0, 2).to_i
      @api.sid = data.dig(0, 0, 3)
      @player.profile.rank = data.dig(0, 0, 4).to_i
      @player.profile.experience = data.dig(0, 0, 5).to_i

      @missions.data = data[2]
      @missions.parse
    end

    ##
    # Attacks target in test mode
    def attack_test(id)
      target = Network::Target.new(@api)
      target.attack_test(id)
      target
    end

    ##
    # Buys a skin
    def buy_skin(skin)
      @api.buy_skin(skin)
    end

    ##
    # Buys a shield
    def buy_shield(shield)
      @api.buy_shield(shield)
    end

    ##
    # Buys a builder
    def buy_builder
      @api.buy_builder
    end

    ##
    # Buys a money
    def buy_money(perc)
      raw_data = @api.buy_currency(Network::CURRENCY_MONEY, perc)
      data = Serializer.parseData(raw_data)

      @player.profile.credits = data.dig(0, 0, 0)
      @player.profile.money = data.dig(0, 0, 1)
    end

    ##
    # Buys a bitcoins
    def buy_bitcoins(perc)
      raw_data = @api.buy_currency(Network::CURRENCY_BITCOINS, perc)
      data = Serializer.parseData(raw_data)

      @player.profile.credits = data.dig(0, 0, 0)
      @player.profile.bitcoins = data.dig(0, 0, 1)
    end

    ##
    # Creates a new account
    def create_player
      raw_data = @api.create_player
      data = Serializer.parseData(raw_data)

      Account.new(
        data.dig(0, 0, 0).to_i,
        data.dig(0, 0, 1),
        data.dig(0, 0, 2)
      )
    end

    ##
    # Gets player info
    def player_info(id)
      raw_data = @api.player_info(id)
      data = Serializer.parseData(raw_data)

      profile = Network::Profile.new
      profile.parse(data.dig(0, 0))
      profile
    end

    ##
    # Gets detailed player info
    def player_details(id)
      raw_data = @api.player_details(id)
      data = Serializer.parseData(raw_data)

      profile = Network::Profile.new
      profile.parse(data.dig(0, 0))
      network = Network::Network.new(@api, @player)
      network.parse(data.dig(1))

      PlayerDetails.new(profile, network)
    end
  end
end
