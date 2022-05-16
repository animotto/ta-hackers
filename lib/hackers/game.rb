# frozen_string_literal: true

module Hackers
  ##
  # Game API implementation
  class Game
    SUCCESS_FAIL = 0
    SUCCESS_CORE = 1
    SUCCESS_RESOURCES = 2
    SUCCESS_CONTROL = 4

    MISSION_AWAITS = 0
    MISSION_FINISHED = 1
    MISSION_REJECTED = 2

    CURRENCY_MONEY = 0
    CURRENCY_BITCOINS = 1

    attr_reader :api, :app_settings, :node_types,
                :language_translations, :program_types,
                :missions_list, :skin_types, :player,
                :chat, :hints_list, :experience_list,
                :builders_list

    attr_accessor :config, :goalsTypes, :shieldTypes,
      :rankList, :countriesList, :sid, :syncSeq,
      :client

    def initialize(config)
      @config = config
      @sid = String.new
      @goalsTypes = Hash.new
      @shieldTypes = Hash.new
      @rankList = Hash.new
      @countriesList = Hash.new
      @syncSeq = 0
      @client = Client.new(
        @config["host"], 
        @config["port"], 
        !@config["ssl"].nil?,
        @config["url"], 
        @config["salt"], 
      )

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

      @app_settings = AppSettings.new(@api)
      @language_translations = LanguageTranslations.new(@api)
      @node_types = NodeTypes::List.new(@api)
      @program_types = ProgramTypes::List.new(@api)
      @missions_list = MissionsList.new(@api)
      @skin_types = SkinTypes.new(@api)
      @hints_list = HintsList.new(@api)
      @experience_list = ExperienceList.new(@api)
      @builders_list = BuildersList.new(@api)
      @player = Network::Player.new(@api)
      @chat = Chat.new(@api)
    end

    ##
    # Authenticates by id and password
    def auth
      @api.auth
    end

    ##
    # Attacks target in test mode
    def attack_test(id)
      target = Network::Target.new(@api)
      target.attack_test(id)
      target
    end

    ##
    # Gets country name by ID:
    #   id = Country ID
    #
    # Returns country name as string
    def getCountryNameByID(id)
      @countriesList.fetch(id.to_s, "Unknown")
    end

    ##
    # Converts a timer to human readable format:
    #   timer = Timer in seconds
    #
    # Returns a string in the format Days:Hours:Minutes:Seconds
    def timerToDHMS(timer)
      dhms = Array.new
      dhms.push("%02d" % [timer / 60 / 60 / 24])
      dhms.push("%02d" % [timer / 60 / 60 % 24])
      dhms.push("%02d" % [timer / 60 % 60])
      dhms.push("%02d" % [timer % 60])
      return dhms.join(":")
    end

    ##
    # Checks network connectivity
    #
    # Returns 1 if the request is successful
    def cmdCheckCon
      params = {
        "check_connectivity"  => 1,
        "app_version"         => @config["version"],
      }
      response = @client.request_cmd(params)
      return response.to_i
    end

    ##
    # Creates new account
    #
    # Returns Serializer#parsePlayerCreate
    def cmdPlayerCreate
      params = {
        "player_create" => 1,
        "app_version"   => @config["version"],
      }
      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      return serializer.parsePlayerCreate
    end

    ##
    # Sets new player name:
    #   id    = Player ID
    #   name  = Player name
    #
    # Returns the string "ok" if the request is successful
    def cmdPlayerSetName(id, name)
      params = {
        "player_set_name" => "",
        "id"              => id,
        "name"            => name,
        "app_version"     => @config["version"],
      }
      response = @client.request_cmd(params)
      return response
    end

    ##
    # Sets new player name in tutorial mode:
    #   id        = Player ID
    #   name      = Player name
    #   tutorial  = Tutorial ID
    #
    # Returns the string "ok" if the request is successful
    def cmdTutorialPlayerSetName(id, name, tutorial)
      params = {
        "tutorial_player_set_name"  => "",
        "id_player"                 => id,
        "name"                      => name,
        "tutorial"                  => tutorial,
        "app_version"               => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Authenticates by Google services
    def cmdAuthGoogle(code)
      params = {
        "auth_google_new" => "",
        "authCode"        => code,
        "app_version"     => @config["version"],
      }
      response = @client.request_cmd(params)
      return response
    end

    ##
    # Authenticates by ID and password
    #
    # Returns Serializer#parseAuthIdPassword
    def cmdAuthIdPassword
      params = {
        "auth_id_password"  => "",
        "id_player"         => @config["id"],
        "password"          => @config["password"],
        "app_version"       => @config["version"],
      }
      response = @client.request_cmd(params)
      @syncSeq = 0
      serializer = Serializer.new(response)
      return serializer.parseAuthIdPassword
    end

    ##
    # Gets player network
    #
    # Returns Serializer#parseNetGetForMaint
    def cmdNetGetForMaint
      params = {
        "net_get_for_maintenance" => 1,
        "id_player"               => @config["id"],
        "app_version"             => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseNetGetForMaint
    end

    ##
    # Updates player network:
    #   net = Serialize#parseNetwork
    #
    # Returns the string "ok" if the request is successful
    def cmdUpdateNet(net)
      params = {
        "net_update"  => 1,
        "id_player"   => @config["id"],
        "net"         => Serializer.generateNetwork(net),
        "app_version" => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Creates a node and updates the network structure:
    #   type  = Node type
    #   net   = Serialize#parseNetwork
    #
    # Returns the ID of the created node
    def cmdCreateNodeUpdateNet(type, net)
      params = {
        "create_node_and_update_net"  => 1,
        "id_player"                   => @config["id"],
        "id_node"                     => type,
        "net"                         => Serializer.generateNetwork(net),
        "app_version"                 => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response.to_i
    end

    ##
    # Deletes node and updates network structure:
    #   id  = Node ID
    #   net = Serialize#parseNetwork
    #
    # Returns the string "ok" if the request is successful
    def cmdDeleteNodeUpdateNet(id, net)
      params = {
        "node_delete_net_update"  => 1,
        "id_player"               => @config["id"],
        "id"                      => id,
        "net"                     => Serializer.generateNetwork(net),
        "app_version"             => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Upgrades node:
    #   id = Node ID
    #
    # Returns the string "ok" if the request is successful
    def cmdUpgradeNode(id)
      params = {
        "upgrade_node"  => 1,
        "id"            => id,
        "app_version"   => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Upgrades node in tutorial mode:
    #   id        = Node ID
    #   tutorial  = Tutorial ID
    #
    # Returns the string "ok" if the request is successful
    def cmdTutorialUpgradeNode(id, tutorial)
      params = {
        "tutorial_upgrade_node"   => 1,
        "id_player"               => @config["id"],
        "id_node"                 => id,
        "tutorial"                => tutorial,
        "app_version"             => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Finishes node upgrade:
    #   id = Node ID
    #
    # Returns the string "ok" if the request is successful
    def cmdFinishNode(id)
      params = {
        "finish_node"   => 1,
        "id"            => id,
        "app_version"   => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Collects node resources:
    #   id = Node ID
    #
    # Returns Serializer#parseCollectNode
    def cmdCollectNode(id)
      params = {
        "collect"       => 1,
        "id_node"       => id,
        "app_version"   => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseCollectNode
    end

    ##
    # Sets amount of builders for node:
    #   id        = Node ID
    #   builders  = Amount of builders
    #
    # Returns the string "ok" if the request is successful
    def cmdNodeSetBuilders(id, builders)
      params = {
        "node_set_builders"   => 1,
        "id_node"             => id,
        "builders"            => builders,
        "app_version"         => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Creates program:
    #   type = Program type
    #
    # Returns the ID of the created program
    def cmdCreateProgram(type)
      params = {
        "create_program"  => 1,
        "id_player"       => @config["id"],
        "id_program"      => type,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response.to_i
    end

    ##
    # Upgrades program:
    #   id = Program ID
    #
    # Returns the string "ok" if the request is successful
    def cmdUpgradeProgram(id)
      params = {
        "upgrade_program" => 1,
        "id"              => id,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Finishes program upgrade:
    #   id = Program ID
    #
    # Returns the string "ok" if the request is successful
    def cmdFinishProgram(id)
      params = {
        "finish_program" => 1,
        "id"             => id,
        "app_version"    => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Deletes program:
    #   programs = {
    #     Type1 => Amount1,
    #     Type2 => Amount2,
    #     Type3 => Amount3,
    #     ...
    #   }
    #
    # Returns Serializer#parseDeleteProgram
    def cmdDeleteProgram(programs)
      params = {
        "program_delete"  => "",
        "id_player"       => @config["id"],
        "data"            => Serializer.generatePrograms(programs),
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseDeleteProgram
    end

    ##
    # Synchronizes programs queue
    #   programs  = {
    #     Type1 => Amount1,
    #     Type2 => Amount2,
    #     Type3 => Amount3,
    #     ...
    #   }
    #   seq       = Sequence
    #
    # Returns Serializer#parseQueueSync
    def cmdQueueSync(programs, seq = @syncSeq)
      params = {
        "queue_sync_new"  => 1,
        "id_player"       => @config["id"],
        "data"            => Serializer.generatePrograms(programs),
        "seq"             => seq,
        "app_version"     => @config["version"],
      }
      @syncSeq += 1
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseQueueSync
    end

    ##
    # Finishes programs queue synchronization immediately
    #   programs  = {
    #     Type1 => Amount1,
    #     Type2 => Amount2,
    #     Type3 => Amount3,
    #     ...
    #   }
    #
    # Returns Serializer#parseQueueSync
    def cmdQueueSyncFinish(programs)
      params = {
        "queue_sync_and_finish_new" => 1,
        "id_player"                 => @config["id"],
        "data"                      => Serializer.generatePrograms(programs),
        "app_version"               => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.parseData(response)
      return serializer.parseQueueSync
    end

    ##
    # Gets world data:
    #   country = Country ID
    #
    # Returns #Serialize#parsePlayerWorld
    def cmdPlayerWorld(country)
      params = {
        "player_get_world"  => 1,
        "id"                => @config["id"],
        "id_country"        => country,
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parsePlayerWorld
    end

    ##
    # Gets new targets
    #
    # Returns Serializer#parseGetNewTargets
    def cmdGetNewTargets
      params = {
        "player_get_new_targets"  => 1,
        "id"                      => @config["id"],
        "app_version"             => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseGetNewTargets
    end

    ##
    # Collects bonus:
    #   id = Bonus ID
    #
    # Returns the string "ok" if the request is successful
    def cmdBonusCollect(id)
      params = {
        "bonus_collect" => 1,
        "id"            => id,
        "app_version"   => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Updates goal:
    #   id     = Goal ID
    #   record = New record
    #
    # Returns Serializer#parseGoalUpdate
    def cmdGoalUpdate(id, record)
      params = {
        "goal_update" => "",
        "id"          => id,
        "record"      => record,
        "app_version" => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseGoalUpdate
    end

    ##
    # Rejects goal:
    #   id = Goal ID
    #
    # Returns the string "ok" if the request is successful
    def cmdGoalReject(id)
      params = {
        "goal_reject" => "",
        "id"          => id,
        "app_version" => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Gets network for attack:
    #   target = Target ID
    #
    # Returns Serializer#parseNetGetForAttack
    def cmdNetGetForAttack(target)
      params = {
        "net_get_for_attack"  => 1,
        "id_target"           => target,
        "id_attacker"         => @config["id"],
        "app_version"         => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseNetGetForAttack
    end

    ##
    # Leaves network after attack:
    #   target = Target ID
    def cmdNetLeave(target)
      params = {
        "net_leave"   => 1,
        "id_attacker" => @config["id"],
        "id_target"   => target,
        "app_version" => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Updates fight:
    #   target = Target ID
    #   date   = {
    #     :money    => Money,
    #     :bitcoin  => Bitcoins,
    #     :nodes    => Nodes,
    #     :loots    => Loots,
    #     :success  => Success,
    #     :programs => Programs,
    #   }
    def cmdFightUpdate(target, data)
      params = {
        "fight_update_running"  => 1,
        "attackerID"            => @config["id"],
        "targetID"              => target,
        "goldMainLoot"          => data[:money],
        "bcMainLoot"            => data[:bitcoin],
        "nodeIDsList"           => data[:nodes],
        "nodeLootValues"        => data[:loots],
        "attackSuccess"         => data[:success],
        "usedProgramsList"      => data[:programs],
        "app_version"           => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Finishes fight:
    #   target = Target ID
    #   date   = {
    #     :money    => Money,
    #     :bitcoin  => Bitcoins,
    #     :nodes    => Nodes,
    #     :loots    => Loots,
    #     :success  => Success,
    #     :programs => Programs,
    #     :replay   => Replay data,
    #   }
    def cmdFight(target, data)
      params = {
        "fight"             => 1,
        "attackerID"        => @config["id"],
        "targetID"          => target,
        "goldMainLoot"      => data[:money],
        "bcMainLoot"        => data[:bitcoin],
        "nodeIDsList"       => data[:nodes],
        "nodeLootValues"    => data[:loots],
        "attackSuccess"     => data[:success],
        "usedProgramsList"  => data[:programs],
        "summaryString"     => data[:summary],
        "replayVersion"     => data[:version],
        "keepLock"          => 1,
        "app_version"       => @config["version"],
      }
      data = {
        "replayString" => data[:replay],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Updates mission in tutorial mode:
    #   mission = Mission ID
    #   data    = {
    #     :money       => Money,
    #     :bitcoins    => Bitcoins,
    #     :finished    => Finished,
    #     :currencies  => Nodes currencies,
    #     :programs    => Programs,
    #     :tutorial    => Tutorial ID,
    #   }
    #   id = Player ID
    def cmdTutorialPlayerMissionUpdate(mission, data, id = @config["id"])
      params = {
        "tutorial_player_mission_update"  => 1,
        "id_player"                       => id,
        "id_mission"                      => mission,
        "money_looted"                    => data[:money],
        "bcoins_looted"                   => data[:bitcoins],
        "finished"                        => data[:finished],
        "nodes_currencies"                => Serializer.generateMissionCurrencies(data[:currencies]),
        "programs_data"                   => Serializer.generateMissionPrograms(data[:programs]),
        "tutorial"                        => data[:tutorial],
        "app_version"                     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Gets replay:
    #   id = Replay ID
    #
    # Returns Serializer#parseReplay
    def cmdFightGetReplay(id)
      params = {
        "fight_get_replay" => 1,
        "id"               => id,
        "app_version"      => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseReplay(0, 0, 0)
    end

    ##
    # Gets replay info:
    #   id = Replay ID
    #
    # Returns Serializer#parseReplayInfo
    def cmdFightGetReplayInfo(id)
      params = {
        "fight_get_replay_info"   => "",
        "replay_id"               => id,
        "app_version"             => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseReplayInfo
    end

    ##
    # Gets mission fight:
    #   mission = Mission ID
    #
    # Returns Serializer#parseGetMissionFight
    def cmdGetMissionFight(mission)
      params = {
        "get_mission_fight" => 1,
        "id_mission"        => mission,
        "id_attacker"       => @config["id"],
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseGetMissionFight
    end

    ##
    # Gets player info:
    #   id = Player ID
    #
    # Returns *Profile*
    def cmdPlayerGetInfo(id)
      params = {
        "player_get_info"   => "",
        "id"                => id,
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseProfile(0, 0)
    end

    ##
    # Gets detailed player info:
    #   id = Player ID
    #
    # Returns hash:
    #   {
    #     "profile" => *Profile*,
    #     "nodes"   => Serializer#parseNodes,
    #   }
    def cmdGetNetDetailsWorld(id)
      params = {
        "get_net_details_world" => 1,
        "id_player"             => id,
        "app_version"           => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      data = {
        "profile"  => serializer.parseProfile(0, 0),
        "nodes"    => serializer.parseNodes(1),
      }
      return data
    end

    ##
    # Sets player HQ and country:
    #   id       = Player ID
    #   x        = X
    #   y        = y
    #   country  = Country ID
    #
    # Returns the string "ok" if the request is successful
    def cmdSetPlayerHqCountry(id, x, y, country)
      params = {
        "set_player_hq_and_country" => 1,
        "id_player"                 => id,
        "hq_location_x"             => x,
        "hq_location_y"             => y,
        "id_country"                => country,
        "app_version"               => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Moves player HQ:
    #   x        = X
    #   y        = y
    #   country  = Country ID
    #
    # Returns the string "ok" if the request is successful
    def cmdPlayerHqMove(x, y, country)
      params = {
        "player_hq_move"  => 1,
        "id"              => @config["id"],
        "hq_location_x"   => x,
        "hq_location_y"   => y,
        "country"         => country,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Gets HQ move price:
    #
    # Returns the price
    def cmdHqMoveGetPrice
      params = {
        "hq_move_get_price" => "",
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response.to_i
    end

    ##
    # Sets player skin:
    #   skin = Skin ID
    def cmdPlayerSetSkin(skin)
      params = {
        "player_set_skin" => "",
        "id"              => @config["id"],
        "skin"            => skin,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Buys player skin:
    #   skin = Skin ID
    #
    # Returns the string "ok" if the request is successful
    def cmdPlayerBuySkin(skin)
      params = {
        "player_buy_skin" => "",
        "id"              => @config["id"],
        "id_skin"         => skin,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Buys shield:
    #   shield = Shield ID
    #
    # Returns an empty string if the request is successful
    def cmdShieldBuy(shield)
      params = {
        "shield_buy"      => "",
        "id_player"       => @config["id"],
        "id_shield_type"  => shield,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Buys currency:
    #   currency  = Currency
    #   perc      = Percent
    #
    # Returns Serializer#parsePlayerBuyCurrencyPerc
    def cmdPlayerBuyCurrencyPerc(currency, perc)
      params = {
        "player_buy_currency_percentage" => 1,
        "id"                             => @config["id"],
        "currency"                       => currency,
        "max_storage_percentage"         => perc,
        "app_version"                    => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parsePlayerBuyCurrencyPerc
    end

    ##
    # Gets ranking:
    #   country = Country ID
    #
    # Returns Serializer#parseRankingGetAll
    def cmdRankingGetAll(country)
      params = {
        "ranking_get_all" => "",
        "id_player"       => @config["id"],
        "id_country"      => country,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseRankingGetAll
    end

    ##
    # Gets missions log:
    #   id = Player ID
    #
    # Returns Serializer#parseMissionsLog
    def cmdPlayerMissionsGetLog(id = @config["id"])
      params = {
        "player_missions_get_log"  => "",
        "id"                       => id,
        "app_version"              => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseMissionsLog(0)
    end

    ##
    # Sets player readme:
    #   readme = *Readme*
    #
    # Returns the string "ok" if the request is successful
    def cmdPlayerSetReadme(readme)
      params = {
        "player_set_readme"  => "",
        "id"                 => @config["id"],
        "text"               => Serializer.generateReadme(readme),
        "app_version"        => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Sets the readme after attack:
    #   target  = Target ID
    #   readme  = *Readme*
    #
    # Returns the string "ok" if the request is successful
    def cmdPlayerSetReadmeFight(target, readme)
      params = {
        "player_set_readme_fight"  => "",
        "id_attacker"              => @config["id"],
        "id_target"                => target,
        "text"                     => Serializer.generateReadme(readme),
        "app_version"              => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Gets player goals
    #
    # Returns Serializer#parseGoals
    def cmdGoalByPlayer
      params = {
        "goal_by_player"  => "",
        "id_player"       => @config["id"],
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseGoals(0)
    end

    ##
    # Gets news list
    #
    # Returns Serializer#parseNewsList
    def cmdNewsGetList
      params = {
        "news_get_list" => 1,
        "app_version"   => @config["version"],
      }
      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      return serializer.parseNewsList
    end

    ##
    # Gets hints list
    #
    # Returns Serializer#parseHintsList
    def cmdHintsGetList
      params = {
        "hints_get_list"  => 1,
        "app_version"     => @config["version"],
      }
      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      return serializer.parseHintsList
    end

    ##
    # Gets world news list
    def cmdWorldNewsGetList
      params = {
        "world_news_get_list" => 1,
        "app_version"         => @config["version"],
      }
      response = @client.request_cmd(params)
      return response
    end

    ##
    # Gets experience list
    #
    # Returns Serializer#parseExperienceList
    def cmdGetExperienceList
      params = {
        "get_experience_list" => 1,
        "app_version"         => @config["version"],
      }
      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      return serializer.parseExperienceList
    end

    ##
    # Gets builders list
    #
    # Returns Serializer#parseBuildersList
    def cmdBuildersCountGetList
      params = {
        "builders_count_get_list" => 1,
        "app_version"             => @config["version"],
      }
      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      return serializer.parseBuildersList
    end

    ##
    # Gets goals types list
    #
    # Returns Serializer#parseGoalsTypes
    def cmdGoalTypesGetList
      params = {
        "goal_types_get_list" => 1,
        "app_version"         => @config["version"],
      }
      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      return serializer.parseGoalsTypes
    end

    ##
    # Gets shield types list
    #
    # Returns Serializer#parseShieldTypes
    def cmdShieldTypesGetList
      params = {
        "shield_types_get_list" => 1,
        "app_version"           => @config["version"],
      }
      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      return serializer.parseShieldTypes
    end

    ##
    # Gets rank list
    #
    # Returns Serializer#parseRankList
    def cmdRankGetList
      params = {
        "rank_get_list" => 1,
        "app_version"   => @config["version"],
      }
      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      return serializer.parseRankList
    end

    ##
    # Gets fight map
    #
    # Returns Serializer#parseFightMap
    def cmdFightGetMap
      params = {
        "fight_get_map"   => "",
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseFightMap(0)
    end

    ##
    # Creates exception:
    #   name        = Player name
    #   exception   = Exception
    #   version     = Version
    def cmdCreateException(name, exception, version)
      params = {
        "exception_create"    => 1,
        "player_name"         => name,
        "app_version_number"  => version,
        "app_version"         => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Creates report:
    #   reporter    = Reporter
    #   reported    = Reported
    #   message     = Message
    def cmdCreateReport(repoter, reported, message)
      params = {
        "report_create" => "",
        "id_reporter"   => reporter,
        "id_reported"   => reported,
        "message"       => message,
        "app_version"   => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Sets tutorial:
    #   id        = Player ID
    #   tutorial  = Tutorial ID
    def cmdPlayerSetTutorial(tutorial, id = @config["id"])
      params = {
        "player_set_tutorial"  => "",
        "id"                   => id,
        "tutorial"             => tutorial,
        "app_version"          => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Buys builder:
    #   id = Builder ID
    #
    # Returns the string "ok" if the request is successful
    def cmdPlayerBuyBuilder(id = @config["id"])
      params = {
        "player_buy_builder"  => "",
        "id"                  => id,
        "app_version"         => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Buys builder in tutorial mode:
    #   id        = Builder ID
    #   tutorial  = Tutorial ID
    #
    # Returns the string "ok" if the request is successful
    def cmdTutorialPlayerBuyBuilder(id = @config["id"], tutorial)
      params = {
        "tutorial_player_buy_builder"  => "",
        "id_player"                    => id,
        "tutorial"                     => tutorial,
        "app_version"                  => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Uses CP (change platform) code:
    #   id        = Player ID
    #   code      = Code
    #   platform  = Platform
    #
    # Returns Serializer#parseCpUseCode
    def cmdCpUseCode(id, code, platform)
      params = {
        "cp_use_code" => "",
        "id_player"   => id,
        "code"        => code,
        "platform"    => platform,
        "app_version" => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseCpUseCode
    end

    ##
    # Generates CP (change platform) code
    #
    # Returns Serializer#parseCpGenerateCode
    def cmdCpGenerateCode(id, platform)
      params = {
        "cp_generate_code"  => "",
        "id_player"         => id,
        "platform"          => platform,
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseCpGenerateCode
    end

    ##
    # Redeems promo code
    #
    # Returns Serializer#parseRedeemPromoCode
    def cmdRedeemPromoCode(id, code)
      params = {
        "redeem_promo_code" => 1,
        "id_player"         => id,
        "code"              => code,
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseRedeemPromoCode
    end

    def cmdPaymentPayGoogle(id, receipt, signature)
      params = {
        "payment_pay_google"  => "",
        "id_player"           => id,
        "receipt"             => receipt,
        "signature"           => signature,
        "app_version"         => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdAuthByName(name, password)
      params = {
        "auth"         => 1,
        "name"         => name,
        "password"     => password,
        "app_version"  => @config["version"],
      }
      response = @client.request_cmd(params)
      return response
    end

    ##
    # Starts mission:
    #   mission = Mission ID
    #   id      = Player ID
    #
    # Returns the string "ok" if the request is successful
    def cmdPlayerMissionMessageDelivered(mission, id = @config["id"])
      params = {
        "player_mission_message_delivered"  => "",
        "id_player"                         => id,
        "id_mission"                        => mission,
        "app_version"                       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Gets friend logs:
    #   id = Player ID
    #
    # Returns Serializer#parseLogs
    def cmdFightByFBFriend(id)
      params = {
        "fight_by_fb_friend"  => "",
        "id_player"           => id,
        "app_version"         => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseLogs(0)
    end

    ##
    # Sets new player name once:
    #   id    = Player ID
    #   name  = Player name
    #
    # Returns the string "ok" if the request is successful
    def cmdPlayerSetNameOnce(id, name)
      params = {
        "player_set_name_once"  => "",
        "id"                    => id,
        "name"                  => name,
        "app_version"           => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdAuthFB(token)
      params = {
        "auth_fb"     => "",
        "token"       => token,
        "app_version" => @config["version"],
      }
      response = @client.request_cmd(params)
      return response
    end

    ##
    # Gets network structure for test fight:
    #   target    = Target ID
    #   attacker  = Attacker ID (default: ID from config)
    #
    # Returns hash:
    #   {
    #     "nodes"     => Serializer#parseNodes,
    #     "net"       => Serializer#parseNetwork,
    #     "profile"   => *Profile*,
    #     "programs"  => Serializer#parsePrograms,
    #     "readme"    => *Readme*,
    #   }
    def cmdTestFightPrepare(target, attacker = @config["id"])
      params = {
        "testfight_prepare" => "",
        "id_target"         => target,
        "id_attacker"       => attacker,
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      data = {
        "nodes"     => serializer.parseNodes(0),
        "net"       => serializer.parseNetwork(1, 0, 1),
        "profile"   => serializer.parseProfile(2, 0),
        "programs"  => serializer.parsePrograms(3),
        "readme"    => serializer.parseReadme(5, 0, 0),
      }
      return data
    end

    def cmdTestFightWrite(target, attacker, data)
      params = {
        "testfight_write"     => 1,
        "finished"            => "true",
        "id_attacker"         => attacker,
        "id_target"           => target,
        "gold_main_loot"      => data[:moneyMain],
        "gold_total_loot"     => data[:moneyTotal],
        "bc_main_loot"        => data[:bitcoinMain],
        "bc_total_loot"       => data[:bitcoinTotal],
        "node_ids_list"       => data[:nodes],
        "node_loot_values"    => data[:loots],
        "attack_success"      => data[:success],
        "used_programs_list"  => data[:programs],
        "replay_version"      => data[:version],
        "app_version"         => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdPlayerGetFBFriends(id, token)
      params = {
        "player_get_fb_friends" => "",
        "id"                    => id,
        "token"                 => token,
        "app_version"           => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Gets player statistics
    #
    # Returns Serializer#parsePlayerGetStats
    def cmdPlayerGetStats
      params = {
        "player_get_stats"  => "",
        "id"                => @config["id"],
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parsePlayerGetStats
    end

    def cmdTutorialNetUpdate(id, net, tutorial)
      params = {
        "tutorial_net_update" => 1,
        "id_player"           => id,
        "net"                 => net,
        "tutorial"            => tutorial,
        "app_version"         => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdShieldRemove(id)
      params = {
        "shield_remove" => "",
        "id_player"     => id,
        "app_version"   => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdPlayerMissionReject(mission)
      params = {
        "player_mission_reject" => 1,
        "id_player"             => @config["id"],
        "id_mission"            => mission,
        "app_version"           => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdFightByPlayer(id)
      params = {
        "fight_by_player" => 1,
        "player_id"       => id,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdProgramCreateFinish(type)
      params = {
        "program_create_and_finish" => 1,
        "id_player"                 => @config["id"],
        "id_program"                => type,
        "app_version"               => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdAuthPairFB(id, token)
      params = {
        "auth_pair_fb"  => "",
        "id_player"     => id,
        "token"         => token,
        "app_version"   => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdAuthUnpairFB(id)
      params = {
        "auth_unpair_fb"  => "",
        "id_player"       => id,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdAuthPairGoogleNew(id, code)
      params = {
        "auth_pair_google_new"  => "",
        "id_player"             => id,
        "authCode"              => code,
        "app_version"           => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdProgramUpgradeFinish(id)
      params = {
        "program_upgrade_and_finish"  => 1,
        "id"                          => id,
        "app_version"                 => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdIssueCreate(name, issue)
      params = {
        "issue_create"  => 1,
        "player_name"   => name,
        "issue"         => issue,
        "app_version"   => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Revives AI program:
    #   id = Program ID
    #
    # Returns Serializer#parseAIProgramRevive
    def cmdAIProgramRevive(id)
      params = {
        "ai_program_revive" => 1,
        "id"                => id,
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseAIProgramRevive
    end

    ##
    # Revives and finishes AI program:
    #   id = Program ID
    #
    # Returns Serializer#parseAIProgramRevive
    def cmdAIProgramReviveFinish(id)
      params = {
        "ai_program_revive_and_finish"  => 1,
        "id"                            => id,
        "app_version"                   => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseAIProgramRevive
    end

    ##
    # Finishes reviving AI program:
    #   id = Program ID
    #
    # Returns Serializer#parseAIProgramRevive
    def cmdAIProgramFinishRevive(id)
      params = {
        "ai_program_finish_revive"  => 1,
        "id"                        => id,
        "app_version"               => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseAIProgramRevive
    end

    ##
    # Gets player readme:
    #   id = Player ID
    #
    # Returns *Readme*
    def cmdPlayerGetReadme(id)
      params = {
        "player_get_readme" => "",
        "id"                => id,
        "app_version"       => @config["version"],
      }
      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      return serializer.parseReadme(0, 0, 0)
    end

    ##
    # Finishes node upgrade immediately:
    #   id = Node ID
    #
    # Returns the string "ok" if the request is successful
    def cmdNodeUpgradeFinish(id)
      params = {
        "node_upgrade_and_finish"   => 1,
        "id"                        => id,
        "app_version"               => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    def cmdPlayerMissionUpdate(mission, data, id = @config["id"])
      params = {
        "player_mission_update" => 1,
        "id_player"             => id,
        "id_mission"            => mission,
        "money_looted"          => data[:money],
        "bcoins_looted"         => data[:bitcoins],
        "finished"              => data[:finished],
        "nodes_currencies"      => Serializer.generateMissionCurrencies(data[:currencies]),
        "programs_data"         => Serializer.generateMissionPrograms(data[:programs]),
        "app_version"           => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Cancels node upgrade:
    #   id = Node ID
    #
    # Returns the string "ok" if the request is successful
    def cmdNodeCancel(id)
      params = {
        "node_cancel" => 1,
        "id"          => id,
        "app_version" => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end

    ##
    # Subscribes player email:
    #   email     = Email
    #   language  = Language
    #   id        = Player ID
    #
    # Returns the string "ok" if the request is successful
    def cmdEmailSubscribe(email, language = @config["language"], id = @config["id"])
      params = {
        "email_subscribe" => "",
        "player_id"       => id,
        "email"           => email,
        "language"        => language,
        "app_version"     => @config["version"],
      }
      response = @client.request_session(params, @sid)
      return response
    end
  end
end
