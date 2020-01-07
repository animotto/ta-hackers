module Trickster
  module Hackers
    require "net/http"
    require "digest"
    require "base64"

    class Game
      attr_accessor :config, :appSettings, :transLang,
                    :nodeTypes, :programTypes
      
      def initialize(config)
        @config = config
        @appSettings = Hash.new
        @transLang = Hash.new
        @nodeTypes = Hash.new
        @programTypes = Hash.new
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
        request = URI.encode(request)
        request += "&cmd_id=" + hashUrl(request) if cmd
        return request
      end
      
      def request(url, cmd = true, session = true, data = "")
        response = nil
        header = {
          "Content-Type" => "application/x-www-form-urlencoded",
          "Accept-Charset" => "utf-8",
          "Accept-Encoding" => "gzip",
          "User-Agent" => "UniWeb (http://www.differentmethods.com)",
        }

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
        rescue
          return false
        end
        unless response.code == "200" ||
               (response.code == "500" && !response.body.empty?)
          return false
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
        records = data[0][1].split("|")
        coords = records[0].split("_")
        rels = records[1].split("_")
        nodes = records[2].split("_")
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
      
      def cmdTransLang
        url = "i18n_translations_get_language=1" +
              "&language_code=#{@config["language"]}" +
              "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response
        data = Hash.new
        fields = parseData(response)
        fields[0].each_index do |i|
          data[fields[0][i][0]] = fields[0][i][1]
        end
        return data
      end
      
      def cmdAppSettings
        url = "app_setting_get_list=1" +
              "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response
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
        url = "get_node_types_and_levels=1" +
              "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response
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
        url = "get_program_types_and_levels=1" +
              "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response
        fields = parseData(response)
        data = Hash.new
        fields[0].each_index do |i|
          data[fields[0][i][0].to_i] = {
            "name" => fields[0][i][2],
          }
        end
        return data
      end
      
      def cmdCheckCon
        url = "check_connectivity=1" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false if response.nil? || response != "1"
        return true
      end

      def cmdPlayerCreate
        url = "player_create=1" +
              "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response
        fields = parseData(response)
        data = Hash.new
        data["id"] = fields[0][0][0].to_i
        data["password"] = fields[0][0][1]
        data["sid"] = fields[0][0][2]
        return data
      end

      def cmdPlayerSetName(id, name)
        url = "player_set_name" +
            "&id=#{id}" +
            "&name=#{name}" +
            "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response || response == "ok"
        return true
      end
      
      def cmdAuthIdPassword
        url = "auth_id_password" +
              "&id_player=#{@config["id"].to_s}" +
              "&password=#{@config["password"]}" +
              "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response
        fields = parseData(response)
        data = Hash.new
        data["sid"] = fields[0][0][3]
        return data
      end

      def cmdNetGetForMaint
        url = "net_get_for_maintenance=1" +
              "&id_player=#{@config["id"]}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        fields = parseData(response)
        data = Hash.new

        data["nodes"] = Hash.new
        fields[0].each_index do |i|
          data["nodes"][fields[0][i][0].to_i] = {
            "type" => fields[0][i][2].to_i,
            "level" => fields[0][i][3].to_i,
            "time" => fields[0][i][4].to_i,
          }
        end

        data["net"] = parseNetwork(fields[1])
        
        data["profile"] = {
          "id" => fields[2][0][0].to_i,
          "name" => fields[2][0][1],
          "money" => fields[2][0][2].to_i,
          "bitcoin" => fields[2][0][3].to_i,
          "credit" => fields[2][0][4].to_i,
          "experience" => fields[2][0][5].to_i,
          "rank" => fields[2][0][9].to_i,
          "builder" => fields[2][0][10].to_i,
          "x" => fields[2][0][11].to_i,
          "y" => fields[2][0][12].to_i,
          "country" => fields[2][0][13].to_i,
          "skin" => fields[2][0][14].to_i,
        }

        data["programs"] = Hash.new
        fields[3].each_index do |i|
          data["programs"][fields[3][i][0].to_i] = {
            "type" => fields[3][i][2].to_i,
            "level" => fields[3][i][3].to_i,
            "amount" => fields[3][i][4].to_i,
          }
        end

        data["readme"] = fields[11][0][0]

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
        data = generateNetwork(net)
        url = "net_update=1" +
              "&id_player=#{@config["id"]}" +
              "&net=#{data}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response || response == "ok"
        return true
      end
      
      def cmdCollect(id)
        url = "collect=1" +
              "&id_node=#{id}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return true
      end

      def cmdPlayerWorld(country)
        url = "player_get_world=1" +
              "&id=#{config["id"]}" +
              "&id_country=#{country}" +
              "&app_version=#{config["version"]}"
        response = request(url, true, true)
        return false unless response
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
        url = "player_get_new_targets=1" +
              "&id=#{@config["id"]}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return true
      end

      def cmdBonusCollect(id)
        url = "bonus_collect=1" +
              "&id=#{id}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response || response == "ok"
        return true
      end

      def cmdGoalUpdate(id, record)
        url = "goal_update" +
              "&id=#{id}" +
              "&record=#{record}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        fields = parseData(response)
        data = {
          "status" => fields[0][0][0],
          "credits" => fields[0][0][1],
        }
        return data
      end
      
      def cmdChatDisplay(room, last = "")
        url = "chat_display" +
              "&room=#{room.to_s}" +
              "&last_message=#{last}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
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
        url = "chat_send" +
              "&room=#{room.to_s}" +
              "&last_message=#{last}" +
              "&message=#{message}" +
              "&id_player=#{@config["id"]}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
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
        url = "net_get_for_attack=1" +
              "&id_target=#{target}" +
              "&id_attacker=#{@config["id"]}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return response
      end

      def cmdNetLeave(target)
        url = "net_leave=1" +
              "&id_attacker=#{@config["id"]}" +
              "&id_target=#{target}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return response
      end

      def cmdFightUpdate(target, data)
        url = "fight_update_running=1" +
              "&attackerID=#{@config["id"]}" +
              "&targetID=#{target}" +
              "&goldMainLoot=#{data[:money]}" +
              "&bcMainLoot=#{data[:bitcoin]}" +
              "&nodeIDsList=#{data[:nodes]}" +
              "&nodeLootValues=#{data[:loots]}" +
              "&attackSuccess=#{data[:success]}" +
              "&usedProgramsList=#{data[:programs]}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return response
      end

      def cmdFight(target, data)
        url = "fight=1" +
              "&attackerID=#{@config["id"]}" +
              "&targetID=#{target}" +
              "&goldMainLoot=#{data[:money]}" +
              "&bcMainLoot=#{data[:bitcoin]}" +
              "&nodeIDsList=#{data[:nodes]}" +
              "&nodeLootValues=#{data[:loots]}" +
              "&attackSuccess=#{data[:success]}" +
              "&usedProgramsList=#{data[:programs]}" +
              "&summaryString=#{data[:summary]}" +
              "&replayVersion=#{data[:version]}" +
              "&app_version=#{@config["version"]}"
        data = "replayString=#{data["replay"]}"
        response = request(url, true, true, data)
        return false unless response
        return response
      end

      def cmdPlayerGetInfo(id)
        url = "player_get_info" +
              "&id=#{id}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response

        fields = parseData(response)
        data = {
          "id" => fields[0][0][0].to_i,
          "name" => fields[0][0][1],
          "money" => fields[0][0][2].to_i,
          "bitcoin" => fields[0][0][3].to_i,
          "credit" => fields[0][0][4].to_i,
          "experience" => fields[0][0][5].to_i,
          "rank" => fields[0][0][9].to_i,
          "builder" => fields[0][0][10].to_i,
          "x" => fields[0][0][11].to_i,
          "y" => fields[0][0][12].to_i,
          "country" => fields[0][0][13].to_i,
          "skin" => fields[0][0][14].to_i,
        }
        return data
      end

      def cmdPlayerHqMove(x, y, country)
        url = "player_hq_move=1" +
              "&id=#{@config["id"]}" +
              "&hq_location_x=#{x}" +
              "&hq_location_y=#{y}" +
              "&country=#{country}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return response
      end

      def cmdHqMoveGetPrice
        url = "hq_move_get_price" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return response
      end

      def cmdPlayerSetSkin(skin)
        url = "player_set_skin" +
              "&id=#{@config["id"]}" +
              "&skin=#{skin}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return response
      end

      def cmdPlayerBuySkin(skin)
        url = "player_buy_skin" +
              "&id=#{@config["id"]}" +
              "&id_skin=#{skin}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return response
      end

      def cmdShieldBuy(shield)
        url = "buy_shiled" +
              "&id_player=#{@config["id"]}" +
              "&id_shield_type=#{shield}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return response
      end

      def cmdPlayerBuyCurrencyPerc(currency, perc)
        url = "player_buy_currency_percentage=1" +
              "&id=#{@config["id"]}" +
              "&currency=#{currency}" +
              "&max_storage_percentage=#{perc}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return response
      end

      def cmdRankingGetAll(country)
        url = "ranking_get_all" +
              "&id_player=#{@config["id"]}" +
              "&id_country=#{country}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response

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
    end
  end
end
