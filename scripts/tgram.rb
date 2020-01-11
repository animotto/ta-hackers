class Tgram < Sandbox::Script
  DATA_DIR = "#{Sandbox::ContextScript::SCRIPTS_DIR}/tgram"
  TELEGRAM_ADDRESS = "api.telegram.org"
  TELEGRAM_PORT = 443
  INTERVAL = 10
  
  def initialize(game, shell, args)
    super(game, shell, args)
    Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)
  end
  
  def main
    chats = Array.new
    chatsFile = "#{DATA_DIR}/chats.json"
    if File.file?(chatsFile)
      begin
        chats = JSON.parse(File.read(chatsFile))
      rescue => e
        @shell.log("Invalid file format of chats: #{e}")
        return
      end
    end

    if @game.config["tgramToken"].nil?
      @shell.log("No Telegram token", :script)
      return
    end

    room = @args[0]
    if room.nil?
      @shell.log("Specify room ID", :script)
      return
    end
    
    updateId = 0
    last = String.new
    loop do
      sleep(INTERVAL)

      begin
        messages = @game.cmdChatDisplay(room, last)
      rescue Trickster::Hackers::RequestError => e
        @shell.log("#{e}", :script)
        next
      end

      messages.each do |message|
        if last.empty?
          if message == messages.last
            last = message["datetime"]
            break
          end
          next
        end
        
        last = message["datetime"]
        chats.each do |chat|
          sendMessage(chat, "#{message["nick"]}: #{message["message"]}")
        end
      end
      
      next unless updates = getUpdates(updateId)
      updates["result"].each do |update|
        updateId = update["update_id"] + 1
        message = update["message"]
        case message["text"]

        when "/start"
          chats.append(message["chat"]["id"]) unless chats.include?(message["chat"]["id"])
          File.write(chatsFile, JSON.generate(chats))

        when "/stop"
          chats.delete(message["chat"]["id"]) if chats.include?(message["chat"]["id"])
          File.write(chatsFile, JSON.generate(chats))

        else
          if chats.include?(message["chat"]["id"])
            begin
              @game.cmdChatSend(room, "@#{message["chat"]["first_name"]}: #{message["text"]}", last)
            rescue Trickster::Hackers::RequestError => e
              @shell.log("#{e}", :script)
              next
            end
          end
          
        end
      end
    end
  end

  def request(url)
    client = Net::HTTP.new(TELEGRAM_ADDRESS, TELEGRAM_PORT)
    client.use_ssl = true
    response = client.get("/bot#{@game.config["tgramToken"]}/#{url}")
    return false unless response || response.code == 200
    return response.body
  end

  def getUpdates(offset = 0)
    response = request("getUpdates?offset=#{offset}")
    return false unless response
    return JSON.parse(response)
  end

  def sendMessage(id, text)
    data = URI.encode(text)
    response = request("sendMessage?chat_id=#{id}&text=#{data}")
    return false unless response
    return JSON.parse(response)
  end
end
