# frozen_string_literal: true

require 'cgi'

class Telegram < Sandbox::Script
  DATA_DIR = "#{Sandbox::ContextScript::SCRIPTS_DIR}/telegram"
  TOKEN_VAR = 'telegram-token'
  CHAT_INTERVAL = 10
  TELEGRAM_INTERVAL = 1
  QUEUE_SIZE = 1000

  class API
    HOST = 'api.telegram.org'
    PORT = 443

    def initialize(token)
      @token = token
      @client = Net::HTTP.new(HOST, PORT)
      @client.use_ssl = (PORT == 443)
      @updateId = 0
      @mutex = Mutex.new
    end

    def getMe
      request("getMe")
    end

    def getUpdates
      updates = request(
        "getUpdates",
        {
          "offset" => @updateId,
        }
      )
      @updateId = updates.last["update_id"].to_i + 1 unless updates.empty?
      return updates
    end

    def sendMessage(chatId, text, parseMode = "HTML")
      request(
        "sendMessage",
        {
          "chat_id" => chatId,
          "text" => text,
          "parse_mode" => parseMode,
        }
      )
    end

    private

    def request(method, params = {})
      uri = "/bot#{@token}/#{method}"
      uri += "?" + encodeURI(params) unless params.empty?
      begin
        response = nil
        @mutex.synchronize do
          response = @client.get(uri)
        end
      rescue => e
        raise APIError.new("HTTP request", e.message)
      end

      begin
        data = JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise APIError.new("API parse", e.message)
      end

      raise APIError.new("API", data["description"]) unless data["ok"]
      raise APIError.new("API", "No result") if data["result"].nil?
      return data["result"]
    end

    def encodeURI(data)
      params = Array.new
      data.each do |k, v|
        params.push(
          [
            k,
            URI.encode_www_form_component(v).gsub("+", "%20"),
          ].join("=")
        )
      end
      return params.join("&")
    end
  end

  class APIError < StandardError
    def initialize(message, description = nil)
      @message = message
      @description = description
    end

    def to_s
      msg = @message
      msg += ": #{@description}" unless @description.nil?
      return msg
    end
  end

  def initialize(game, shell, logger, args)
    super
    Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)
    @api = API.new(@game.config[TOKEN_VAR])
    @queue = SizedQueue.new(QUEUE_SIZE)
  end

  def load
    file = "#{DATA_DIR}/main.conf"
    @config = Sandbox::Config.new(file)
    begin
      @config.load
    rescue JSON::ParserError => e
      @logger.error("Main config has invalid format (#{e})")
      return false
    rescue => e
      @config.merge!({
        "relays" => {},
      })
    end
    return true
  end

  def save
    begin
      @config.save
    rescue => e
      @logger.error("Can't save main config (#{e})")
    end
  end

  def admin(line)
    words = line.split(/\s+/)
    return if words.empty?
    case words[0]
      when "help", "?"
        return "Commands: me | relay <add|del> <room> <channel>"

      when "me"
        me = "Me:\n"
        @api.getMe.each do |k, v|
          me << " #{k}: #{v}\n"
        end
        return me

      when "relay"
        case words[1]
          when "add"
            room = words[2]
            channel = words[3]
            return "Specify room ID and channel name" if room.nil? || channel.nil?
            return "Relay for room #{room} already exists" if @config["relays"].key?(room)
            @config["relays"][room] = {
              "channel" => channel,
            }
            save
            return "Relay for room #{room} added"

          when "del"
            room = words[2]
            return "Specify room ID" if room.nil?
            return "Relay for room #{room} doesn't exist" unless @config["relays"].key?(room)
            @config["relays"].delete(room)
            save
            return "Relay for room #{room} deleted"

          else
            return "No relays" if @config["relays"].empty?
            relays = "Relays:\n"
            @config["relays"].each do |room, relay|
              relays << " #{room} -> #{relay["channel"]}\n"
            end
            return relays
        end

      else
        return "Unrecognized command #{words[0]}"
    end
  end

  def finish
    @queue_thread.kill unless @queue_thread.nil?
  end

  def queue
    time = Time.now
    loop do
      message = @queue.pop
      t = Time.now - time
      sleep(t) if t <= TELEGRAM_INTERVAL

      msg = message[:message].message.clone
      msg.gsub!(/\[([biusc]|sup|sub|[\da-f]{6})\]/i, '')
      msg = format(
        '<b>%<nick>s: </b>%<msg>s',
        nick: CGI.escape_html(message[:message].nick),
        msg: CGI.escape_html(msg)
      )
      time = Time.now
      begin
        @api.sendMessage(message[:channel], msg)
      rescue APIError => e
        @logger.error("Send message error, from chat room #{message[:room]} to channel #{message[:channel]} (#{e})")
        @logger.error(msg)
      end
    end
  end

  def main
    if @game.config[TOKEN_VAR].nil? || @game.config[TOKEN_VAR].empty?
      @logger.error("No telegram token")
      return
    end

    return unless load
    chat = Hash.new

    @config["relays"].each do |room, relay|
      chat[room] = @game.getChat(room)
      begin
        chat[room].read
      rescue Hackers::RequestError => e
        @logger.error("Chat read (#{e})")
        return
      end
      @logger.log("Relay chat room #{room} to channel #{relay["channel"]}")
    end

    @queue_thread = Thread.new { queue }

    loop do
      begin
        @api.getUpdates.each do |update|
          @logger.log("%d (%s): %s" % [
            update["message"]["from"]["id"],
            update["message"]["from"]["username"],
            update["message"]["text"],
          ])
        end
      rescue APIError => e
        @logger.error("Get updates error (#{e})")
      end

      @config["relays"].each do |room, relay|
        begin
          messages = chat[room].read
        rescue Hackers::RequestError => e
          @logger.error("Chat read (#{e})")
          next
        end

        messages.each do |message|
          @queue.push(
            {
              room: room,
              channel: relay['channel'],
              message: message
            },
            true
          )
        rescue ThreadError
          next
        end
      end

      sleep(CHAT_INTERVAL)
    end
  end
end
