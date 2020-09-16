module Sandbox
  class ContextChat < ContextBase
    def initialize(game, shell)
      @rooms = Hash.new
      super(game, shell)
      @commands.merge!({
                         "open" => ["open <room>", "Open room"],
                         "close" => ["close <room>", "Close room"],
                         "list" => ["list", "List opened rooms"],
                         "say" => ["say <room> <text>", "Say to the room"],
                         "talk" => ["talk <room>", "Talk in the room"],
                         "users" => ["users <room>", "Show users list in the room"],
                       })
      @mutex = Mutex.new
      @logger = Logger.new(@shell)
      @logger.logPrefix = "\e[1;33m\u2764\e[22;33m "
      @logger.logSuffix = "\e[0m"
    end

    def exec(words)
      cmd = words[0].downcase
      case cmd

      when "open"
        if @game.sid.empty? || @game.appSettings.empty?
          @shell.puts "#{cmd}: Not connected"
          return
        end

        if words[1].nil?
          @shell.puts "#{cmd}: Specify room ID"
          return
        end

        room = words[1].to_i
        if @rooms.key?(room)
          @shell.puts("#{cmd}: Room #{room} already opened")
          return
        end
        
        @rooms[room] = [
          Thread.new {chat(room)},
          String.new,
        ]
        return

      when "list"
        if @rooms.empty?
          @shell.puts "#{cmd}: No opened rooms"
          return
        end
        
        @shell.puts "Opened rooms:"
        @rooms.each_key do |k|
          @shell.puts " \e[1;33m\u2022\e[0m %d" % k
        end
        return
        
      when "close"
        if words[1].nil?
          @shell.puts "#{cmd}: Specify room ID"
          return
        end

        room = words[1].to_i
        unless @rooms.key?(room)
          @shell.puts "#{cmd}: No such opened room"
          return
        end

        @rooms[room][0].kill
        @rooms.delete(room)
        return

      when "say"
        if words[1].nil?
          @shell.puts "#{cmd}: Specify room ID"
          return
        end

        room = words[1].to_i
        if words[2].nil?
          @shell.puts "#{cmd}: Specify message"
          return
        end

        unless @rooms.key?(room)
          @shell.puts("#{cmd}: No such opened room")
          return
        end

        response = nil
        @mutex.synchronize do
          begin
            response = @game.cmdChatSend(
              room,
              words[2..-1].join(" "),
              @rooms[room][1],
            )
          rescue Trickster::Hackers::RequestError => e
            @shell.logger.error("Chat send (#{e})")
            return
          end
          logMessages(room, response)
        end
        return

      when "talk"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify room ID")
          return
        end

        room = words[1].to_i
        unless @rooms.key?(room)
          @shell.puts("#{cmd}: No such opened room")
          return
        end

        @shell.puts("Enter ! to quit")
        loop do
          @shell.reading = true
          message = Readline.readline("#{room} \e[1;33m\u2765\e[0m ", true)
          @shell.reading = false
          break if message.nil?
          message.strip!
          Readline::HISTORY.pop if message.empty?
          next if message.empty?
          break if message == "!"
          response = nil
          @mutex.synchronize do
            begin
              response = @game.cmdChatSend(
                room,
                message,
                @rooms[room][1],
              )
            rescue Trickster::Hackers::RequestError => e
              @shell.logger.error("Chat send (#{e})")
              next
            end
            logMessages(room, response)
          end
        end
        return
        
    when "users"
      if @game.sid.empty? || @game.appSettings.empty?
        @shell.puts "#{cmd}: Not connected"
        return
      end

      if words[1].nil?
        @shell.puts("#{cmd}: Specify room ID")
        return
      end

      messages = nil
      @mutex.synchronize do
        messages = @game.cmdChatDisplay(words[1])
      rescue Trickster::Hackers::RequestError => e
        @shell.logger.error("Chat display (#{e})")
        return
      end

      if messages.empty?
        @shell.puts "No users in room #{words[1]}"
        return
      end

      messages.uniq! {|m| m["id"]}
      @shell.puts "Users:"
      messages.each do |message|
        @shell.puts " %-30s .. %d" % [message["nick"], message["id"]]
      end
      return

      end

      super(words)
    end

    def logMessages(room, messages)
      messages.each do |message|
        @logger.log(
          "(%d) %s: %s" % [
            room,
            message["nick"],
            message["message"],
          ],
        )
        @rooms[room][1] = message["datetime"]
      end
    end
    
    def chat(room)
      loop do
        @mutex.synchronize do
          messages = @game.cmdChatDisplay(room, @rooms[room][1])
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("Chat display (#{e})")
        else
          logMessages(room, messages)
        end
        
        sleep(@game.appSettings["chat_refresh_interval"].to_i)
      end
    end
  end
end

