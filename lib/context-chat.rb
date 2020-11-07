module Sandbox
  class ContextChat < ContextBase
    def initialize(game, shell)
      @rooms = Hash.new
      super(game, shell)
      @commands.merge!({
        "open"  => ["open <room>", "Open room"],
        "close" => ["close <room>", "Close room"],
        "list"  => ["list", "List opened rooms"],
        "say"   => ["say <room> <text>", "Say to the room"],
        "talk"  => ["talk <room>", "Talk in the room"],
        "users" => ["users <room>", "Show users list in the room"],
       })
      @mutex = Mutex.new
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
        
        @rooms[room] = {
          "chat"    => @game.getChat(room),
          "thread"  => Thread.new {read(room)},
        }
        return

      when "list"
        if @rooms.empty?
          @shell.puts "#{cmd}: No opened rooms"
          return
        end
        
        @shell.puts "Opened rooms:"
        @rooms.each_key do |k|
          @shell.puts " \e[1;33m\u2022\e[0m %-4d (%s)" % [k, @game.countriesList.fetch(k.to_s, "Unknown")]
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

        @rooms[room]["thread"].kill
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

        messages = Array.new
        @mutex.synchronize do
          messages = @rooms[room]["chat"].write(words[2..-1].join(" "))
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("Chat write (#{e})")
          return
        end
        log(room, messages)
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
          messages = Array.new
          @mutex.synchronize do
            messages = @rooms[room]["chat"].write(message)
          rescue Trickster::Hackers::RequestError => e
            @shell.logger.error("Chat write (#{e})")
            next
          end
          log(room, messages)
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
      room = words[1].to_i

      chat = @game.getChat(room)
      begin
        messages = chat.read
      rescue Trickster::Hackers::RequestError => e
        @shell.logger.error("Chat read (#{e})")
        return
      end

      if messages.empty?
        @shell.puts "No users in room #{room}"
        return
      end

      messages.uniq! {|m| m.id}
      @shell.puts "Users in room %d (%s)" % [room, @game.countriesList.fetch(room.to_s, "Unknown")]
      messages.each do |message|
        @shell.puts " %-30s .. %d" % [message.nick, message.id]
      end
      return

      end

      super(words)
    end

    def log(room, messages)
      messages.each do |message|
        @shell.puts(
          "\e[1;33m\u2764 \e[22;34m[%s:%d] \e[22;31m%d \e[1;35m%s \e[22;33m%s\e[0m" % [
            @game.countriesList.fetch(room.to_s, "Unknown"),
            room,
            @game.getLevelByExp(message.experience),
            message.nick,
            message.message,
          ],
        )
      end
    end
    
    def read(room)
      loop do
        @mutex.synchronize do
          messages = @rooms[room]["chat"].read
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("Chat read (#{e})")
        else
          log(room, messages)
        end
        
        sleep(@game.appSettings["chat_refresh_interval"].to_i)
      end
    end
  end
end

