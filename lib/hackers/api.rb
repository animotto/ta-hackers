# frozen_string_literal: true

module Hackers
  ##
  # API implementation
  class API
    HOST = 'hackers-1.appspot.com'
    PORT = 443
    SSL = true
    PATH = '/req.php'
    SALT = 'WGmHVNph'
    VERSION = 1220
    LANGUAGE = 'en'
    PLATFORM = 'google'

    attr_accessor :host, :port, :path, :salt,
                  :ssl, :id, :password, :language,
                  :platform, :version, :sid, :sync_seq

    ##
    # Creates a new instance of the API
    def initialize(
      host: HOST,
      port: PORT,
      ssl: SSL,
      path: PATH,
      salt: SALT,
      version: VERSION,
      language: LANGUAGE,
      platform: PLATFORM
    )
      @host = host
      @port = port
      @ssl = ssl
      @path = path
      @salt = salt
      @version = version
      @language = language
      @platform = platform

      @client = Client.new(@host, @port, @ssl, @path, @salt)

      @sync_seq = 0
    end

    ##
    # Returns true if id is present
    def id?
      !@id.nil?
    end

    ##
    # Returns true if password is present
    def password?
      !@password.nil?
    end

    ##
    # Returns true if sid is present
    def sid?
      !@sid.nil?
    end

    ##
    # Gets translations by specified language
    def language_translations(language = @language)
      @client.request_cmd(
        {
          'i18n_translations_get_language' => 1,
          'language_code' => language,
          'app_version' => @version
        }
      )
    end

    ##
    # Gets application settings
    def app_settings
      response = @client.request_cmd(
        {
          'app_setting_get_list' => 1,
          'app_version' => @version
        }
      )
    end

    ##
    # Gets node types
    def node_types
      @client.request_cmd(
        {
          'get_node_types_and_levels' => 1,
          'app_version' => @version
        }
      )
    end

    ##
    # Gets program types
    def program_types
      @client.request_cmd(
        {
          'get_program_types_and_levels' => 1,
          'app_version' => @version
        }
      )
    end

    ##
    # Gets missions list
    def missions_list
      params = {
        'missions_get_list' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parseMissionsList
    end

    ##
    # Checks network connectivity
    def check_connectivity
      params = {
        'check_connectivity' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      response.to_i
    end

    ##
    # Creates a new account
    def create_player
      params = {
        'player_create' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parsePlayerCreate
    end

    ##
    # Sets new player name
    def set_name(name, id = @id)
      @client.request_cmd(
        {
          'player_set_name' => '',
          'id' => id,
          'name' => name,
          'app_version' => @version
        }
      )
    end

    ##
    # Sets new player name in tutorial mode
    def set_name_tutorial(name, tutorial, id = @id)
      @client.request_session(
        {
          'tutorial_player_set_name' => '',
          'id_player' => id,
          'name' => name,
          'tutorial' => tutorial,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Authenticates by Google services
    def auth_google(code)
      @client.request_cmd(
        {
          'auth_google_new' => '',
          'authCode' => code,
          'app_version' => @version
        }
      )
    end

    ##
    # Authenticates by id and password
    def auth(id = @id, password = @password)
      params = {
        'auth_id_password' => '',
        'id_player' => id,
        'password' => password,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      @sync_seq = 0
      serializer = Serializer.new(response)
      serializer.parseAuthIdPassword
    end

    ##
    # Gets player network
    def net(id = @id)
      @client.request_session(
        {
          'net_get_for_maintenance' => 1,
          'id_player' => id,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Updates player network
    def update_net(net, id = @id)
      @client.request_session(
        {
          'net_update' => 1,
          'id_player' => id,
          'net' => Serializer.generateNetwork(net),
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Creates a node and updates the network structure
    def create_node_update_net(type, net, id = @id)
      params = {
        'create_node_and_update_net' => 1,
        'id_player' => id,
        'id_node' => type,
        'net' => Serializer.generateNetwork(net),
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      response.to_i
    end

    ##
    # Deletes a node and updates network structure
    def delete_node_update_net(node, net, id = @id)
      @client.request_session(
        {
          'node_delete_net_update' => 1,
          'id_player' => id,
          'id' => node,
          'net' => Serializer.generateNetwork(net),
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Upgrades a node
    def upgrade_node(node)
      @client.request_session(
        {
          'upgrade_node' => 1,
          'id' => node,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Upgrades a node in tutorial mode
    def upgrade_node_tutorial(node, tutorial, id = @id)
      @client.request_session(
        {
          'tutorial_upgrade_node' => 1,
          'id_player' => id,
          'id_node' => node,
          'tutorial' => tutorial,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Finishes node upgrade
    def finish_node(node)
      @client.request_session(
        {
          'finish_node' => 1,
          'id' => node,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Collects node resources
    def collect_node(node)
      params = {
        'collect' => 1,
        'id_node' => node,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseCollectNode
    end

    ##
    # Sets amount of builders for the node
    def node_set_builders(node, builders)
      @client.request_session(
        {
          'node_set_builders' => 1,
          'id_node' => node,
          'builders' => builders,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Creates a program
    def create_program(type, id = @id)
      params = {
        'create_program' => 1,
        'id_player' => id,
        'id_program' => type,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      response.to_i
    end

    ##
    # Upgrades a program
    def upgrade_program(program)
      @client.request_session(
        {
          'upgrade_program' => 1,
          'id' => program,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Finishes program upgrade
    def finish_program(program)
      @client.request_session(
        {
          'finish_program' => 1,
          'id' => program,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Deletes a program
    def delete_program(programs, id = @id)
      params = {
        'program_delete' => '',
        'id_player' => id,
        'data' => Serializer.generatePrograms(programs),
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseDeleteProgram
    end

    ##
    # Synchronizes programs queue
    def queue_sync(programs, seq = @sync_seq, id = @id)
      @sync_seq += 1

      @client.request_session(
        {
          'queue_sync_new' => 1,
          'id_player' => id,
          'data' => programs,
          'seq' => seq,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Finishes programs queue synchronization immediately
    def queue_sync_finish(programs, id = @id)
      params = {
        'queue_sync_and_finish_new' => 1,
        'id_player' => id,
        'data' => Serializer.generatePrograms(programs),
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.parseData(response)
      serializer.parseQueueSync
    end

    ##
    # Gets world data
    def world(country, id = @id)
      params = {
        'player_get_world' => 1,
        'id' => id,
        'id_country' => country,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parsePlayerWorld
    end

    ##
    # Gets new targets
    def new_targets(id = @id)
      params = {
        'player_get_new_targets' => 1,
        'id' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseGetNewTargets
    end

    ##
    # Collects bonus
    def collect_bonus(bonus)
      @client.request_session(
        {
          'bonus_collect' => 1,
          'id' => bonus,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Updates goal
    def update_goal(goal, record)
      params = {
        'goal_update' => '',
        'id' => goal,
        'record' => record,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseGoalUpdate
    end

    ##
    # Rejects goal
    def reject_goal(goal)
      @client.request_session(
        {
          'goal_reject' => '',
          'id' => goal,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Reads the chat
    def read_chat(room, last = '')
      params = {
        'chat_display' => '',
        'room' => room,
        'last_message' => last,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseChat
    end

    ##
    # Writes a message to the chat
    def write_chat(room, message, last = '', id = @id)
      message = Serializer.normalizeData(message, false)
      params = {
        'chat_send' => '',
        'room' => room,
        'last_message' => last,
        'message' => message,
        'id_player' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseChat
    end

    ##
    # Gets network for attack
    def attack_net(target, id = @id)
      params = {
        'net_get_for_attack' => 1,
        'id_target' => target,
        'id_attacker' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseNetGetForAttack
    end

    ##
    # Leaves network after attack
    def leave_net(target, id = @id)
      @client.request_session(
        {
          'net_leave' => 1,
          'id_attacker' => id,
          'id_target' => target,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Updates fight
    def update_fight(target, data, id = @id)
      @client.request_session(
        {
          'fight_update_running' => 1,
          'attackerID' => id,
          'targetID' => target,
          'goldMainLoot' => data[:money],
          'bcMainLoot' => data[:bitcoin],
          'nodeIDsList' => data[:nodes],
          'nodeLootValues' => data[:loots],
          'attackSuccess' => data[:success],
          'usedProgramsList' => data[:programs],
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Finishes fight
    def finish_fight(target, data, id = @id)
      @client.request_session(
        {
          'fight' => 1,
          'attackerID' => id,
          'targetID' => target,
          'goldMainLoot' => data[:money],
          'bcMainLoot' => data[:bitcoin],
          'nodeIDsList' => data[:nodes],
          'nodeLootValues' => data[:loots],
          'attackSuccess' => data[:success],
          'usedProgramsList' => data[:programs],
          'summaryString' => data[:summary],
          'replayVersion' => data[:version],
          'keepLock' => 1,
          'app_version' => @version
        },
        @sid,
        data: {
          'replayString' => data[:replay]
        }
      )
    end

    ##
    # Updates mission in tutorial mode
    def update_mission_tutorial(mission, tutorial, data, id = @id)
      @client.request_session(
        {
          'tutorial_player_mission_update' => 1,
          'id_player' => id,
          'id_mission' => mission,
          'money_looted' => data[:money],
          'bcoins_looted' => data[:bitcoins],
          'finished' => data[:finished],
          'nodes_currencies' => Serializer.generateMissionCurrencies(data[:currencies]),
          'programs_data' => Serializer.generateMissionPrograms(data[:programs]),
          'tutorial' => tutorial,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Gets replay
    def replay(id)
      params = {
        'fight_get_replay' => 1,
        'id' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseReplay(0, 0, 0)
    end

    ##
    # Gets replay info:
    def replay_info(id)
      params = {
        'fight_get_replay_info' => '',
        'replay_id' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseReplayInfo
    end

    ##
    # Gets mission fight
    def attack_mission(mission, id = @id)
      params = {
        'get_mission_fight' => 1,
        'id_mission' => mission,
        'id_attacker' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseGetMissionFight
    end

    ##
    # Gets player info
    def player_info(id)
      params = {
        'player_get_info' => '',
        'id' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseProfile(0, 0)
    end

    ##
    # Gets detailed player info
    def player_details(id)
      params = {
        'get_net_details_world' => 1,
        'id_player' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)

      {
        'profile' => serializer.parseProfile(0, 0),
        'nodes' => serializer.parseNodes(1)
      }
    end

    ##
    # Sets player HQ and country
    def set_hq(x, y, country, id = @id)
      @client.request_session(
        {
          'set_player_hq_and_country' => 1,
          'id_player' => id,
          'hq_location_x' => x,
          'hq_location_y' => y,
          'id_country' => country,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Moves player HQ
    def move_hq(x, y, country, id = @id)
      @client.request_session(
        {
          'player_hq_move' => 1,
          'id' => id,
          'hq_location_x' => x,
          'hq_location_y' => y,
          'country' => country,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Gets HQ move price
    def hq_price
      params = {
        'hq_move_get_price' => '',
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      response.to_i
    end

    ##
    # Sets player skin
    def set_skin(skin, id = @id)
      @client.request_session(
        {
          'player_set_skin' => '',
          'id' => id,
          'skin' => skin,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Buys player skin
    def buy_skin(skin, id = @id)
      @client.request_session(
        {
          'player_buy_skin' => '',
          'id' => id,
          'id_skin' => skin,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Gets skin types list
    def skin_types
      @client.request_cmd(
        {
          'skin_types_get_list' => '',
          'app_version' => @version
        }
      )
    end

    ##
    # Buys shield
    def buy_shield(shield, id = @id)
      @client.request_session(
        {
          'shield_buy' => '',
          'id_player' => id,
          'id_shield_type' => shield,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Buys currency
    def buy_currency(currency, perc, id = @id)
      params = {
        'player_buy_currency_percentage' => 1,
        'id' => id,
        'currency' => currency,
        'max_storage_percentage' => perc,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parsePlayerBuyCurrencyPerc
    end

    ##
    # Gets ranking
    def ranking(country, id = @id)
      params = {
        'ranking_get_all' => '',
        'id_player' => id,
        'id_country' => country,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseRankingGetAll
    end

    ##
    # Gets missions log
    def missions_log(id = @id)
      params = {
        'player_missions_get_log' => '',
        'id' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseMissionsLog(0)
    end

    ##
    # Sets player readme
    def set_readme(data, id = @id)
      @client.request_session(
        {
          'player_set_readme' => '',
          'id' => id,
          'text' => data,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Sets the readme after attack
    def set_readme_fight(target, readme, id = @id)
      @client.request_session(
        {
          'player_set_readme_fight' => '',
          'id_attacker' => id,
          'id_target' => target,
          'text' => Serializer.generateReadme(readme),
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Gets player goals
    def goals(id = @id)
      params = {
        'goal_by_player' => '',
        'id_player' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseGoals(0)
    end

    ##
    # Gets news list
    def news
      params = {
        'news_get_list' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parseNewsList
    end

    ##
    # Gets hints list
    def hints_list
      params = {
        'hints_get_list' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parseHintsList
    end

    ##
    # Gets world news list
    def world_news
      @client.request_cmd(
        {
          'world_news_get_list' => 1,
          'app_version' => @version
        }
      )
    end

    ##
    # Gets experience list
    def experience_list
      params = {
        'get_experience_list' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parseExperienceList
    end

    ##
    # Gets builders list
    def builders_list
      params = {
        'builders_count_get_list' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parseBuildersList
    end

    ##
    # Gets goals types list
    def goal_types
      params = {
        'goal_types_get_list' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parseGoalsTypes
    end

    ##
    # Gets shield types list
    def shield_types
      params = {
        'shield_types_get_list' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parseShieldTypes
    end

    ##
    # Gets rank list
    def rank_list
      params = {
        'rank_get_list' => 1,
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parseRankList
    end

    ##
    # Gets fight map
    def map_fight
      params = {
        'fight_get_map' => '',
        'app_version' => @version
      }

      response = @client.request_cmd(params)
      serializer = Serializer.new(response)
      serializer.parseFightMap(0)
    end

    ##
    # Creates an exception
    def exception(name, exception, version)
      @client.request_session(
        {
          'exception_create' => 1,
          'player_name' => name,
          'exception' => exception,
          'app_version_number' => version,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Creates a report
    def report(reported, message, reporter = @id)
      @client.request_session(
        {
          'report_create' => '',
          'id_reporter' => reporter,
          'id_reported' => reported,
          'message' => message,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Sets the tutorial
    def set_tutorial(tutorial, id = @id)
      @client.request_session(
        {
          'player_set_tutorial' => '',
          'id' => id,
          'tutorial' => tutorial,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Buys builder:
    def buy_builder(id = @id)
      @client.request_session(
        {
          'player_buy_builder' => '',
          'id' => id,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Buys builder in tutorial mode
    def buy_builder_tutorial(tutorial, id = @id)
      @client.request_session(
        {
          'tutorial_player_buy_builder' => '',
          'id_player' => id,
          'tutorial' => tutorial,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Uses CP (change platform) code
    def cp_use_code(code, id = @id, platform = @platform)
      params = {
        'cp_use_code' => '',
        'id_player' => id,
        'code' => code,
        'platform' => platform,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseCpUseCode
    end

    ##
    # Generates CP (change platform) code
    def cp_generate_code(id = @id, platform = @platform)
      params = {
        'cp_generate_code' => '',
        'id_player' => id,
        'platform' => platform,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseCpGenerateCode
    end

    ##
    # Redeems promo code
    def redeem_promocode(code, id = @id)
      params = {
        'redeem_promo_code' => 1,
        'id_player' => id,
        'code' => code,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseRedeemPromoCode
    end

    ##
    # Pays for the purchase through Google
    def pay_google(receipt, signature, id = @id)
      @client.request_session(
        {
          'payment_pay_google' => '',
          'id_player' => id,
          'receipt' => receipt,
          'signature' => signature,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Authenticates by name and password
    #
    # NOTE: This request is probably deprecated
    def auth_name(name, password)
      @client.request_cmd(
        {
          'auth' => 1,
          'name' => name,
          'password' => password,
          'app_version' => @version
        }
      )
    end

    ##
    # Starts the mission
    def start_mission(mission, id = @id)
      @client.request_session(
        {
          'player_mission_message_delivered' => '',
          'id_player' => id,
          'id_mission' => mission,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Gets friends logs
    def fight_friend(id = @id)
      params = {
        'fight_by_fb_friend' => '',
        'id_player' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseLogs(0)
    end

    ##
    # Sets new player name once
    def set_name_once(name, id = @id)
      @client.request_session(
        {
          'player_set_name_once' => '',
          'id' => id,
          'name' => name,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Authentiaces by Facebook
    def auth_fb(token)
      @client.request_cmd(
        {
          'auth_fb' => '',
          'token' => token,
          'app_version' => @version
        }
      )
    end

    ##
    # Gets network structure for test fight
    def attack_net_test(target, attacker = @id)
      @client.request_session(
        {
          'testfight_prepare' => '',
          'id_target' => target,
          'id_attacker' => attacker,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Finishes test fight
    def finish_fight_test(target, data, attacker = @id)
      @client.request_session(
        {
          'testfight_write' => 1,
          'finished' => 'true',
          'id_attacker' => attacker,
          'id_target' => target,
          'gold_main_loot' => data[:moneyMain],
          'gold_total_loot' => data[:moneyTotal],
          'bc_main_loot' => data[:bitcoinMain],
          'bc_total_loot' => data[:bitcoinTotal],
          'node_ids_list' => data[:nodes],
          'node_loot_values' => data[:loots],
          'attack_success' => data[:success],
          'used_programs_list' => data[:programs],
          'replay_version' => data[:version],
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Gets Facebook friends list
    def friends_fb(token, id = @id)
      @client.request_session(
        {
          'player_get_fb_friends' => '',
          'id' => id,
          'token' => token,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Gets player statistics
    def player_stats(id = @id)
      params = {
        'player_get_stats' => '',
        'id' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parsePlayerGetStats
    end

    ##
    # Updates network in tutorial mode
    def update_net_tutorial(net, tutorial, id = @id)
      @client.request_session(
        {
          'tutorial_net_update' => 1,
          'id_player' => id,
          'net' => net,
          'tutorial' => tutorial,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Removes the shield
    def remove_shield(id = @id)
      @client.request_session(
        {
          'shield_remove' => '',
          'id_player' => id,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Rejects the mission
    def reject_mission(mission, id = @id)
      @client.request_session(
        {
          'player_mission_reject' => 1,
          'id_player' => id,
          'id_mission' => mission,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Unknown
    #
    # NOTE: This is not a public request
    def fight_player(id)
      @client.request_session(
        {
          'fight_by_player' => 1,
          'player_id' => id,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Creates a program and finishes immediately
    def create_program_finish(type, id = @id)
      @client.request_session(
        {
          'program_create_and_finish' => 1,
          'id_player' => id,
          'id_program' => type,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Pairs Facebook account
    def pair_fb(token, id = @id)
      @client.request_session(
        {
          'auth_pair_fb' => '',
          'id_player' => id,
          'token' => token,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Unpairs Facebook account
    def unpair_fb(id = @id)
      @client.request_session(
        {
          'auth_unpair_fb' => '',
          'id_player' => id,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Pairs Google account
    def pair_google(code, id = @id)
      @client.request_session(
        {
          'auth_pair_google_new' => '',
          'id_player' => id,
          'authCode' => code,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Upgrades program and finishes immediately
    def upgrade_program_finish(prog)
      @client.request_session(
        {
          'program_upgrade_and_finish' => 1,
          'id' => prog,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Unknown
    #
    # NOTE: Probably creates an issue in the internal issue tracker
    def issue(name, issue)
      @client.request_session(
        {
          'issue_create' => 1,
          'player_name' => name,
          'issue' => issue,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Revives AI program
    def revive_ai(prog)
      params = {
        'ai_program_revive' => 1,
        'id' => prog,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseAIProgramRevive
    end

    ##
    # Revives and finishes AI program immediately
    def revive_ai_finish(prog)
      params = {
        'ai_program_revive_and_finish' => 1,
        'id' => prog,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseAIProgramRevive
    end

    ##
    # Finishes reviving AI program
    def finish_revive_ai(prog)
      params = {
        'ai_program_finish_revive' => 1,
        'id' => prog,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseAIProgramRevive
    end

    ##
    # Gets player readme
    def player_readme(id = @id)
      params = {
        'player_get_readme' => '',
        'id' => id,
        'app_version' => @version
      }

      response = @client.request_session(params, @sid)
      serializer = Serializer.new(response)
      serializer.parseReadme(0, 0, 0)
    end

    ##
    # Upgrades node and finishes immediately
    def upgrade_node_finish(node)
      @client.request_session(
        {
          'node_upgrade_and_finish' => 1,
          'id' => node,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Updates mission
    def update_mission(mission, data, id = @id)
      @client.request_session(
        {
          'player_mission_update' => 1,
          'id_player' => id,
          'id_mission' => mission,
          'money_looted' => data[:money],
          'bcoins_looted' => data[:bitcoins],
          'finished' => data[:finished],
          'nodes_currencies' => Serializer.generateMissionCurrencies(data[:currencies]),
          'programs_data' => Serializer.generateMissionPrograms(data[:programs]),
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Cancels node upgrade
    def cancel_node(node)
      @client.request_session(
        {
          'node_cancel' => 1,
          'id' => node,
          'app_version' => @version
        },
        @sid
      )
    end

    ##
    # Subscribes players email
    def subscribe_email(email, id = @id, language = @language)
      @client.request_session(
        {
          'email_subscribe' => '',
          'player_id' => id,
          'email' => email,
          'language' => language,
          'app_version' => @version
        },
        @sid
      )
    end
  end
end
