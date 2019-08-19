# coding: utf-8
require "rss"

class Chatbot < Sandbox::Script
  DATA_DIR ||= "#{Sandbox::ContextScript::SCRIPTS_DIR}/chatbot"
  SLEEP_TIME ||= 10
  FLOOD_TIME ||= 15
  USER_REPEATS ||= 4
  
  attr_accessor :commands, :game, :shell,
                :room, :users, :userTimers,
                :userRepeat
  
  def initialize(game, shell, args)
    super(game, shell, args)
    Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)
    @commands = {
      "!помощь" => [CmdHelp.new(self)],
      "!формат" => [CmdFormat.new(self)],
      "!считалочка" => [CmdCounting.new(self)],
      "!рулетка" => [CmdRoulette.new(self)],
      "!печенька" => [CmdCookie.new(self)],
      "!бац" => [CmdClick.new(self)],
      "!топ" => [CmdTop.new(self)],
      "!лента" => [CmdLenta.new(self)],
      "!хабр" => [CmdHabr.new(self)],
      "!лор" => [CmdLor.new(self)],
      "!баш" => [CmdBash.new(self)],
      "!фраза" => [CmdPhrase.new(self)],
      "!анекдот" => [CmdJoke.new(self)],
      "!курс" => [CmdCurrency.new(self)],
      "привет" => [CmdHello.new(self), true],
      "!путин" => [CmdPutin.new(self), true],
      "!город" => [CmdCity.new(self)],
    }
    @commandsRandom = [
      "!считалочка",
      "!рулетка",
      "!печенька",
      "!топ",
      "!лента",
      "!хабр",
      "!лор",
      "!баш",
      "!фраза",
      "!анекдот",
      "!курс",
    ]
    @room = args[0]
    @users = Hash.new
    @userTimers = Hash.new
    @userRepeats = Hash.new
    @userRepeat = true
    @last = String.new
  end
  
  def main
    if @room.nil?
      @shell.log("Specify room ID", :script)
      return
    end

    @room = @room.to_i
    @shell.log("The bot listens room #{@room}", :script)
    loop do
      sleep(SLEEP_TIME)
      @commands.each_value {|v| v[0].poll}
      next unless messages = @game.cmdChatDisplay(@room, @last)
      messages.each do |message|
        cmd = message["message"].downcase
        @users[message["id"]] = message["nick"] unless message["id"] == @game.config["id"]
        if @last.empty?
          if message == messages.last
            @last = message["datetime"]
            break
          end
          next
        end
        
        @last = message["datetime"]
        next if message["id"] == @game.config["id"]
        @commands.each_value {|v| v[0].poll(message)}
       next if @userTimers.key?(message["id"]) && Time.now - @userTimers[message["id"]] <= FLOOD_TIME

        if (not @commands.key?(cmd)) && @userRepeat
          if @userRepeats.key?(message["id"])
            @userRepeats[message["id"]] += 1          
          else
            @userRepeats.clear
            @userRepeats[message["id"]] = 1
          end
          if @userRepeats[message["id"]] >= USER_REPEATS
            @userRepeats.clear
            cmd = @commandsRandom.sample
          end
        end
        
        next unless @commands.key?(cmd)
        @commands[cmd][0].exec(message)
        @userTimers[message["id"]] = Time.now
      end
    end
  end
end

class CmdBase
  def initialize(script)
    @script = script
  end

  def exec(message)
  end

  def poll(message = nil)
  end
  
  def rss(host, port, url)
    http = Net::HTTP.new(host, port)
    http.use_ssl = true if port == 443
    response = http.get(url)
    return false unless response.code == "200"
    return RSS::Parser.parse(response.body, false)
  end
end

class CmdHelp < CmdBase
  def exec(message)
    msg = "[b][77a9ff]ВОТ ЧТО Я УМЕЮ: "
    @script.commands.each do |k, v|
      msg += "#{k} " unless v[1]
    end
    @script.game.cmdChatSend(@script.room, msg)
  end
end

class CmdFormat < CmdBase
  def exec(message)
    msg = "[b][ffffff][ b ] - жирный, [ i ] - курсив, [ u ] - подчеркнутый, [ s ] - зачёркнутый, [rrggbb] - цвет в HEX формате"
    @script.game.cmdChatSend(@script.room, msg)
  end
end

class CmdCounting < CmdBase
  COUNTINGS ||= [
    "ШИШЕЛ-МЫШЕЛ, СЕЛ НА КРЫШУ, ШИШЕЛ-МЫШЕЛ, ВЗЯЛ % И ВЫШЕЛ!",
    "ПЛЫЛ ПО МОРЮ ЧЕМОДАН, В ЧЕМОДАНЕ БЫЛ ДИВАН, НА ДИВАНЕ ЕХАЛ СЛОН. КТО НЕ ВЕРИТ - % ВЫЙДИ ВОН!",
    "ЗА СТЕКЛЯННЫМИ ДВЕРЯМИ СИДИТ МИШКА С ПИРОГАМИ. МИШКА, МИШЕНЬКА ДРУЖОК! СКОЛЬКО СТОИТ ПИРОЖОК? ПИРОЖОК-ТО ПО РУБЛЮ, ВЫХОДИ %, Я ТЕБЯ ЛЮБЛЮ!",
    "ПОД ГОРОЮ У РЕКИ ЖИВУТ ГНОМЫ-СТАРИКИ. У НИХ КОЛОКОЛ ВЕСИТ, ПОЗОЛОЧЕННЫЙ ЗВОНИТ: ДИГИ-ДИГИ-ДИГИ-ДОН - ВЫХОДИ % СКОРЕЕ ВОН!",
    "КАК НА НАШЕМ СЕНОВАЛЕ, ДВЕ ЛЯГУШКИ НОЧЕВАЛИ. УТРОМ ВСТАЛИ, ЩЕЙ ПОЕЛИ, И ТЕБЕ % ВОДИТЬ ВЕЛЕЛИ!",
    "В ПОЛЕ МЫ НАШЛИ РОМАШКУ, ВАСИЛЕК, ГВОЗДИКУ, КАШКУ, КОЛОКОЛЬЧИК, МАК, ВЬЮНОК... НАЧИНАЙ % ПЛЕСТИ ВЬЮНОК!",
  ]
  def exec(message)
    msg = "[b][00ff00]#{COUNTINGS.sample}"
    msg.gsub!("%", "[ffff00]#{@script.users[@script.users.keys.sample]}[00ff00]")
    @script.game.cmdChatSend(@script.room, msg)
  end
end

class CmdRoulette < CmdBase
  def exec(message)
    if rand(1..6) == 3
      msg = "[b][ffff00]#{message["nick"]} [00ff00] ПИФ ПАФ! ТЫ УБИТ!"
    else
      msg = "[b][ffff00]#{message["nick"]} [00ff00]В ЭТОТ РАЗ ТЕБЕ ПОВЕЗЛО!"
    end
    @script.game.cmdChatSend(@script.room, msg)
  end
end

class CmdCookie < CmdBase
  def exec(message)
    if rand(0..1) == 0
      msg = "[00ff00]ТЫ МОЛОДЕЦ [ffff00]#{message["nick"]}[00ff00]! ВОТ ТВОЯ ПЕЧЕНЬКА!"
    else
      msg = "[00ff00]ФИГУШКИ ТЕБЕ [ffff00]#{message["nick"]}[00ff00], А НЕ ПЕЧЕНЬКА!"
    end
    @script.game.cmdChatSend(@script.room, msg)
  end
end

class CmdHello < CmdBase
  GREETINGS ||= [
    "ПРИВЕТ %!",
    "АЛОХА %!",
    "ЧО КАК %? КАК САМ?",
    "КАВАБАНГА %!",
    "КАК НАМ ТЕБЯ НЕ ХВАТАЛО %!",
    "ПРИВЕТСТВУЮ %!",
    "ВИДИЛИСЬ %!",
  ]
  
  def exec(message)
    msg = "[b][6aab7f]#{GREETINGS.sample} ЕСЛИ ТЕБЕ ИНТЕРЕСНО ЧТО Я УМЕЮ, ОТПРАВЬ В ЧАТ [ff35a0]!помощь"
    msg.gsub!("%", "[ff35a0]#{message["nick"]}[6aab7f]")
    @script.game.cmdChatSend(@script.room, msg)
  end
end

class CmdClick < CmdBase
  DATA_FILE ||= "#{Chatbot::DATA_DIR}/click.json"
  MESSAGES ||= [
    "ХАКЕРЮГИ СБАЦАЛИ УЖЕ % РАЗ!",
    "ХАКЕРЬЁ НЕ СПИТ! НАБАЦАЛИ % РАЗ!",
    "ЛАМЕРЮГИ НИКОГДА НЕ НАБАЦАЮТ % РАЗ!",
  ]

  def initialize(script)
    super(script)
    @counter = 0
    @users = Hash.new
    File.write(DATA_FILE, JSON.generate([@counter, @users])) unless File.file?(DATA_FILE)
  end

  def exec(message)
    begin
      @counter, @users = JSON.parse(File.read(DATA_FILE))
    rescue
    end
    @counter += 1
    @users[message["id"]] = [message["nick"], 0] unless @users.key?(message["id"])
    @users[message["id"]] = [message["nick"], @users[message["id"]][1] + 1]
    msg = "[b][ff3500]#{MESSAGES.sample} ПРИСОЕДИНЯЙСЯ!"
    msg.gsub!("%", "[ff9ea1]#{@counter}[ff3500]")
    @script.game.cmdChatSend(@script.room, msg)
    File.write(
      DATA_FILE,
      JSON.generate([@counter, @users]),
    )
  end
end

class CmdTop < CmdBase
  def exec(message)
    counter = 0
    users = Hash.new
    begin
      counter, users = JSON.parse(File.read(CmdClick::DATA_FILE))
    rescue
    end
    if users.nil? || users.empty?
      msg = "[b][7aff38]ЕЩЕ НИКТО НЕ СБАЦАЛ, ТЫ МОЖЕШЬ СТАТЬ ПЕРВЫМ!"
    else
      c = Array.new
      users.each do |k, v|
        if c.empty?
          c = v
          next
        end
        c = v if v[1] > c[1]
      end
      msg = "[b][ff312a]#{c[0]}[7aff38] ХАКЕРЮГА НОМЕР ОДИН! НАБАЦАЛ [ff312a]#{c[1]}[7aff38] РАЗ!"
    end
    @script.game.cmdChatSend(@script.room, msg)
  end
end

class CmdLenta < CmdBase
  def exec(message)
    if feed = rss("lenta.ru", 443, "/rss/news")
      msg = "[b][39fe12]" + feed.items.sample.title
      @script.game.cmdChatSend(@script.room, msg)
    end
  end
end

class CmdHabr < CmdBase
  def exec(message)
    if feed = rss("habr.com", 443, "/ru/rss/news/")
      msg = "[b][7aff51]" + feed.items.sample.title
      @script.game.cmdChatSend(@script.room, msg)
    end
  end
end

class CmdLor < CmdBase
  def exec(message)
    if feed = rss("www.linux.org.ru", 443, "/section-rss.jsp?section=1")
      msg = "[b][81f5d0]" + feed.items.sample.title
      @script.game.cmdChatSend(@script.room, msg)
    end
  end
end

class CmdBash < CmdBase
  def exec(message)
    if feed = rss("bash.im", 443, "/rss/")
      data = feed.items.sample.description
      data.gsub!(/<.*>/, " ")
      msg = "[b][d5e340]" + data
      @script.game.cmdChatSend(@script.room, msg)
    end
  end
end

class CmdPhrase < CmdBase
  def exec(message)
    if feed = rss("www.aphorism.ru", 443, "/rss/aphorism-new.rss")
      msg = "[b][a09561]" + feed.items.sample.description
      @script.game.cmdChatSend(@script.room, msg)
    end
  end
end

class CmdJoke < CmdBase
  def exec(message)
    if feed = rss("www.anekdot.ru", 443, "/rss/export_bestday.xml")
      data = feed.items.sample.description
      data.gsub!(/<.*>/, "")
      msg = "[b][38bfbe]" + data
      @script.game.cmdChatSend(@script.room, msg)
    end
  end
end

class CmdCurrency < CmdBase
  def exec(message)
    if feed = rss("currr.ru", 80, "/rss/")
      data = feed.items[-1].description
      data.gsub!(/<.*>/, "")
      data.gsub!(/\s+/, " ")
      msg = "[b][8f4a6d]" + data
      @script.game.cmdChatSend(@script.room, msg)
    end
  end
end

class CmdPutin < CmdBase
  def exec(message)
    msg = "[s]Путин думает о нас! Путин заботится о нас! До здравствует Путин!"
    @script.game.cmdChatSend(@script.room, msg)
  end
end

class CmdCity < CmdBase
  CITIES_FILE ||= "#{Chatbot::DATA_DIR}/cities.json"
  HINT_TIME ||= 60
  
  def initialize(script)
    super(script)
    unless File.file?(CITIES_FILE)
      @shell.log("Can't load cities file", :script)
      return
    end
    begin
      @cities = JSON.parse(File.read(CITIES_FILE))
    rescue JSON::ParserError => e
      @shell.log("Invalid format of cities file: #{e}", :script)
    end
    @city = String.new
  end
  
  def exec(message)
    return false if @cities.nil? || (not @city.empty?)
    @city = @cities.sample.downcase
    @cityMasked = @city.clone
    pos = (0..@city.length - 1).to_a.sort {rand() - 0.5}[0..((@city.length - 1) * 0.5).floor]
    pos.each do |p|
      @cityMasked[p] = "*"
    end
    @lastHint = Time.now
    @script.userRepeat = false
    msg = "[b][afab73]УГАДАЙТЕ КАКОЙ Я ЗАГАДАЛ ГОРОД: [10ff10]#{@cityMasked.upcase}"
    @script.game.cmdChatSend(@script.room, msg)
  end

  def poll(message = nil)
    return false if @city.empty?

    if not message.nil?
      if message["message"] =~ /#{@city}/i
        msg = "[b][7affe1]#{message["nick"]}[afab73] УГАДАЛ ГОРОД [10ff10]#{@city.upcase}[afab73]!"
        @script.game.cmdChatSend(@script.room, msg)
        @city.clear
        @cityMasked.clear
        @lastHint = nil
        @script.userRepeat = true
        return
      end
    else
      if Time.now - @lastHint >= HINT_TIME
        msg = String.new
        if @cityMasked.scan("*").length <= 1
          msg = "[b][afab73]ЭХ ВЫ! НИКТО НЕ УГАДАЛ! ЭТО БЫЛ ГОРОД [10ff10]#{@city.upcase}"
          @city.clear
          @cityMasked.clear
          @lastHint = nil
          @script.userRepeat = true
        elsif pos = @cityMasked.index("*")
          @cityMasked[pos] = @city[pos]
          msg = "[b][afab73]ПОКА НИКТО НЕ УГАДАЛ ГОРОД, ВОТ ВАМ ПОДСКАЗКА [10ff10]#{@cityMasked.upcase}"
          @lastHint = Time.now
        end
        @script.game.cmdChatSend(@script.room, msg)
      end
    end
  end
end
