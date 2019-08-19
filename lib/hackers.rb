module Trickster
  module Hackers
    require "net/http"
    require "digest"
    require "base64"

    NODES_TYPES = {
      7 => "Core",
      8 => "Internet",
      11 => "Server farm",
      12 => "Database",
      13 => "Bitcoin Mine",
      14 => "Bitcoin Mixer",
      15 => "Sentry",
      22 => "Compiler",
      27 => "AI Hawk",
    }
    PROGRAMS_TYPES = {
      3 => "Beam cannon",
      4 => "Shuriken",
      5 => "Worms",
      6 => "Blaster",
      8 => "Data leech",
      9 => "Battering Ram",
      12 => "Protector",
      11 => "Ice wall",
      18 => "Access",
      22 => "AI Hawk",
    }
    
    class Game
      attr_accessor :config, :appSettings, :transLang
      
      def initialize(config)
        @config = config
        @appSettings = Hash.new
        @transLang = Hash.new
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
        request = URI::encode(request)
        request += "&cmd_id=" + hashUrl(request) if cmd
        return request
      end
      
      def request(url, cmd = true, session = true)
        response = nil
        @mutex.synchronize do
          response = @client.get(
            makeUrl(url, cmd, session),
            {
              "Content-Type" => "application/x-www-form-urlencoded",
              "Accept-Charset" => "utf-8",
              "Accept-Encoding" => "gzip",
              "User-Agent" => "UniWeb (http://www.differentmethods.com)",
            },
          )
        rescue
          return false
        end
        return false unless response.code == "200"
        return response.body
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
      
      def cmdTransLang
        url = "i18n_translations_get_language=1" +
              "&language_code=#{@config["language"]}" +
              "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response
        data = Hash.new
        response.split(";").each do |record|
          fields = record.split(",")
          data[fields[0]] = fields[1]
        end
        return data
      end
      
      def cmdAppSettings
        url = "app_setting_get_list=1" +
              "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response
        data = Hash.new
        records = response.split(";")
        
        for i in (0..10) do
          fields = records[i].split(",")
          data[fields[1]] = fields[2..3]
        end
        
        data["datetime"] = records[11]

        data["languages"] = Hash.new
        records[12].split(",").each do |field|
          language = field.split(":")
          data["languages"][language[0]] = language[1]
        end

        for i in (13..17) do
          fields = records[i].split(",")
          data[fields[0]] = fields[1]
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
        data = Hash.new
        records = response.split(";")
        fields = records[0].split(",")
        data["id"] = fields[0].to_i
        data["password"] = fields[1]
        data["sid"] = fields[2]
        return data
      end
      
      def cmdAuthIdPassword
        url = "auth_id_password" +
              "&id_player=#{@config["id"].to_s}" +
              "&password=#{@config["password"]}" +
              "&app_version=#{@config["version"]}"
        response = request(url, true, false)
        return false unless response
        data = Hash.new
        sections = response.split("@")
        records = sections[0].split(";")
        fields = records[0].split(",")
        data["sid"] = fields[3]
        return data
      end

      def cmdNetGetForMaint
        url = "net_get_for_maintenance=1" +
              "&id_player=#{@config["id"]}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        data = Hash.new
        sections = response.split("@")

        data["nodes"] = Hash.new
        nodes = sections[0].split(";")
        nodes.each do |node|
          fields = node.split(",")
          data["nodes"][fields[0].to_i] = {
            "type" => fields[2].to_i,
            "level" => fields[3].to_i,
            "time" => fields[4].to_i,
          }
        end

        data["profile"] = Hash.new
        profile = sections[2].split(";").first.split(",")
        data["profile"] = {
          "id" => profile[0].to_i,
          "name" => profile[1],
          "money" => profile[2].to_i,
          "bitcoin" => profile[3].to_i,
          "credit" => profile[4].to_i,
          "reputation" => profile[9].to_i,
          "thread" => profile[10].to_i,
          "country" => profile[13].to_i,
        }

        data["programs"] = Hash.new
        programs = sections[3].split(";")
        programs.each do |program|
          fields = program.split(",")
          data["programs"][fields[0].to_i] = {
            "type" => fields[2].to_i,
            "level" => fields[3].to_i,
            "amount" => fields[4].to_i,
          }
        end

        data["readme"] = sections[11].split(";").first

        data["logs"] = Hash.new
        logs = sections[9].split(";")
        logs.each do |log|
          fields = log.split(",")
          data["logs"][fields[0].to_i] = {
            "date" => fields[1],
            "id" => fields[2].to_i,
            "target" => fields[3].to_i,
            "idName" => fields[9],
            "targetName" => fields[10],
          }
        end
        
        return data
      end

      def cmdCollect(id)
        url = "collect=1" +
              "&id_node=#{id}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        return true
      end
      
      def cmdChatDisplay(room, last = "")
        url = "chat_display" +
              "&room=#{room.to_s}" +
              "&last_message=#{last}" +
              "&app_version=#{@config["version"]}"
        response = request(url)
        return false unless response
        data = Array.new
        response.force_encoding("utf-8")
        records = response.split(";")
        records.each do |record|
          fields = record.split(",")
          data.append({
                        "datetime" => fields[0],
                        "nick" => fields[1],
                        "message" => normalizeData(fields[2]),
                        "id" => fields[3].to_i,
                      })
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
        data = Array.new
        response.force_encoding("utf-8")
        records = response.split(";")
        records.each do |record|
          fields = record.split(",")
          data.append({
                        "datetime" => fields[0],
                        "nick" => fields[1],
                        "message" => normalizeData(fields[2]),
                        "id" => fields[3].to_i,
                      })
        end
        return data.reverse
      end
    end
  end
end
