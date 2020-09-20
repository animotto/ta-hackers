require "time"
require "rss"

class Chatbot < Sandbox::Script
  DATA_DIR = "#{Sandbox::ContextScript::SCRIPTS_DIR}/chatbot"
  SLEEP_TIME = 10
  SAVE_TIME = 60

  attr_reader :game, :shell, :logger,
              :room, :config, :commands

  class CmdBase
    NAME = String.new
    PATTERNS = Array.new

    attr_accessor :enabled, :visible

    def initialize(script)
      @script = script
      @enabled = false
      @visible = true
      @config = Sandbox::Config.new("#{Chatbot::DATA_DIR}/cmd-#{self.class::NAME}.conf")
      load
    end

    def matched?(message)
      id = message["id"].to_s
      return false if !@script.config["users"][id]["lastTime"].nil? && @script.config["users"][id]["lastTime"] + @script.config["config"]["flood"].to_i > Time.now
      return false if self.class::PATTERNS.empty?
      words = message["message"].split(/\s+/)
      return false if words.empty?
      self.class::PATTERNS.each do |pattern|
        return true if pattern == words[0].downcase
      end
      return false
    end

    def load
      return false if self.class::NAME.empty? || !File.file?(@config.file)
      begin
        @config.load
      rescue JSON::ParserError => e
        @script.logger.error("Config file #{@config.file} has invalid format (#{e})")
      end
    end

    def save
      begin
        @config.save
      rescue => e
        @script.logger.error("Can't save config #{@config.file} (#{e})")
      end
    end
    
    def exec(message)
    end

    def poll
    end

    def stat(id = nil)
    end

    def watch
    end

    def http(host, port, url, params = {})
      client = Net::HTTP.new(host, port)
      client.use_ssl = true if port == 443
      uri = params.empty? ? url : "#{url}?#{@script.game.encodeUrl(params)}"
      response = client.get(uri)
      return false if response.code != "200"
      return response.body
    rescue => e
      @script.logger.error("HTTP request error (#{e})")
      return false
    end

    def rss(host, port, url, params = {})
      return false unless response = http(host, port, url, params)
      return RSS::Parser.parse(response, false)
    rescue => e
      @script.logger.error("RSS parse error (#{e})")
      return false
    end
  end

  class CmdAdmin < CmdBase
    NAME = "admin"
    PATTERNS = %w[!admin]

    def initialize(script)
      super(script)
      @enabled = true
      @visible = false
      @msgPrefix = "[b][f0ffa5]"
    end

    def exec(message)
      return unless @script.config["admins"].include?(message["id"])
      words = message["message"].split(/\s+/)
      if words.length <= 1
        msg = @script.admin("help")
      else
        msg = @script.admin(words[1..-1].join(" "))
      end
      return if msg.nil?
      @script.say("#{@msgPrefix}#{msg}") unless msg.empty?
    end
  end

  class CmdHelp < CmdBase
    NAME = "help"
    PATTERNS = %w[!помощь]

    def exec(message)
      list = Array.new
      @script.commands.each do |name, command|
        next if command.class == self.class || !(command.enabled && command.visible)
        list.concat(command.class::PATTERNS)
        list.concat(command.config["patterns"].keys) if command.class::NAME == CmdMessage::NAME
      end
      hex = (0..15).to_a
      list.map! do |command|
        color = String.new
        6.times {color += hex.sample.to_s(16)}
        "[#{color}]#{command}"
      end
      msg = "[b][77a9ff]ВОТ ЧТО Я УМЕЮ: " + list.join(" ")
      @script.say(msg)
    end
  end

  class CmdStat < CmdBase
    NAME = "stat"
    PATTERNS = %w[!стат]

    def exec(message)
      stats = Array.new
      @script.commands.each do |name, command|
        next unless command.enabled
        stat = command.stat
        next if stat.nil?
        stats.push(stat)
      end
      return if stats.empty?
      msg = "[b]" + stats.join("[ff673d], ")
      @script.say(msg)
    end
  end

  class CmdHello < CmdBase
    NAME = "hello"
    PATTERNS = [
      /\bприв(ет)?\b/i,
      /\bхай\b/i,
      /\bздравствуй(те)?\b/i,
      /\bзд(о|а)рово\b/i,
    ]

    FLOOD_TIME_MULTI = 8
    GREETINGS = [
      "ПРИВЕТ %!",
      "АЛОХА %!",
      "ЧО КАК %? КАК САМ?",
      "КАВАБАНГА %!",
      "КАК НАМ ТЕБЯ НЕ ХВАТАЛО %!",
      "ПРИВЕТСТВУЮ %!",
      "ВИДЕЛИСЬ %!",
      "ЗДРАВСТВУЙ %!",
      "БОНСУАР %!",
      "КОНИЧИВА %!",
      "ГУТЕН ТАГ %!",
      "ШАЛОМ %!",
      "% А ТЫ ЗНАЕШЬ ЧТО ТАКОЕ БЕЗУМИЕ?",
    ]

    def initialize(script)
      super(script)
      @visible = false
    end

    def matched?(message)
      return false if !@lastTime.nil? && @lastTime + (@script.config["config"]["flood"].to_i * FLOOD_TIME_MULTI) > Time.now
      return false if self.class::PATTERNS.empty? || message["message"].empty?
      self.class::PATTERNS.each do |pattern|
        return true if pattern.match(message["message"])
      end
      return false
    end

    def exec(message)
      @lastTime = Time.now
      msg = "[b][6aab7f]#{GREETINGS.sample} ЕСЛИ ТЕБЕ ИНТЕРЕСНО ЧТО Я УМЕЮ, ОТПРАВЬ В ЧАТ [ff35a0]!помощь"
      msg.gsub!("%", "[ff35a0]#{message["nick"]}[6aab7f]")
      @script.say(msg)
    end

    def watch
      {
        "floodmulti" => FLOOD_TIME_MULTI,
      }
    end
  end

  class CmdCounting < CmdBase
    NAME = "counting"
    PATTERNS = %w[!считалочка]

    COUNTINGS = [
      "ШИШЕЛ-МЫШЕЛ, СЕЛ НА КРЫШУ, ШИШЕЛ-МЫШЕЛ, ВЗЯЛ % И ВЫШЕЛ!",
      "ПЛЫЛ ПО МОРЮ ЧЕМОДАН, В ЧЕМОДАНЕ БЫЛ ДИВАН, НА ДИВАНЕ ЕХАЛ СЛОН. КТО НЕ ВЕРИТ - % ВЫЙДИ ВОН!",
      "ЗА СТЕКЛЯННЫМИ ДВЕРЯМИ СИДИТ МИШКА С ПИРОГАМИ. МИШКА, МИШЕНЬКА ДРУЖОК! СКОЛЬКО СТОИТ ПИРОЖОК? ПИРОЖОК-ТО ПО РУБЛЮ, ВЫХОДИ %, Я ТЕБЯ ЛЮБЛЮ!",
      "ПОД ГОРОЮ У РЕКИ ЖИВУТ ГНОМЫ-СТАРИКИ. У НИХ КОЛОКОЛ ВИСИТ, ПОЗОЛОЧЕННЫЙ ЗВОНИТ: ДИГИ-ДИГИ-ДИГИ-ДОН - ВЫХОДИ % СКОРЕЕ ВОН!",
      "КАК НА НАШЕМ СЕНОВАЛЕ, ДВЕ ЛЯГУШКИ НОЧЕВАЛИ. УТРОМ ВСТАЛИ, ЩЕЙ ПОЕЛИ, И ТЕБЕ % ВОДИТЬ ВЕЛЕЛИ!",
      "В ПОЛЕ МЫ НАШЛИ РОМАШКУ, ВАСИЛЕК, ГВОЗДИКУ, КАШКУ, КОЛОКОЛЬЧИК, МАК, ВЬЮНОК... НАЧИНАЙ % ПЛЕСТИ ВЬЮНОК!",
      "БЕГАЛ ЗАЙКА ПО ДОРОГЕ, ДА УСТАЛИ СИЛЬНО НОГИ. ЗАХОТЕЛОСЬ ЗАЙКЕ СПАТЬ, ВЫХОДИ %, ТЕБЕ ИСКАТЬ!",
      "ЛУНОХОД, ЛУНОХОД, ПО ЛУНЕ ИДЁТ ВПЕРЁД. ДОЛГО ТАМ ЕМУ ХОДИТЬ, А СЕЙЧАС ТЕБЕ % ВОДИТЬ!",
    ]

    def exec(message)
      msg = "[b][00ff00]#{COUNTINGS.sample}"
      msg.gsub!("%", "[ffff00]#{@script.config["users"][@script.config["users"].keys.sample]["nick"]}[00ff00]")
      @script.say(msg)
    end
  end

  class CmdRoulette < CmdBase
    NAME = "roulette"
    PATTERNS = %w[!рулетка]

    def load
      super
      @config.merge!({
        "counter" => 0,
        "bullets" => 6,
        "mutetime" => 60 * 60,
        "users" => {},
      }) if @config.empty?
    end

    def exec(message)
      msg = "[b][ffff00]#{message["nick"]} "
      if rand(1..@config["bullets"]) == @config["bullets"] / 2
        id = message["id"].to_s
        @script.config["users"][id]["muteTime"] = Time.now + @config["mutetime"].to_i
        msg += "[ff0000]ПИФ ПАФ! ТЫ УБИТ! ТЕБЯ НЕ БУДЕТ СЛЫШНО [00ff00]#{@config["mutetime"] / 60} [ff0000]МИНУТ!"
        @config["counter"] += 1
        if @config["users"][id].nil?
          @config["users"][id] = {
            "counter" => 0,
          }
        end
        @config["users"][id]["counter"] += 1
        save
      else
        msg += "[00ff00]В ЭТОТ РАЗ ТЕБЕ ПОВЕЗЛО!"
      end
      @script.say(msg)
    end

    def stat(id = nil)
      return "[ff1000]ЗАСТРЕЛИЛСЯ #{@config["users"].dig(id, "counter") || 0} РАЗ" unless id.nil?
      return "[ff1000]ЗАСТРЕЛИЛОСЬ #{@config["counter"]} ЧЕЛОВЕК"
    end

    def watch
      {
        "counter" => @config["counter"],
        "bullets" => @config["bullets"],
        "mutetime" => @config["mutetime"],
        "muted" => @script.config["users"].select {|k, v| !v["muteTime"].nil? && v["muteTime"] >= Time.now}.length
      }
    end
  end

  class CmdCookie < CmdBase
    NAME = "cookie"
    PATTERNS = %w[!печенька]

    def load
      super
      @config.merge!({
        "counter" => 0,
        "users" => {},
        "fortune" => [],
      }) if @config.empty?
    end

    def exec(message)
      id = message["id"].to_s
      if rand(0..1) == 1
        msg = "[ffff00]#{message["nick"]} [00ff00]СЪЕДАЕТ ПЕЧЕНЬКУ И ЧИТАЕТ ПРЕДСКАЗАНИЕ: [60ffda]#{@config["fortune"].sample}"
        @config["counter"] += 1
        if @config["users"][id].nil?
          @config["users"][id] = {
            "counter" => 0,
          }
        end
        @config["users"][id]["counter"] += 1
        save
      else
        msg = "[00ff00]ФИГУШКИ ТЕБЕ [ffff00]#{message["nick"]}[00ff00], А НЕ ПЕЧЕНЬКА!"
      end
      @script.say(msg)
    end

    def stat(id = nil)
      return "[ffea4f]СЪЕЛ #{@config["users"].dig(id, "counter") || 0} ПЕЧЕНЕК" unless id.nil?
      return "[ffea4f]СЪЕДЕНО #{@config["counter"]} ПЕЧЕНЕК"
    end

    def watch
      {
        "fortune" => @config["fortune"].length,
      }
    end
  end

  class CmdClick < CmdBase
    NAME = "click"
    PATTERNS = %w[!бац !топ]

    MESSAGES = [
      "ХАКЕРЮГИ СБАЦАЛИ УЖЕ % РАЗ!",
      "ХАКЕРЬЁ НЕ СПИТ! НАБАЦАЛИ % РАЗ!",
      "ЛАМЕРЮГИ НИКОГДА НЕ НАБАЦАЮТ % РАЗ!",
    ]

    def load
      super
      @config.merge!({
        "counter" => 0,
        "users" => {},
      }) if @config.empty?
    end

    def exec(message)
      words = message["message"].split(/\s+/)
      if words[0] == self.class::PATTERNS[0]
        @config["counter"] += 1
        id = message["id"].to_s
        @config["users"][id] = [message["nick"], 0] unless @config["users"].key?(id)
        @config["users"][id] = [message["nick"], @config["users"][id][1] + 1]
        msg = "[b][ff3500]#{MESSAGES.sample} ПРИСОЕДИНЯЙСЯ!"
        msg.gsub!("%", "[ff9ea1]#{@config["counter"]}[ff3500]")
        save
        @script.say(msg)
        return
      end

      if @config["counter"].zero?
        msg = "[b][7aff38]ЕЩЕ НИКТО НЕ СБАЦАЛ, ТЫ МОЖЕШЬ СТАТЬ ПЕРВЫМ!"
      else
        users = @config["users"].sort_by {|k, v| -v[1]}
        msg = "[b][7aff38]ТОП ХАКЕРЮГ: "
        top = Array.new
        3.times do |i|
          break if users[i].nil?
          top.push("[ff312a]#{users[i][1][0]}[7aff38] НАБАЦАЛ [ff312a]#{users[i][1][1]} [7aff38]РАЗ!")
        end
        msg += top.join(" ")
      end
      @script.say(msg)
    end

    def stat(id = nil)
      return "[ff312a]БАЦНУЛ #{@config["users"].dig(id, 1) || 0} РАЗ" unless id.nil?
      return "[ff312a]БАЦНУТО #{@config["counter"]} РАЗ"
    end

    def watch
      {
        "counter" => @config["counter"],
      }
    end
  end
  
  class CmdLenta < CmdBase
    NAME = "lenta"
    PATTERNS = %w[!лента]

    def exec(message)
      return unless feed = rss("lenta.ru", 443, "/rss/news")
      msg = "[b][39fe12]" + feed.items.sample.title
      @script.say(msg)
    end
  end

  class CmdHabr < CmdBase
    NAME = "habr"
    PATTERNS = %w[!хабр]

    def exec(message)
      return unless feed = rss("habr.com", 443, "/ru/rss/news/")
      msg = "[b][7aff51]" + feed.items.sample.title
      @script.say(msg)
    end
  end

  class CmdLor < CmdBase
    NAME = "lor"
    PATTERNS = %w[!лор]

    def exec(message)
      return unless feed = rss(
        "www.linux.org.ru",
        443,
        "/section-rss.jsp",
        {
          "section" => 1,
        },
      )
      msg = "[b][81f5d0]" + feed.items.sample.title
      @script.say(msg)
    end
  end

  class CmdBash < CmdBase
    NAME = "bash"
    PATTERNS = %w[!баш]

    def exec(message)
      return unless feed = rss("bash.im", 443, "/rss/")
      data = feed.items.sample.description
      data.gsub!(/<.+?>/, " ")
      msg = "[b][d5e340]" + data
      @script.say(msg)
    end
  end

  class CmdPhrase < CmdBase
    NAME = "phrase"
    PATTERNS = %w[!фраза]

    def exec(message)
      return unless feed = rss("www.aphorism.ru", 443, "/rss/aphorism-best-rand.rss")
      msg = "[b][a09561]" + feed.items.sample.description
      @script.say(msg)
    end
  end

  class CmdJoke < CmdBase
    NAME = "joke"
    PATTERNS = %w[!анекдот]

    def exec(message)
      return unless feed = rss("www.anekdot.ru", 443, "/rss/export_j.xml")
      data = feed.items.sample.description
      data.gsub!(/<.+?>/, " ")
      msg = "[b][38bfbe]" + data
      @script.say(msg)
    end
  end

  class CmdCurrency < CmdBase
    NAME = "currency"
    PATTERNS = %w[!курс]

    def exec(message)
      return unless feed = rss("currr.ru", 80, "/rss/")
      data = feed.items.last.description
      data.gsub!(/<.+?>/, " ")
      data.gsub!(/\s+/, " ")
      msg = "[b][8f4a6d]" + data
      @script.say(msg)
    end
  end

  class CmdDay < CmdBase
    NAME = "day"
    PATTERNS = %w[!день]

    def exec(message)
      return unless feed = rss("www.calend.ru", 443, "/img/export/today-holidays.rss")
      items = feed.items.select {|item| item.title.start_with?(Time.now.day.to_s)}
      msg = "[b][ffcc5e]" + items.sample.title
      @script.say(msg)
    end
  end

  class CmdGoose < CmdBase
    NAME = "goose"
    PATTERNS = %w[!гусь]

    def load
      super
      @config.merge!({
        "counter" => 0,
        "users" => {},
      }) if @config.empty?
    end

    def exec(message)
      id = message["id"].to_s
      user = @script.config["users"].keys.sample.to_i
      begin
        info = @script.game.cmdPlayerGetInfo(user)
      rescue Trickster::Hackers::RequestError => e
        @script.logger.error("Get player info error (#{e})")
        return
      end
      msg = "[b][ffa62b]ЗАПУСКАЕМ ГУСЯ! ГУСЬ ДЕЛАЕТ КУСЬ [568eff]#{info["name"]}[ffa62b]! В ЕГО КАРМАНАХ НАШЛОСЬ [ff2a16]#{info["money"]} денег[ffa62b], [ff2a16]#{info["bitcoins"]} биткойнов[ffa62b], [ff2a16]#{info["credits"]} кредитов"
      @config["counter"] += 1
      if @config["users"][id].nil?
        @config["users"][id] = {
          "counter" => 0,
        }
      end
      @config["users"][id]["counter"] += 1
      save
      @script.say(msg)
    end

    def stat(id = nil)
      return "[3fefff]ЗАПУСТИЛ #{@config["users"].dig(id, "counter") || 0} ГУСЕЙ" unless id.nil?
      return "[3fefff]ЗАПУЩЕНО #{@config["counter"]} ГУСЕЙ"
    end
  end

  class CmdHour < CmdBase
    NAME = "hour"

    def initialize(script)
      super(script)
      @visible = false
      @lastTime = Time.now
      @lastUsers = @script.config["users"].length
    end

    def poll
      return if @lastTime.hour == Time.now.hour
      @lastTime = Time.now
      case @lastTime.hour
      when 0
        hour = "ПОЛНОЧЬ"
      when 8
        hour = "С ДОБРЫМ УТРОМ СТРАНА"
      when 12
        hour = "ПОЛДЕНЬ"
      when 13
        hour = "ОБЕД"
      when 19
        hour = "ВЕЧЕРЕЕТ"
      when 1, 21
        hour = "#{@lastTime.hour} ЧАС"
      when 2..4, 22..23
        hour = "#{@lastTime.hour} ЧАСА"
      when 5..20
        hour = "#{@lastTime.hour} ЧАСОВ"
      end

      users = @script.config["users"].length - @lastUsers
      case
      when users.zero?
        status = "ВСЕ СПОКОЙНО"
      when users.between?(1, 3)
        status = "БЫЛО НЕМНОГО ШУМНО"
      else
        status = "ВОТ ЭТО ДА"
      end

      msg = "[b][b6ff56]#{hour}! #{status}!"
      msg += " ПРИХОДИЛО ПОБОЛТАТЬ #{users} НОВЫХ ЧЕЛОВЕК!" unless users.zero?
      @lastUsers = @script.config["users"].length
      @script.say(msg)
    end
  end

  class CmdISS < CmdBase
    NAME = "iss"
    PATTERNS = %w[!мкс]

    def load
      super
      @config.merge!({
        "countries" => {},
      }) if @config.empty?
    end

    def exec(message)
      begin
        return unless data = http("api.open-notify.org", 80, "/iss-now.json")
        coords = JSON.parse(data)
        return unless data = http("api.open-notify.org", 80, "/astros.json")
        astros = JSON.parse(data)
        if data = http(
          "geocode.xyz",
          443,
          "/#{coords["iss_position"]["latitude"]},#{coords["iss_position"]["longitude"]}",
          {
            "json" => 1,
          }
        )
          geo = JSON.parse(data)
        else
          geo = Hash.new
        end
      rescue JSON::ParserError => e
        @script.logger.error("ISS JSON parser error (#{e})")
        return
      end
      astron = astros["people"].select {|a| a["craft"] == "ISS"}
      
      msg = "[b][4cffff]ПЩЩЩЬЬЬ! МЕЖДУНАРОДНАЯ КОСМИЧЕСКАЯ СТАНЦИЯ ВЫХОДИТ НА СВЯЗЬ! НАШИ КООРДИНАТЫ [b6ff00]#{coords["iss_position"]["longitude"]} / #{coords["iss_position"]["latitude"]}"
      msg += "[4cffff], ПРОЛЕТАЕМ НАД [ff3aba]#{@config["countries"][geo["prov"]].upcase}" if geo["prov"]
      msg += "[4cffff], НА БОРТУ [b6ff00]#{astron.length}[4cffff] ЧЕЛОВЕК"
      @script.say(msg)
    end
  end
  
  class CmdSpaceX < CmdBase
    NAME = "spacex"
    PATTERNS = %w[!spacex]

    def exec(message)
      begin
        return unless data = http("api.spacexdata.com", 443, "/v3/launches/next")
        nextLaunch = JSON.parse(data)
      rescue JSON::ParserError => e
        @script.logger.error("SpaceX JSON parser error (#{e})")
        return
      end

      if nextLaunch.nil? || nextLaunch.empty?
        msg = "[b][99e3ff]SpaceX: БЛИЖАЙШИЙ ЗАПУСК НЕ ЗАПЛАНИРОВАН!"
        return
      end
      window = ", ВРЕМЕННОЕ ОКНО [70ff6d]#{nextLaunch["launch_window"] / 60 / 60} [99e3ff]ЧАСОВ," unless nextLaunch["launch_window"].nil?
      msg = "[b][99e3ff]SpaceX: БЛИЖАЙШИЙ ЗАПУСК [70ff6d]#{nextLaunch["mission_name"]} [99e3ff]В [70ff6d]#{Time.at(nextLaunch["launch_date_unix"]).strftime("%H:%M:%S %d.%m.%Y")}[99e3ff]#{window} НА РАКЕТЕ [70ff6d]#{nextLaunch["rocket"]["rocket_name"]}[99e3ff], С ПЛОЩАДКИ [70ff6d]#{nextLaunch["launch_site"]["site_name_long"]}"
      @script.say(msg)
    end
  end

  class CmdCOVID19 < CmdBase
    NAME = "covid19"
    PATTERNS = %w[!ковид]

    def exec(message)
      begin
        return unless data = http("api.covid19api.com", 443, "/summary")
        covid19 = JSON.parse(data)
      rescue JSON::ParserError => e
        @script.logger.error("COVID19 JSON parser error (#{e})")
        return
      end

			msg = "[b][f8ff7f]ВИРУС COVID-19: ЗАРАЖЕНО [ebafff]#{covid19["Global"]["TotalConfirmed"]}[f8ff7f], УМЕРЛО [ebafff]#{covid19["Global"]["TotalDeaths"]}[f8ff7f], ИЗЛЕЧЕННО [ebafff]#{covid19["Global"]["TotalRecovered"]}"
      @script.say(msg)
    end
  end

  class CmdWiki < CmdBase
    NAME = "wiki"
    PATTERNS = %w[!вики]

    def exec(message)
      words = message["message"].split(/\s+/)
      if words.length <= 1
        msg = "[b][7ffb1a]ДЛЯ ПОИСКА ИСПОЛЬЗУЙ КОМАНДУ #{self.class::PATTERNS[0]} [e5dbf9]текст"
        @script.say(msg)
        return
      end

      search = words[1..-1].join(" ")

      return unless data = http(
        "ru.wikipedia.org",
        443,
        "/w/api.php",
        {
          "action" => "opensearch",
          "format" => "json",
          "limit" => 1,
          "search" => search,
        },
      )
      opensearch = JSON.parse(data)

      if opensearch[1].empty?
        msg = "[b][7ffb1a]ПО ЗАПРОСУ [e5dbf9]#{search} [7ffb1a]НИЧЕГО НЕ НАШЕЛ!"
        @script.say(msg)
        return
      end

      return unless data = http(
        "ru.wikipedia.org",
        443,
        "/w/api.php",
        {
          "action" => "query",
          "format" => "json",
          "prop" => "extracts",
          "explaintext" => "",
          "exintro" => "",
          "exchars" => 300,
          "redirects" => "",
          "titles" => opensearch[1][0],
        },
      )
      query = JSON.parse(data)
      result = query["query"]["pages"].values[0]["extract"]
      msg = "[b][7ffb1a]#{result}"
      @script.say(msg)
    rescue JSON::ParserError => e
      @script.logger.error("Wiki JSON parser error (#{e})")
      return
    end
  end

  class CmdCity < CmdBase
    NAME = "city"
    PATTERNS = %w[!город]

    HINT_TIME = 60

    def initialize(script)
      super(script)
      @city = String.new
      @cityMasked = String.new
    end
    
    def load
      super
      @config.merge!({
        "counter" => 0,
        "users" => {},
        "cities" => [],
      }) if @config.empty?
    end

    def matched?(message)
      unless @city.empty?
        pattern = /\b#{Regexp.escape(@city)}\b/i
        return true if pattern.match(message["message"])
      end
      super(message)
    end

    def exec(message)
      id = message["id"].to_s
      if @city.empty?
        return if @config["cities"].empty?
        @city = @config["cities"].sample.strip.downcase
        @cityMasked = @city.clone
        return if @city.empty?
        positions = (0..(@city.length - 1)).to_a.shuffle[0..((@city.length - 1) / 2)]
        positions.each {|p| @cityMasked[p] = "*"}
        @lastTimeHint = Time.now
        msg = "[b][afab73]УГАДАЙТЕ КАКОЙ Я ЗАГАДАЛ ГОРОД: [10ff10]#{@cityMasked.upcase}"
        @script.say(msg)
        return
      end

      pattern = /\b#{Regexp.escape(@city)}\b/i
      if pattern.match(message["message"])
        msg = "[b][7affe1]#{message["nick"]}[afab73] УГАДАЛ ГОРОД [10ff10]#{@city.upcase}[afab73]!"
        @script.say(msg)
        @city.clear
        @cityMasked.clear
        @config["counter"] += 1
        if @config["users"][id].nil?
          @config["users"][id] = {
            "counter" => 0,
          }
        end
        @config["users"][id]["counter"] += 1
        save
      end
    end

    def poll
      return if @city.empty?
      return unless Time.now - @lastTimeHint >= HINT_TIME
      if @cityMasked.count("*") <= 1
        msg = "[b][afab73]ЭХ ВЫ! НИКТО НЕ УГАДАЛ! ЭТО БЫЛ ГОРОД [10ff10]#{@city.upcase}"
        @script.say(msg)
        @city.clear
        @cityMasked.clear
        return
      end

      position = @cityMasked.index("*")
      @cityMasked[position] = @city[position]
      @lastTimeHint = Time.now
      msg = "[b][afab73]ПОКА НИКТО НЕ УГАДАЛ ГОРОД, ВОТ ВАМ ПОДСКАЗКА [10ff10]#{@cityMasked.upcase}"
      @script.say(msg)
    end

    def stat(id = nil)
      return "[ffbcdc]ОТГАДАЛ #{@config["users"].dig(id, "counter") || 0} ГОРОДОВ" unless id.nil?
      return "[ffbcdc]ОТГАДАНО #{@config["counter"]} ГОРОДОВ"
    end

    def watch
      {
        "amount" => @config["cities"].length,
      }
    end
  end

  class CmdTazik < CmdBase
    NAME = "tazik"
    PATTERNS = %w[!тазик]

    def load
      super
      @config.merge!({
        "authtime" => 5 * 60,
        "authtimerand" => 2 * 60,
        "checktime" => 60,
        "users" => {},
        "active" => {},
      }) if @config.empty?

      @config["active"].keys.each do |id|
        @config["active"][id]["startTime"] = Time.parse(@config["active"][id]["startTime"])
        @config["active"][id]["authTime"] = Time.parse(@config["active"][id]["authTime"])
        @config["active"][id]["checkTime"] = Time.parse(@config["active"][id]["checkTime"])
        config = @script.game.config.clone
        config["id"] = id.to_i
        config["password"] = @config["users"][id]["password"]
        @config["active"][id]["game"] = Trickster::Hackers::Game.new(config)
        @config["active"][id]["game"].sid = @config["active"][id]["sid"]
      end
    end

    def exec(message)
      id = message["id"].to_s
      unless @config["users"].key?(id)
        msg = "[b][bcd6ff]#{message["nick"]} [fff544]К СОЖАЛЕНИЮ ДЛЯ ТЕБЯ МЕСТА ПОД ТАЗИКОМ НЕ НАШЛОСЬ!"
        msg += " ПОД НИМ СОБРАЛОСЬ [bcd6ff]#{@config["active"].length} [fff544]ЧЕЛОВЕК!" unless @config["active"].empty?
        @script.say(msg)
        return
      end
      if @config["active"].key?(id)
        msg = "[b][bcd6ff]#{message["nick"]} [fff544]ТЫ УЖЕ ПОД ТАЗИКОМ!"
        @script.say(msg)
        return
      end

      config = @script.game.config.clone
      config["id"] = message["id"]
      config["password"] = @config["users"][id]["password"]
      game = Trickster::Hackers::Game.new(config)
      begin
        auth = game.cmdAuthIdPassword
        game.sid = auth["sid"]
        game.cmdNetGetForMaint
        @config["active"][id] = {
          "sid" => auth["sid"],
          "startTime" => Time.now,
          "authTime" => Time.now,
          "checkTime" => Time.now,
        }
      rescue Trickster::Hackers::RequestError => e
        @script.logger.error("Tazik auth error for #{id} (#{e})")
        msg = "[b][bcd6ff]#{message["nick"]} [fff544]НЕ УДАЕТСЯ СПРЯТАТЬСЯ ПОД ТАЗИК!"
        @script.say(msg)
        return
      end

      @config["active"][id]["game"] = game
      @config["active"][id]["nick"] = message["nick"]
      save
      msg = "[b][bcd6ff]#{message["nick"]} [fff544]СПРЯТАЛСЯ ПОД ТАЗИКОМ! ТЕПЕРЬ ЕГО НИКТО НЕ ДОСТАНЕТ!"
      @script.say(msg)
    end

    def poll
      @config["active"].keys.each do |id|
        if @config["active"][id]["authTime"] + @config["authtime"] + rand(@config["authtimerand"]) <= Time.now
          auth = @config["active"][id]["game"].cmdAuthIdPassword
          @config["active"][id]["sid"] = auth["sid"]
          @config["active"][id]["game"].sid = auth["sid"]
          @config["active"][id]["game"].cmdNetGetForMaint
          @config["active"][id]["authTime"] = Time.now
          @config["active"][id]["checkTime"] = Time.now
          save
        end
        if @config["active"][id]["checkTime"] + @config["checktime"] <= Time.now
          @config["active"][id]["game"].cmdCheckCon
          @config["active"][id]["checkTime"] = Time.now
          save
        end
      rescue Trickster::Hackers::RequestError => e
        case e.type
        when "WrongSessionIdException"
          mins = (Time.now - @config["active"][id]["startTime"]).to_i / 60
          hours = mins / 60
          time = Array.new
          time.push("[bcd6ff]#{hours} [fff544]ЧАСОВ") if hours > 0
          time.push("[bcd6ff]#{mins % 60} [fff544]МИНУТ")
          msg = "[b][bcd6ff]#{@config["active"][id]["nick"]} [fff544]ВЫЛЕЗАЕТ ИЗ ПОД ТАЗИКА! ПРОСИДЕЛ ПОД НИМ #{time.join(", ")}!"
          @script.say(msg)
          @config["active"].delete(id)
          save
        when "NotLoggedException"
          @config["active"].delete(id)
          save
        else
          @script.logger.error("Tazik poll error for #{id} (#{e})")
        end
      end
    end

    def watch
      {
        "authtime" => @config["authtime"],
        "authtimerand" => @config["authtimerand"],
        "checktime" => @config["checktime"],
        "amount" => @config["active"].length,
        "users" => @config["active"].map {|k, v| v["nick"]}.join(", ").insert(0, "[").insert(-1, "]")
      }
    end
  end

  class CmdPerson < CmdBase
    NAME = "person"

    ANSWERS = [
      "ЧТО ТЕБЕ НУЖНО %?",
      "ТЫ МЕНЯ ЗВАЛ %?",
      "ВСЕГДА ГОТОВ %!",
      "Я НИЧЕГО ОБ ЭТОМ НЕ ЗНАЮ %!",
      "Я НЕ ВИНОВАТ %! ОНО САМО!",
      "Я ПОДУМАЮ НАД ЭТИМ %!",
      "ПОЛОСТЬЮ С ТОБОЙ СОГЛАСЕН %!",
      "НИЗАЧТО %!",
      "% А ТЫ КОГДА-НИБУДЬ ПРОБОВАЛ ЛИЗНУТЬ ЛУНУ?",
      "% КОНЕЧНО!",
      "% НЕТ, А ТЫ?",
      "ЛАДНО %!",
      "ХОРОШО %!",
      "ТАКОГО Я НЕ ОЖИДАЛ ОТ ТЕБЯ %!",
      "% ЭТО ПРОСТО НЕ ПРИЛИЧНО!",
      "% ТЫ ТАКОЙ КЛАССНЫЙ!",
      "Я НЕ МОГУ %, У МЕНЯ ЛАПКИ!",
      "% ЕСЛИ ТЕБЕ ИНТЕРЕСНО, ТОЧНОЕ ВРЕМЯ @!",
    ]

    def matched?(message)
      id = message["id"].to_s
      return false if !@script.config["users"][id]["lastTime"].nil? && @script.config["users"][id]["lastTime"] + @script.config["config"]["flood"].to_i > Time.now
      words = message["message"].split(/\s+/)
      return true if words.include?("@#{@script.config["name"]}")
      return false
    end

    def exec(message)
      msg = "[b][7fffa7]" + ANSWERS.sample
      msg.gsub!("%", "[8ccbff]#{message["nick"]}[7fffa7]")
      msg.gsub!("@", "[ffe5af]#{Time.now.strftime("%H:%M")}[7fffa7]")
      @script.say(msg)
    end
  end

  class CmdRanking < CmdBase
    NAME = "ranking"

    def load
      super
      @config.merge!({
        "checktime" => 15 * 60,
        "topnum" => 20,
      }) if @config.empty?
    end

    def initialize(script)
      super(script)
      @visible = false
      @lastTimeCheck = Time.now
    end

    def poll
      return unless Time.now - @lastTimeCheck >= @config["checktime"]
      begin
        @top = @script.game.cmdRankingGetAll(@script.room)
      rescue Trickster::Hackers::RequestError => e
        @script.logger.error("Get ranking error (#{e})")
        return
      end
      @lastTimeCheck = Time.now
      if @lastTop.nil?
        @lastTop = @top.clone
        return
      end

      players = Array.new
      msg = "[b]"
      for i in 0..(@config["topnum"] - 1) do
        ["world", "country"].each do |type|
          next if @top[type][i].nil?
          lastPlace = @lastTop[type].find_index {|v| v["id"] == @top[type][i]["id"]}
          next if !lastPlace.nil? && lastPlace <= i
          m = "[ffa0f5]ИГРОК [66ff8e]#{@top[type][i]["name"]} [ffa0f5]ВЫРЫВАЕТСЯ НА [6b99ff]#{i + 1} [ffa0f5]МЕСТО"
          m += " В МИРОВОМ РЕЙТИНГЕ" if type == "world"
          m += " В РЕЙТИНГЕ СТРАНЫ" if type == "country"
          players.push(m)
        end
      end
      msg += players.join(", ") + "!"
      @script.say(msg) unless players.empty?

      @lastTop = @top.clone
    end

    def watch
      {
        "checktime" => @config["checktime"],
        "topnum" => @config["topnum"],
      }
    end
  end
  
  class CmdWall < CmdBase
    NAME = "wall"
    PATTERNS = %w[!стена !запись]

    def load
      super
      @config.merge!({
        "recordtime" => 60 * 60 * 24,
        "records" => {},
      }) if @config.empty?

      @config["records"].keys.each do |id|
        @config["records"][id]["time"] = Time.parse(@config["records"][id]["time"])
      end
    end

    def exec(message)
      words = message["message"].split(/\s+/)
      id = message["id"].to_s
      msg = "[b][ff5e3a]"
      if words[0] == self.class::PATTERNS[1]
        if !@config["records"][id].nil? && Time.now - @config["records"][id]["time"] <= @config["recordtime"]
          msg += "[7aff9f]#{message["nick"]} [ff5e3a]ТЫ УЖЕ ОСТАВИЛ ЗАПИСЬ! ОСТАВИТЬ НОВУЮ ЗАПИСЬ МОЖНО БУДЕТ [7aff9f]#{(@config["records"][id]["time"] + @config["recordtime"]).strftime("%d.%m.%y %H:%M")}"
        else
          record = words[1..-1].join(" ")
          if record.empty?
            msg += "ДЛЯ ТОГО ЧТОБЫ ОСТАВИТЬ ЗАПИСЬ НА СТЕНЕ, ИСПОЛЬЗУЙ КОМАНДУ #{self.class::PATTERNS[1]} текст"
            @script.say(msg)
            return
          end
          msg += "[7aff9f]#{message["nick"]} [ff5e3a]ОСТАВИЛ НА СТЕНЕ ЗАПИСЬ!"
          @config["records"][id] = {
            "name" => message["nick"],
            "message" => record,
            "time" => Time.now,
          }
          save
        end
        @script.say(msg)
        return
      end

      if @config["records"].empty?
        msg += "НА СТЕНЕ ПУСТО! ПОПРОБУЙ ЧТО-НИБУДЬ НАПИСАТЬ КОМАНДОЙ #{self.class::PATTERNS[1]}"
      else
        record = @config["records"][@config["records"].keys.sample]
        msg += "[7aff9f]#{record["name"]} [ff5e3a]НАПИСАЛ В [7aff9f]#{record["time"].strftime("%d.%m.%y %H:%M")}[ff5e3a]: [93e9ff]#{record["message"]}"
      end
      @script.say(msg)
    end

    def stat(id = nil)
      unless id.nil?
        return "[ffadad]НА СТЕНЕ НЕ ПИСАЛ" unless @config["records"].key?(id)
        return "[ffadad]НА СТЕНЕ ПИСАЛ #{@config["records"][id]["time"].strftime("%d.%m.%y %H:%M")}"
      end
      return "[ffadad]ОСТАВЛЕНО #{@config["records"].length} ЗАПИСЕЙ"
    end

    def watch
      {
        "recordtime" => @config["recordtime"],
        "records" => @config["records"].length,
      }
    end
  end

  class CmdMessage < CmdBase
    NAME = "message"

    attr_accessor :config

    def load
      super
      @config.merge!({
        "patterns" => {},
      }) if @config.empty?
    end

    def matched?(message)
      id = message["id"].to_s
      return false if !@script.config["users"][id]["lastTime"].nil? && @script.config["users"][id]["lastTime"] + @script.config["config"]["flood"].to_i > Time.now
      return false if @config["patterns"].empty?
      words = message["message"].split(/\s+/)
      return false if words.empty?
      return true if @config["patterns"].key?(words[0].downcase)
      return false
    end

    def exec(message)
      words = message["message"].split(/\s+/)
      @script.say(@config["patterns"][words[0]]["message"])
    end
  end

  class CmdInfo < CmdBase
    NAME = "info"
    PATTERNS = %w[!инфо]

    MESSAGES = [
      "И ВООБЩЕ ПРОСТО НЯШКА!",
      "ЖИВЕТ ТАКОЙ ЧЕЛОВЕК!",
      "НИ ДАТЬ НИ ВЗЯТЬ!",
      "ЧТО-ТО ПОДОЗРИТЕЛЬНО!",
      "КАК ОН ЭТО ДЕЛАЕТ?",
    ]

    def exec(message)
      id = message["id"].to_s
      msg = "[b][fc7cff]#{message["nick"]}: "
      info = [
        "[95ff93]НАПИСАЛ #{@script.config["users"][id]["counter"]} СООБЩЕНИЙ",
      ]
      @script.commands.each do |name, command|
        next unless command.enabled
        stat = command.stat(id)
        next if stat.nil?
        info.push(stat)
      end
      info.push("[ff5b5e]#{MESSAGES.sample}")
      msg += info.join(", ")
      @script.say(msg)
    end
  end

  def initialize(game, shell, logger, args)
    super(game, shell, logger, args)
    Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)

    @room = args[0].to_i
    @users = Hash.new
  end

  def load
    file = "#{DATA_DIR}/main.conf"
    @config = Sandbox::Config.new(file)
    begin
      @config.load
    rescue JSON::ParserError => e
      @logger.error("Main config file has invalid format (#{e})")
      return false
    rescue => e
      @config.merge!({
        "config" => {
          "flood" => "15",
          "repeats" => "4",
          "random" => "on",
          },
        "admins" => [],
        "enabled" => [],
        "users" => {},
      })
    end

    @config["users"].each do |id, info|
        @config["users"][id]["lastTime"] = Time.parse(info["lastTime"])
        @config["users"][id]["muteTime"] = Time.parse(info["muteTime"])
    rescue TypeError => e
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

  def say(message)
    @game.cmdChatSend(@room, message)
  rescue Trickster::Hackers::RequestError => e
    @logger.error("Say error (#{e})")
  end

  def admin(line)
    words = line.split(/\s+/)
    return if words.empty?

    case words[0]
      when "help", "?"
        return "Commands: <uptime> | <set> [var] [value] | <cmd> <on|of|watch> <names> | mute [add|del] <id>"

      when "uptime"
        secs = (Time.now - @config["startup"]).to_i
        mins = secs / 60
        hours = mins / 60
        days = hours / 24
        elems = Array.new
        elems.push("#{days} days") if days > 0
        elems.push("#{hours % 24} hours") if hours > 0
        elems.push("#{mins % 60} mins") if mins > 0
        elems.push("#{secs % 60} secs")
        return "Uptime: " + elems.join(", ")

      when "set"
        if words.length < 2
          vars = Array.new
          @config["config"].each do |var, value|
            vars.push("#{var}=#{value}")
          end
          return "Config: " + vars.join(", ")
        end

        return if words.length < 3
        return unless @config["config"].key?(words[1])
        @config["config"][words[1]] = words[2]
        save
        return "Config updated: #{words[1]}=#{words[2]}"

      when "mute"
        if words.length < 2
          users = @config["users"].select {|k, v| !v["muteTime"].nil? && v["muteTime"] > Time.now}
          return if users.empty?
          return "Muted: " + users.map {|k, v| "#{k} => #{(v["muteTime"] - Time.now).to_i / 60}"}.join(", ")
        end
        return if words.length < 3
        id = words[2]
        unless @config["users"].key?(id)
          return "User #{id} doesn't exist"
        end
        case words[1]
          when "add"
            time = words[3].to_i
            @config["users"][id]["muteTime"] = Time.now + time * 60
            save
            return "User #{id} muted for #{time} minutes"

          when "del"
            @config["users"][id].delete("muteTime")
            save
            return "User #{id} unmuted"
        end

      when "cmd"
        if words.length < 2
          list = @commands.select {|k, v| v.enabled && k != CmdAdmin::NAME}
          return "Commands: " + list.keys.join(" ")
        end

        return if words.length < 3
        case words[1]
          when "on", "off"
            cmds = words[2..-1].select {|cmd| @commands.keys.include?(cmd) && cmd != CmdAdmin::NAME}
            return if cmds.empty?
            cmds.each do |cmd|
              if words[1] == "on"
                @commands[cmd].enabled = true
                @config["enabled"].push(cmd) unless @config["enabled"].include?(cmd)
              else
                @commands[cmd].enabled = false
                @config["enabled"].delete(cmd)
              end
            end
            save
            msg = "Commands "
            msg += words[1] == "on" ? "enabled" : "disabled"
            msg += ": " + cmds.join(" ")
            return msg

          when "watch"
            return unless @commands.keys.include?(words[2])
            return unless watch = @commands[words[2]].watch
            msg = "Watch #{words[2]}: "
            msg += watch.map {|k, v| "#{k}=#{v}"}.join(", ")
            return msg
        end
    end
  end

  def main
    if @room.zero?
      @logger.log("Specify room ID")
      return
    end

    return unless load
    @config["startup"] = Time.now

    @commands = Hash.new
    @commands[CmdAdmin::NAME] = CmdAdmin.new(self)
    @commands[CmdHelp::NAME] = CmdHelp.new(self)
    @commands[CmdStat::NAME] = CmdStat.new(self)
    @commands[CmdHello::NAME] = CmdHello.new(self)
    @commands[CmdCounting::NAME] = CmdCounting.new(self)
    @commands[CmdRoulette::NAME] = CmdRoulette.new(self)
    @commands[CmdCookie::NAME] = CmdCookie.new(self)
    @commands[CmdClick::NAME] = CmdClick.new(self)
    @commands[CmdLenta::NAME] = CmdLenta.new(self)
    @commands[CmdHabr::NAME] = CmdHabr.new(self)
    @commands[CmdLor::NAME] = CmdLor.new(self)
    @commands[CmdBash::NAME] = CmdBash.new(self)
    @commands[CmdPhrase::NAME] = CmdPhrase.new(self)
    @commands[CmdJoke::NAME] = CmdJoke.new(self)
    @commands[CmdCurrency::NAME] = CmdCurrency.new(self)
    @commands[CmdDay::NAME] = CmdDay.new(self)
    @commands[CmdGoose::NAME] = CmdGoose.new(self)
    @commands[CmdHour::NAME] = CmdHour.new(self)
    @commands[CmdISS::NAME] = CmdISS.new(self)
    @commands[CmdSpaceX::NAME] = CmdSpaceX.new(self)
    @commands[CmdCOVID19::NAME] = CmdCOVID19.new(self)
    @commands[CmdWiki::NAME] = CmdWiki.new(self)
    @commands[CmdCity::NAME] = CmdCity.new(self)
    @commands[CmdTazik::NAME] = CmdTazik.new(self)
    @commands[CmdPerson::NAME] = CmdPerson.new(self)
    @commands[CmdRanking::NAME] = CmdRanking.new(self)
    @commands[CmdWall::NAME] = CmdWall.new(self)
    @commands[CmdMessage::NAME] = CmdMessage.new(self)
    @commands[CmdInfo::NAME] = CmdInfo.new(self)

    @randomCommands = [
      CmdStat::NAME,
      CmdClick::NAME,
      CmdCounting::NAME,
      CmdRoulette::NAME,
      CmdCookie::NAME,
      CmdLenta::NAME,
      CmdHabr::NAME,
      CmdLor::NAME,
      CmdBash::NAME,
      CmdPhrase::NAME,
      CmdJoke::NAME,
      CmdCurrency::NAME,
      CmdDay::NAME,
      CmdGoose::NAME,
      CmdISS::NAME,
      CmdSpaceX::NAME,
      CmdCOVID19::NAME,
      CmdWall::NAME,
      CmdInfo::NAME,
    ]

    @config["enabled"].each do |name|
      next unless @commands.keys.include?(name)
      @commands[name].enabled = true
    end

    @logger.log("The bot listens room #{@room}")

    roomLastUser = Hash.new
    roomLastTime = String.new
    saveLastTime = Time.now

    begin
      messages = @game.cmdChatDisplay(@room, roomLastTime)
      net = @game.cmdNetGetForMaint
    rescue Trickster::Hackers::RequestError => e
      @logger.error("Initial commands error (#{e})")
      return
    end
    roomLastTime = messages.last["datetime"] unless messages.empty?
    @config["name"] = net["profile"]["name"]

    loop do
      sleep(SLEEP_TIME)
      @commands.each {|name, command| command.poll if command.enabled}
      begin
        messages = @game.cmdChatDisplay(@room, roomLastTime)
      rescue Trickster::Hackers::RequestError => e
        @logger.error("Chat display error (#{e})")
        next
      end
      next if messages.empty?
      roomLastTime = messages.last["datetime"]

      messages.each do |message|
        next if message["id"] == @game.config["id"]
        id = message["id"].to_s
        unless @config["users"].key?(id)
          @config["users"][id] = {
            "counter" => 0,
          }
        end
        @config["users"][id]["nick"] = message["nick"]
        @config["users"][id]["counter"] += 1
        next if !@config["users"][id]["muteTime"].nil? && @config["users"][id]["muteTime"] >= Time.now

        executed = false
        @commands.each do |name, command|
          if command.matched?(message) && command.enabled
            command.exec(message)
            executed = true
            @config["users"][id]["lastTime"] = Time.now
          end
        end
        
        if !executed
          if roomLastUser["id"].nil? || roomLastUser["id"] != message["id"]
            roomLastUser = {
              "id" => message["id"],
              "counter" => 1,
            }
          else
            roomLastUser["counter"] += 1
          end
          if roomLastUser["counter"] >= @config["config"]["repeats"].to_i && @config["config"]["random"] == "on"
            randomCommandsEnabled = @randomCommands.select {|c| @commands[c].enabled}
            unless randomCommandsEnabled.empty?
              @commands[randomCommandsEnabled.sample].exec(message)
              roomLastUser.clear
            end
          end
        end

        if saveLastTime + SAVE_TIME <= Time.now
          save
          saveLastTime = Time.now
        end
      end
    end
  end
end

