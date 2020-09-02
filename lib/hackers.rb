# coding: utf-8
module Trickster
  module Hackers
    require "net/http"
    require "digest"
    require "base64"

    class RequestError < StandardError
      attr_reader :type, :description
      
      def initialize(type = nil, description = nil)
        @type = type&.strip
        @description = description&.strip
      end

      def to_s
        msg = @type.nil? ? "Unknown" : @type
        msg += ": #{@description}" unless @description.nil?
        return msg
      end
    end
    
    class Game
      attr_accessor :config, :appSettings, :transLang,
                    :nodeTypes, :programTypes, :missionsList,
                    :skinTypes, :hintsList, :experienceList,
                    :buildersList, :goalsTypes, :shieldTypes,
                    :rankList
      
      def initialize(config)
        @config = config
        @appSettings = Hash.new
        @transLang = Hash.new
        @nodeTypes = Hash.new
        @programTypes = Hash.new
        @missionsList = Hash.new
        @skinTypes = Hash.new
        @hintsList = Hash.new
        @experienceList = Hash.new
        @buildersList = Hash.new
        @goalsTypes = Hash.new
        @shieldTypes = Hash.new
        @rankList = Hash.new
        @client = Net::HTTP.new(@config["host"], @config["port"].to_s)
        @client.use_ssl = true unless @config["ssl"].nil?
        @mutex = Mutex.new
      end

      def hashUrl(url)
        data = url.clone
        offset = data.length < 10 ? data.length : 10
        data.insert(offset, @config["salt"])
        hash = Digest::MD5.digest(data)
        hash = Base64.strict_encode64(hash[2..7])
        hash.gsub!(
          /[=+\/]/,
          {"=" => ".", "+" => "-", "/" => "_"},
        )
        return hash
      end

      def makeUrl(url, cmd = true, session = true)
        request = @config["url"] + "?" + url
        request += "&session_id=" + @config["sid"] if session
        request += "&cmd_id=" + hashUrl(request) if cmd
        return request
      end
      
      def request(url, cmd = true, session = true, data = "")
        header = {
          "Content-Type" => "application/x-www-form-urlencoded",
          "Accept-Charset" => "utf-8",
          "Accept-Encoding" => "gzip",
          "User-Agent" => "UniWeb (http://www.differentmethods.com)",
        }

        response = nil
        @mutex.synchronize do
          if data.empty?
            response = @client.get(
              makeUrl(url, cmd, session),
              header,
            )
          else
            response = @client.post(
              makeUrl(url, cmd, session),
              data,
              header,
            )
          end
        rescue => e
          raise RequestError.new(e.message), e.message
        end

        if response.code != "200"
          fields = parseData(response.body.force_encoding("utf-8"))
          raise RequestError.new(fields.dig(0, 0, 0), fields.dig(0, 0, 1)), fields.dig(0, 0, 0)
        end
        return response.body.force_encoding("utf-8")
      end

      def normalizeData(data, dir = true)
        if dir
          data.gsub!("\x01", ",")
          data.gsub!("\x02", ";")
          data.gsub!("\x03", "@")
        else
          data.gsub!(",", "\x01")
          data.gsub!(";", "\x02")
          data.gsub!("@", "\x03")
        end
        return data
      end

      def parseData(data)
        array = Array.new
        data.split("@").each.with_index do |section, i|
          array[i] = Array.new if array[i].nil?
          section.split(";").each.with_index do |record, j|
            array[i][j] = Array.new if array[i][j].nil?
            record.split(",").each.with_index do |field, k|
              array[i][j][k] = field
            end
          end
        end
        return array
      end

      def parseNetwork(data)
        net = Array.new
        begin
          records = data.split("|")
          coords = records[0].split("_")
          rels = records[1].split("_")
          nodes = records[2].split("_")
        rescue
          return net
        end
        nodes.each_index do |i|
          coord = coords[i].split("*")
          net[i] = {
            "id" => nodes[i].to_i,
            "x" => coord[0].to_i,
            "y" => coord[1].to_i,
            "z" => coord[2].to_i,
          }
        end
        rels.each_index do |i|
          rel = rels[i].split("*")
          index = rel[0].to_i
          net[index]["rels"] = Array.new if net[index]["rels"].nil?
          net[index]["rels"].append(rel[1].to_i)
        end
        return net
      end

      def generateNetwork(data)
        nodes = String.new
        coords = String.new
        rels = String.new
        data.each_index do |i|
          nodes += "#{data[i]["id"]}_"
          coords += "#{data[i]["x"]}*#{data[i]["y"]}*#{data[i]["z"]}_"
          unless data[i]["rels"].nil?
            data[i]["rels"].each do |rel|
              rels += "#{i}*#{rel}_"
            end
          end
        end
        net = "#{coords}|#{rels}|#{nodes}"
        return net
      end

      def parseProfile(data)
        profile = {
          "id" => data[0].to_i,
          "name" => data[1],
          "money" => data[2].to_i,
          "bitcoins" => data[3].to_i,
          "credits" => data[4].to_i,
          "experience" => data[5].to_i,
          "rank" => data[9].to_i,
          "builders" => data[10].to_i,
          "x" => data[11].to_i,
          "y" => data[12].to_i,
          "country" => data[13].to_i,
          "skin" => data[14].to_i,
        }
        return profile
      end
      
      def parseNodes(data)
        nodes = Hash.new
        return nodes if data.nil?
        data.each do |node|
          nodes[node[0].to_i] = {
            "type" => node[2].to_i,
            "level" => node[3].to_i,
            "time" => node[4].to_i,
          }
        end
        return nodes
      end

      def getLevelByExp(experience)
        level = 0
        @experienceList.each do |k, v|
          level = v["level"] if experience >= v["experience"]
        end
        return level
      end

      def cmdTransLang
        url = URI.encode_www_form(
          {
            "i18n_translations_get_language" => 1,
            "language_code" => @config["language"],
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        data = Hash.new
        fields = parseData(response)
        fields[0].each_index do |i|
          data[fields[0][i][0]] = fields[0][i][1]
        end
        return data
      end
      
      def cmdAppSettings
        url = URI.encode_www_form(
          {
            "app_setting_get_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        
        for i in (0..10) do
          data[fields[0][i][1]] = fields[0][i][2..3]
        end
        
        data["datetime"] = fields[0][11][0]

        data["languages"] = Hash.new
        fields[0][12].each_index do |i|
          language = fields[0][12][i].split(":")
          data["languages"][language[0]] = language[1]
        end

        for i in (13..17) do
          data[fields[0][i][0]] = fields[0][i][1]
        end
        
        return data
      end

      def cmdGetNodeTypes
        url = URI.encode_www_form(
          {
            "get_node_types_and_levels" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each_index do |i|
          data[fields[0][i][0].to_i] = {
            "name" => fields[0][i][1],
          }
        end
        return data
      end
      
      def cmdGetProgramTypes
        url = URI.encode_www_form(
          {
            "get_program_types_and_levels" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each_index do |i|
          data[fields[0][i][0].to_i] = {
            "name" => fields[0][i][2],
          }
        end
        return data
      end

      def cmdGetMissionsList
        url = URI.encode_www_form(
          {
            "missions_get_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[0]] = {
            "name" => field[1],
            "target" => field[2],
            "message_begin" => field[3],
            "goal" => field[4],
            "message_end" => field[17],
            "network" => parseNetwork(field[21]),
          }
        end
        return data
      end
      
      def cmdCheckCon
        url = URI.encode_www_form(
          {
            "check_connectivity" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return true
      end

      def cmdPlayerCreate
        url = URI.encode_www_form(
          {
            "player_create" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        data["id"] = fields[0][0][0].to_i
        data["password"] = fields[0][0][1]
        data["sid"] = fields[0][0][2]
        return data
      end

      def cmdPlayerSetName(id, name)
        url = URI.encode_www_form(
          {
            "player_set_name" => "",
            "id" => id,
            "name" => name,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        return true
      end

      def cmdTutorialPlayerSetName(id, name, tutorial)
        url = URI.encode_www_form(
          {
            "tutorial_player_set_name" => "",
            "id_player" => id,
            "name" => name,
            "tutorial" => tutorial,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdAuthGoogle(code)
        url = URI.encode_www_form(
          {
            "auth_google_new" => "",
            "authCode" => code,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        return response
      end
      
      def cmdAuthIdPassword
        url = URI.encode_www_form(
          {
            "auth_id_password" => "",
            "id_player" => @config["id"],
            "password" => @config["password"],
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        data["sid"] = fields[0][0][3]
        return data
      end

      def cmdNetGetForMaint
        url = URI.encode_www_form(
          {
            "net_get_for_maintenance" => 1,
            "id_player" => @config["id"],
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        fields = parseData(response)
        data = Hash.new

        data["nodes"] = parseNodes(fields[0])
        data["net"] = parseNetwork(fields[1][0][1])
        data["profile"] = parseProfile(fields[2][0])

        data["programs"] = Hash.new
        fields[3].each_index do |i|
          data["programs"][fields[3][i][0].to_i] = {
            "type" => fields[3][i][2].to_i,
            "level" => fields[3][i][3].to_i,
            "amount" => fields[3][i][4].to_i,
          }
        end

        data["readme"] = fields.dig(11, 0, 0)&.split("\x04") || []

        data["logs"] = Hash.new
        fields[9].each_index do |i|
          data["logs"][fields[9][i][0].to_i] = {
            "date" => fields[9][i][1],
            "id" => fields[9][i][2].to_i,
            "target" => fields[9][i][3].to_i,
            "idName" => fields[9][i][9],
            "targetName" => fields[9][i][10],
          }
        end
        
        return data
      end

      def cmdUpdateNet(net)
        url = URI.encode_www_form(
          {
            "net_update" => 1,
            "id_player" => @config["id"],
            "net" => generateNetwork(net),
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return true
      end

      def cmdCreateNodeUpdateNet(type, net)
        url = URI.encode_www_form(
          {
            "create_node_and_update_net" => 1,
            "id_player" => @config["id"],
            "id_node" => type,
            "net" => generateNetwork(net),
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdDeleteNodeUpdateNet(id, net)
        url = URI.encode_www_form(
          {
            "node_delete_update_net" => 1,
            "id_player" => @config["id"],
            "id" => id,
            "net" => generateNetwork(net),
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdUpgradeNode(id)
        url = URI.encode_www_form(
          {
            "upgrade_node" => 1,
            "id" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdTutorialUpgradeNode(id, node, tutorial)
        url = URI.encode_www_form(
          {
            "tutorial_upgrade_node" => 1,
            "id_player" => id,
            "id_node" => node,
            "tutorial" => tutorial,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdFinishNode(id)
        url = URI.encode_www_form(
          {
            "finish_node" => 1,
            "id" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end
      
      def cmdCollectNode(id)
        url = URI.encode_www_form(
          {
            "collect" => 1,
            "id_node" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return true
      end

      def cmdNodeSetBuilders(id, builders)
        url = URI.encode_www_form(
          {
            "node_set_builders" => 1,
            "id_node" => id,
            "builders" => builders,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdCreateProgram(type)
        url = URI.encode_www_form(
          {
            "create_program" => 1,
            "id_player" => @config["id"],
            "id_program" => type,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdUpgradeProgram(id)
        url = URI.encode_www_form(
          {
            "upgrade_program" => 1,
            "id" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdFinishProgram(id)
        url = URI.encode_www_form(
          {
            "finish_program" => 1,
            "id" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdDeleteProgram(id, programs)
        data = String.new
        programs.each do |program|
          data += program.join(",") + ";"
        end
        url = URI.encode_www_form(
          {
            "program_delete" => "",
            "id_player" => id,
            "data" => data,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdQueueSync(programs, seq)
        data = String.new
        programs.each do |program|
          data += program.join(",") + ";"
        end
        url = URI.encode_www_form(
          {
            "queue_sync_new" => 1,
            "id_player" => @config["id"],
            "data" => data,
            "seq" => seq,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdQueueSyncFinish(programs)
        data = String.new
        programs.each do |program|
          data += program.join(",") + ";"
        end
        url = URI.encode_www_form(
          {
            "queue_sync_and_finish_new" => 1,
            "id_player" => @config["id"],
            "data" => data,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end
      
      def cmdPlayerWorld(country)
        url = URI.encode_www_form(
          {
            "player_get_world" => 1,
            "id" => @config["id"],
            "id_country" => country,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, true)
        fields = parseData(response)
        data = Hash.new

        data["targets"] = Hash.new
        fields[0].each_index do |i|
          data["targets"][fields[0][i][0].to_i] = {
            "name" => fields[0][i][1],
          }
        end

        data["bonuses"] = Hash.new
        fields[1].each_index do |i|
          data["bonuses"][fields[1][i][0].to_i] = {
            "amount" => fields[1][i][2].to_i,
          }
        end

        data["goals"] = Hash.new
        fields[4].each_index do |i|
          data["goals"][fields[4][i][0].to_i] = {
            "type" => fields[4][i][1],
            "finished" => fields[4][i][3].to_i,
          }
        end
        
        return data
      end

      def cmdGetNewTargets
        url = URI.encode_www_form(
          {
            "player_get_new_targets" => 1,
            "id" => @config["id"],
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[0].to_i] = {
            "name" => field[1],
          }
        end
        return data
      end

      def cmdBonusCollect(id)
        url = URI.encode_www_form(
          {
            "bonus_collect" => 1,
            "id" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return true
      end

      def cmdGoalUpdate(id, record)
        url = URI.encode_www_form(
          {
            "goal_update" => "",
            "id" => id,
            "record" => record,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        fields = parseData(response)
        data = {
          "status" => fields[0][0][0],
          "credits" => fields[0][0][1],
        }
        return data
      end

      def cmdGoalReject(id)
        url = URI.encode_www_form(
          {
            "goal_reject" => "",
            "id" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return true
      end
      
      def cmdChatDisplay(room, last = "")
        url = URI.encode_www_form(
          {
            "chat_display" => "",
            "room" => room,
            "last_message" => last,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        fields = parseData(response)
        data = Array.new
        unless fields.empty?
          fields[0].each_index do |i|
            data.append({
                          "datetime" => fields[0][i][0],
                          "nick" => fields[0][i][1],
                          "message" => normalizeData(fields[0][i][2]),
                          "id" => fields[0][i][3].to_i,
                        })
          end
        end
        return data.reverse
      end

      def cmdChatSend(room, message, last = "")
        message = normalizeData(message, true)
        url = URI.encode_www_form(
          {
            "chat_send" => "",
            "room" => room,
            "last_message" => last,
            "message" => message,
            "id_player" => @config["id"],
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        fields = parseData(response)
        data = Array.new
        unless fields.empty?
          fields[0].each_index do |i|
            data.append({
                          "datetime" => fields[0][i][0],
                          "nick" => fields[0][i][1],
                          "message" => normalizeData(fields[0][i][2]),
                          "id" => fields[0][i][3].to_i,
                        })
          end
        end
        return data.reverse
      end

      def cmdNetGetForAttack(target)
        url = URI.encode_www_form(
          {
            "net_get_for_attack" => 1,
            "id_target" => target,
            "id_attacker" => @config["id"],
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        fields = parseData(response)
        data = Hash.new
        data["profile"] = parseProfile(fields[2][0])
        data["net"] = parseNetwork(fields[1][0][1])
        return data
      end

      def cmdNetLeave(target)
        url = URI.encode_www_form(
          {
            "net_leave" => 1,
            "id_attacker" => @config["id"],
            "id_target" => target,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdFightUpdate(target, data)
        url = URI.encode_www_form(
          {
            "fight_update_running" => 1,
            "attackerID" => @config["id"],
            "targetID" => target,
            "goldMainLoot" => data[:money],
            "bcMainLoot" => data[:bitcoin],
            "nodeIDsList" => data[:nodes],
            "nodeLootValues" => data[:loots],
            "attackSuccess" => data[:success],
            "usedProgramsList" => data[:programs],
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdFight(target, data)
        url = URI.encode_www_form(
          {
            "fight" => 1,
            "attackerID" => @config["id"],
            "targetID" => target,
            "goldMainLoot" => data[:money],
            "bcMainLoot" => data[:bitcoin],
            "nodeIDsList" => data[:nodes],
            "nodeLootValues" => data[:loots],
            "attackSuccess" => data[:success],
            "usedProgramsList" => data[:programs],
            "summaryString" => data[:summary],
            "replayVersion" => data[:version],
            "keepLock" => 1,
            "app_version" => @config["version"],
          }
        )
        data = URI.encode_www_form(
          {
            "replayString" => data[:replay],
          }
        )
        response = request(url, true, true, data)
        return response
      end

      def cmdTutorialPlayerMissionUpdate(mission, data)
        url = URI.encode_www_form(
          {
            "tutorial_player_mission_update" => 1,
            "id_player" => @config["id"],
            "id_mission" => mission,
            "money_looted" => data[:money],
            "bcoins_looted" => data[:bitcoin],
            "finished" => data[:finished],
            "nodes_currencies" => data[:finished],
            "programs_data" => data[:programs],
            "tutorial" => data[:tutorial],
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdFightGetReplay(id)
        url = URI.encode_www_form(
          {
            "fight_get_replay" => 1,
            "id" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdGetMissionFight(id, mission)
        url = URI.encode_www_form(
          {
            "get_mission_fight" => 1,
            "id_mission" => mission,
            "id_attacker" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdPlayerGetInfo(id)
        url = URI.encode_www_form(
          {
            "player_get_info" => "",
            "id" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)

        fields = parseData(response)
        profile = parseProfile(fields[0][0])
        return profile
      end

      def cmdGetNetDetailsWorld(id)
        url = URI.encode_www_form(
          {
            "get_net_details_world" => 1,
            "id_player" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        fields = parseData(response)
        data = Hash.new
        data["profile"] = parseProfile(fields[0][0])
        data["nodes"] = parseNodes(fields[1])
        return data
      end

      def cmdSetPlayerHqCountry(id, x, y, country)
        url = URI.encode_www_form(
          {
            "set_player_hq_and_country" => 1,
            "id_player" => id,
            "hq_location_x" => x,
            "hq_location_y" => y,
            "id_country" => country,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end
      
      def cmdPlayerHqMove(x, y, country)
        url = URI.encode_www_form(
          {
            "player_hq_move" => 1,
            "id" => @config["id"],
            "hq_location_x" => x,
            "hq_location_y" => y,
            "country" => country,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdHqMoveGetPrice
        url = URI.encode_www_form(
          {
            "hq_move_get_price" => "",
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdPlayerSetSkin(skin)
        url = URI.encode_www_form(
          {
            "player_set_skin" => "",
            "id" => @config["id"],
            "skin" => skin,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdPlayerBuySkin(skin)
        url = URI.encode_www_form(
          {
            "player_buy_skin" => "",
            "id" => @config["id"],
            "id_skin" => skin,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end
    
      def cmdSkinTypesGetList
        url = URI.encode_www_form(
          {
            "skin_types_get_list" => "",
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[0]] = {
            "name" => field[1],
            "price" => field[2].to_i,
            "rank" => field[3].to_i,
          }
        end
        return data
      end
      
      def cmdShieldBuy(shield)
        url = URI.encode_www_form(
          {
            "buy_shield" => "",
            "id_player" => @config["id"],
            "id_shield_type" => shield,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdPlayerBuyCurrencyPerc(currency, perc)
        url = URI.encode_www_form(
          {
            "player_buy_currency_percentage" => 1,
            "id" => @config["id"],
            "currency" => currency,
            "max_storage_percentage" => perc,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdRankingGetAll(country)
        url = URI.encode_www_form(
          {
            "ranking_get_all" => "",
            "id_player" => @config["id"],
            "id_country" => country,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        fields = parseData(response)
        data = {
          "nearby" => [],
          "country" => [],
          "world" => [],
          "countries" => [],
        }

        for i in 0..2 do
          case i
          when 0
            type = "nearby"
          when 1
            type = "country"
          when 2
            type = "world"
          end
          
          fields[i].each do |field|
            data[type].push({
              "id" => field[0],
              "name" => field[1],
              "experience" => field[2],
              "country" => field[3],
              "rank" => field[4],
            })
          end
        end

        fields[3].each do |field|
            data["countries"].push({
              "country" => field[0],
              "rank" => field[1],
            })
          end
                
        return data
      end

      def cmdPlayerMissionsGetLog
        url = URI.encode_www_form(
          {
            "player_missions_get_log" => "",
            "id" => @config["id"],
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[1]] = {
            "money" => field[2].to_i,
            "bitcoin" => field[3].to_i,
            "date" => field[5],
          }
        end
        return data
      end

      def cmdPlayerSetReadme(text)
        url = URI.encode_www_form(
          {
            "player_set_readme" => "",
            "id" => @config["id"],
            "text" => text,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return true
      end

      def cmdPlayerSetReadmeFight(target, text)
        url = URI.encode_www_form(
          {
            "player_set_readme_fight" => "",
            "id_attacker" => @config["id"],
            "id_target" => target,
            "text" => text,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return true
      end

      def cmdGoalByPlayer
        url = URI.encode_www_form(
          {
            "goal_by_player" => "",
            "id_player" => @config["id"],
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdNewsGetList
        url = URI.encode_www_form(
          {
            "news_get_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[0]] = {
            "date" => field[1],
            "title" => normalizeData(field[2]),
            "body" => normalizeData(field[3]),
          }
        end
        return data
      end

      def cmdHintsGetList
        url = URI.encode_www_form(
          {
            "hints_get_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[0].to_i] = {
              "description" => field[1],
            }
        end
        return data
      end

      def cmdWorldNewsGetList
        url = URI.encode_www_form(
          {
            "world_news_get_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        return response
      end

      def cmdGetExperienceList
        url = URI.encode_www_form(
          {
            "get_experience_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[0].to_i] = {
            "level" => field[1].to_i,
            "experience" => field[2].to_i,
          }
        end
        return data
      end

      def cmdBuildersCountGetList
        url = URI.encode_www_form(
          {
            "builders_count_get_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[0].to_i] = {
              "amount" => field[0].to_i,
              "price" => field[1].to_i,
            }
        end
        return data
      end

      def cmdGoalTypesGetList
        url = URI.encode_www_form(
          {
            "goal_types_get_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[1]] = {
            "amount" => field[2].to_i,
            "name" => field[7],
            "description" => field[8],
          }
        end
        return data
      end

      def cmdShieldTypesGetList
        url = URI.encode_www_form(
          {
            "shield_types_get_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[0].to_i] = {
              "price" => field[3].to_i,
              "name" => field[4],
              "description" => field[5],
            }
        end
        return data
      end

      def cmdRankGetList
        url = URI.encode_www_form(
          {
            "rank_get_list" => 1,
            "app_version" => @config["version"],
          }
        )
        response = request(url, true, false)
        fields = parseData(response)
        data = Hash.new
        fields[0].each do |field|
          data[field[0].to_i] = {
            "rank" => field[1].to_i,
          }
        end
        return data
      end

      def cmdFightGetMap
        url = URI.encode_www_form(
          {
            "fight_get_map" => "",
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdCreateException(name, exception, version)
        url = URI.encode_www_form(
          {
            "exception_create" => 1,
            "player_name" => name,
            "app_version_number" => version,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdCreateReport(repoter, reported, message)
        url = URI.encode_www_form(
          {
            "report_create" => "",
            "id_reporter" => reporter,
            "id_reported" => reported,
            "message" => message,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdPlayerSetTutorial(id, tutorial)
        url = URI.encode_www_form(
          {
            "player_set_tutorial" => "",
            "id" => id,
            "tutorial" => tutorial,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdPlayerBuyBuilder(id)
        url = URI.encode_www_form(
          {
            "player_buy_builder" => "",
            "id" => id,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdTutorialPlayerBuyBuilder(id, tutorial)
        url = URI.encode_www_form(
          {
            "tutorial_player_buy_builder" => "",
            "id_player" => id,
            "tutorial" => tutorial,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        return response
      end

      def cmdCpUseCode(id, code, platform)
        url = URI.encode_www_form(
          {
            "cp_use_code" => "",
            "id_player" => id,
            "code" => code,
            "platform" => platform,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        data = parseData(response)
        return {
          "id" => data[0][0][0],
          "password" => data[0][0][1],
        }
      end

      def cmdCpGenerateCode(id, platform)
        url = URI.encode_www_form(
          {
            "cp_generate_code" => "",
            "id_player" => id,
            "platform" => platform,
            "app_version" => @config["version"],
          }
        )
        response = request(url)
        data = parseData(response)
        return data[0][0][0]
      end
    end
  end
end
