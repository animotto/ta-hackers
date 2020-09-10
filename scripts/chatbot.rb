require "time"
require "rss"

class Chatbot < Sandbox::Script
  DATA_DIR = "#{Sandbox::ContextScript::SCRIPTS_DIR}/chatbot"
  SLEEP_TIME = 10

  attr_reader :game, :shell, :room, :config, :commands, :users

  class CmdBase
    NAME = String.new
    PATTERNS = Array.new

    attr_accessor :enabled, :visible

    def initialize(script)
      @script = script
      @config = Hash.new
      @enabled = false
      @visible = true
      load
    end

    def matched?(message)
      return false if !@script.users[message["id"]]["lastTime"].nil? && @script.users[message["id"]]["lastTime"] + @script.config["config"]["flood"].to_i > Time.now
      return false if self.class::PATTERNS.empty?
      words = message["message"].split(/\s+/)
      return false if words.empty?
      self.class::PATTERNS.each do |pattern|
        return true if pattern == words[0].downcase
      end
      return false
    end

    def load
      file = "#{Chatbot::DATA_DIR}/cmd-#{self.class::NAME}.conf"
      return false if self.class::NAME.empty? || !File.file?(file)
      begin
        @config = JSON.parse(File.read(file))
      rescue JSON::ParserError => e
        @script.shell.log("Config file #{file} has invalid format (#{e})", :script)
      end
    end

    def save
      file = "#{Chatbot::DATA_DIR}/cmd-#{self.class::NAME}.conf"
      File.write(file, JSON.pretty_generate(@config))
    end
    
    def exec(message)
    end

    def poll
    end

    def stat
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
      @script.shell.log("HTTP request error (#{e})", :script)
      return false
    end

    def rss(host, port, url, params = {})
      return false unless response = http(host, port, url, params)
      return RSS::Parser.parse(response, false)
    rescue => e
      @script.shell.log("RSS parse error (#{e})", :script)
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
        msg = "#{@msgPrefix}!admin <uptime>|<set> [var] [value]|<cmd> <on|of|watch> <names>"
        @script.say(msg)
        return
      end

      case words[1]
        when "uptime"
          secs = (Time.now - @script.config["startup"]).to_i
          mins = secs / 60
          hours = mins / 60
          days = hours / 24
          elems = Array.new
          elems.push("#{days % 24} days") if days > 0
          elems.push("#{hours % 60} hours") if hours > 0
          elems.push("#{mins % 60} mins") if mins > 0
          elems.push("#{secs % 60} secs")
          msg = "#{@msgPrefix}Uptime: " + elems.join(", ")
          @script.say(msg)
        when "set"
          if words.length < 3
            vars = Array.new
            @script.config["config"].each do |var, value|
              vars.push("#{var}=#{value}")
            end
            msg = "#{@msgPrefix}Config: " + vars.join(", ")
            @script.say(msg)
            return
          end

          return if words.length < 4
          return unless @script.config["config"].key?(words[2])
          @script.config["config"][words[2]] = words[3]
          @script.save
          msg = "#{@msgPrefix}Config updated: #{words[2]}=#{words[3]}"
          @script.say(msg)
        when "cmd"
          if words.length < 3
            msg = "#{@msgPrefix}Commands: "
            list = @script.commands.select {|k, v| v.enabled && k != self.class::NAME}
            msg += list.keys.join(" ")
            @script.say(msg)
            return
          end

          return if words.length < 4
          case words[2]
            when "on", "off"
              cmds = words[3..-1].select {|cmd| @script.commands.keys.include?(cmd) && cmd != self.class::NAME}
              return if cmds.empty?
              cmds.each do |cmd|
                if words[2] == "on"
                  @script.commands[cmd].enabled = true
                  @script.config["enabled"].push(words[3])
                else
                  @script.commands[cmd].enabled = false
                  @script.config["enabled"].delete(words[3])
                end
              end
              @script.save
              msg = "#{@msgPrefix}Commands "
              msg += words[2] == "on" ? "enabled" : "disabled"
              msg += ": " + cmds.join(" ")
              @script.say(msg)
            when "watch"
              return unless @script.commands.keys.include?(words[3])
              return unless watch = @script.commands[words[3]].watch
              msg = "#{@msgPrefix}Watch #{words[3]}: "
              msg += watch.map {|k, v| "#{k}=#{v}"}.join(", ")
              @script.say(msg)
          end
      end
    end
  end

  class CmdHelp < CmdBase
    NAME = "help"
    PATTERNS = %w[!помощь]

    def exec(message)
      list = Array.new
      @script.commands.each do |name, command|
        next if command.class == self.class
        list.concat(command.class::PATTERNS) if command.enabled && command.visible
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

  class CmdFormat < CmdBase
    NAME = "format"
    PATTERNS = %w[!формат]

    CODES = [
      "[ b ] жирный",
      "[ i ] курсив",
      "[ u ] подчеркнутый",
      "[ s ] зачёркнутый",
      "[ sup ] надстрочный",
      "[ sub ] подстрочный",
      "[ c ] светлый",
      "[ ff0000 ] красный",
      "[ 00ff00 ] зеленый",
      "[ 0000ff ] синий",
    ]

    def exec(message)
      msg = "[b][00ffff]" + CODES.join(", ")
      @script.say(msg)
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
      msg.gsub!("%", "[ffff00]#{@script.users[@script.users.keys.sample]["nick"]}[00ff00]")
      @script.say(msg)
    end
  end

  class CmdRoulette < CmdBase
    NAME = "roulette"
    PATTERNS = %w[!рулетка]

    def load
      super
      @config = {
        "counter" => 0,
        "bullets" => 6,
        "mutetime" => 60 * 60,
      } if @config.empty?
    end

    def exec(message)
      msg = "[b][ffff00]#{message["nick"]} "
      if rand(1..@config["bullets"]) == @config["bullets"] / 2
        @script.users[message["id"]]["muteTime"] = Time.now + @config["mutetime"].to_i
        msg += "[ff0000]ПИФ ПАФ! ТЫ УБИТ! ТЕБЯ НЕ БУДЕТ СЛЫШНО [00ff00]#{@config["mutetime"] / 60} [ff0000]МИНУТ!"
        @config["counter"] += 1
        save
      else
        msg += "[00ff00]В ЭТОТ РАЗ ТЕБЕ ПОВЕЗЛО!"
      end
      @script.say(msg)
    end

    def stat
      "[ff1000]ЗАСТРЕЛИЛОСЬ #{@config["counter"]} ЧЕЛОВЕК"
    end

    def watch
      {
        "counter" => @config["counter"],
        "bullets" => @config["bullets"],
        "mutetime" => @config["mutetime"],
        "muted" => @script.users.select {|k, v| !v["muteTime"].nil? && v["muteTime"] >= Time.now}.length
      }
    end
  end

  class CmdCookie < CmdBase
    NAME = "cookie"
    PATTERNS = %w[!печенька]

    def load
      super
      @config = {
        "counter" => 0,
        "fortune" => [],
      } if @config.empty?
    end

    def exec(message)
      if rand(0..1) == 1
        msg = "[ffff00]#{message["nick"]} [00ff00]СЪЕДАЕТ ПЕЧЕНЬКУ И ЧИТАЕТ ПРЕДСКАЗАНИЕ: [60ffda]#{@config["fortune"].sample}"
        @config["counter"] += 1
        save
      else
        msg = "[00ff00]ФИГУШКИ ТЕБЕ [ffff00]#{message["nick"]}[00ff00], А НЕ ПЕЧЕНЬКА!"
      end
      @script.say(msg)
    end

    def stat
      "[ffea4f]СЪЕДЕНО #{@config["counter"]} ПЕЧЕНЕК"
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
      @config = {
        "counter" => 0,
        "users" => {},
      } if @config.empty?
    end

    def exec(message)
      words = message["message"].split(/\s+/)
      msg = String.new
      case words[0]
        when self.class::PATTERNS[0]
          @config["counter"] += 1
          id = message["id"].to_s
          @config["users"][id] = [message["nick"], 0] unless @config["users"].key?(id)
          @config["users"][id] = [message["nick"], @config["users"][id][1] + 1]
          msg = "[b][ff3500]#{MESSAGES.sample} ПРИСОЕДИНЯЙСЯ!"
          msg.gsub!("%", "[ff9ea1]#{@config["counter"]}[ff3500]")
          save
        when self.class::PATTERNS[1]
          if @config["counter"].zero? 
            msg = "[b][7aff38]ЕЩЕ НИКТО НЕ СБАЦАЛ, ТЫ МОЖЕШЬ СТАТЬ ПЕРВЫМ!"
          else
            top = @config["users"].max_by {|k, v| v[1]}
            msg = "[b][ff312a]#{top[1][0]}[7aff38] ХАКЕРЮГА НОМЕР ОДИН! НАБАЦАЛ [ff312a]#{top[1][1]}[7aff38] РАЗ!"
          end
      end
      @script.say(msg)
    end

    def stat
      "[ff312a]БАЦНУТО #{@config["counter"]} РАЗ"
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
      @config = {
        "counter" => 0,
      } if @config.empty?
    end

    def exec(message)
      user = @script.users.keys.sample
      begin
        info = @script.game.cmdPlayerGetInfo(user)
      rescue Trickster::Hackers::RequestError => e
        @script.shell.log("Get player info error (#{e})", :script)
        return
      end
      msg = "[b][ffa62b]ЗАПУСКАЕМ ГУСЯ! ГУСЬ ДЕЛАЕТ КУСЬ [568eff]#{info["name"]}[ffa62b]! В ЕГО КАРМАНАХ НАШЛОСЬ [ff2a16]#{info["money"]} денег[ffa62b], [ff2a16]#{info["bitcoins"]} биткойнов[ffa62b], [ff2a16]#{info["credits"]} кредитов"
      @config["counter"] += 1
      save
      @script.say(msg)
    end

    def stat
      "[3fefff]ЗАПУЩЕНО #{@config["counter"]} ГУСЕЙ"
    end
  end

  class CmdHour < CmdBase
    NAME = "hour"

    def initialize(script)
      super(script)
      @visible = false
      @lastTime = Time.now
      @lastUsers = @script.users.clone
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

      users = @script.users.length - @lastUsers.length
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
      @lastUsers = @script.users.clone
      @script.say(msg)
    end
  end

  class CmdISS < CmdBase
    NAME = "iss"
    PATTERNS = %w[!мкс]

    def load
      super
      @config = {
        "countries" => {},
      } if @config.empty?
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
        @script.shell.log("ISS JSON parser error (#{e})", :script)
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
        @script.shell.log("SpaceX JSON parser error (#{e})", :script)
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
        @script.shell.log("COVID19 JSON parser error (#{e})", :script)
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
      @script.shell.log("Wiki JSON parser error (#{e})", :script)
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
      @config = {
        "counter" => 0,
        "cities" => [],
      } if @config.empty?
    end

    def matched?(message)
      return true unless @city.empty?
      super(message)
    end

    def exec(message)
      return if @config["cities"].empty?
      if @city.empty?
        @city = @config["cities"].sample.downcase
        @cityMasked = @city.clone
        return if @city.empty?
        positions = (1..(@city.length)).to_a.shuffle[0..(@city.length / 2 - 1)]
        positions.each {|p| @cityMasked[p] = "*"}
        @lastTimeHint = Time.now
        msg = "[b][afab73]УГАДАЙТЕ КАКОЙ Я ЗАГАДАЛ ГОРОД: [10ff10]#{@cityMasked.upcase}"
        @script.say(msg)
        return
      end

      pattern = Regexp.new(Regexp.escape(@city), Regexp::IGNORECASE)
      if pattern.match(message["message"])
        msg = "[b][7affe1]#{message["nick"]}[afab73] УГАДАЛ ГОРОД [10ff10]#{@city.upcase}[afab73]!"
        @script.say(msg)
        @city.clear
        @cityMasked.clear
        @config["counter"] += 1
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

    def stat
      "[ffbcdc]ОТГАДАНО #{@config["counter"]} ГОРОДОВ"
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
      @config = {
        "authtime" => 5 * 60,
        "authtimerand" => 2 * 60,
        "checktime" => 60,
        "users" => {},
        "active" => {},
      } if @config.empty?

      @config["active"].keys.each do |id|
        @config["active"][id]["startTime"] = Time.parse(@config["active"][id]["startTime"])
        @config["active"][id]["authTime"] = Time.parse(@config["active"][id]["authTime"])
        @config["active"][id]["checkTime"] = Time.parse(@config["active"][id]["checkTime"])
        config = @script.game.config.clone
        config["id"] = id.to_i
        config["password"] = @config["users"][id]["password"]
        config["sid"] = @config["active"][id]["sid"]
        @config["active"][id]["game"] = Trickster::Hackers::Game.new(config)
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
        game.config["sid"] = auth["sid"]
        game.cmdNetGetForMaint
        @config["active"][id] = {
          "sid" => auth["sid"],
          "startTime" => Time.now,
          "authTime" => Time.now,
          "checkTime" => Time.now,
        }
      rescue Trickster::Hackers::RequestError => e
        @script.shell.log("Tazik auth error for #{id} (#{e})", :script)
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
          @config["active"][id]["game"].config["sid"] = auth["sid"]
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
          @script.shell.log("Tazik poll error for #{id} (#{e})", :script)
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
      return false if !@script.users[message["id"]]["lastTime"].nil? && @script.users[message["id"]]["lastTime"] + @script.config["config"]["flood"].to_i > Time.now
      words = message["message"].split(/\s+/)
      return true if words.include?("@#{@script.config["name"]}")
      return false
    end

    def exec(message)
      msg = "[b][7fffa7]" + ANSWERS.sample
      msg.gsub!("%", message["nick"])
      msg.gsub!("@", Time.now.strftime("%H:%M"))
      @script.say(msg)
    end
  end

  class CmdRanking < CmdBase
    NAME = "ranking"

    def load
      super
      @config = {
        "checktime" => 15 * 60,
        "topnum" => 20,
      } if @config.empty?
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
        @script.shell.log("Get ranking error (#{e})", :script)
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
  
  def initialize(game, shell, args)
    super(game, shell, args)
    Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)

    @room = args[0].to_i
    @users = Hash.new
  end

  def load
    file = "#{DATA_DIR}/main.conf"
    unless File.file?(file)
      @config = {
        "config" => {
          "flood" => "15",
          "repeats" => "4",
          "random" => "on",
          },
        "admins" => [],
        "enabled" => [],
      }
      return true
    end
    begin
      @config = JSON.parse(File.read(file))
    rescue JSON::ParserError => e
      @shell.log("Main config file has invalid format (#{e})", :script)
      return false
    end
    return true
  end

  def save
    file = "#{DATA_DIR}/main.conf"
    File.write(file, JSON.pretty_generate(@config))
  end

  def say(message)
    @game.cmdChatSend(@room, message)
  rescue Trickster::Hackers::RequestError => e
    @shell.log("Say error (#{e})", :script)
  end

  def main
    if @room.nil?
      @shell.log("Specify room ID", :script)
      return
    end

    return unless load
    @config["startup"] = Time.now

    @commands = Hash.new
    @commands[CmdAdmin::NAME] = CmdAdmin.new(self)
    @commands[CmdHelp::NAME] = CmdHelp.new(self)
    @commands[CmdStat::NAME] = CmdStat.new(self)
    @commands[CmdHello::NAME] = CmdHello.new(self)
    @commands[CmdFormat::NAME] = CmdFormat.new(self)
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

    @randomCommands = [
      CmdStat::NAME,
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
    ]

    @config["enabled"].each do |name|
      next unless @commands.keys.include?(name)
      @commands[name].enabled = true
    end

    @shell.log("The bot listens room #{@room}", :script)

    roomLastUser = Hash.new
    roomLastTime = String.new

    begin
      messages = @game.cmdChatDisplay(@room, roomLastTime)
      net = @game.cmdNetGetForMaint
    rescue Trickster::Hackers::RequestError => e
      @shell.log("Initial commands error (#{e})", :script)
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
        @shell.log("Chat display error (#{e})", :script)
        next
      end
      next if messages.empty?
      roomLastTime = messages.last["datetime"]

      messages.each do |message|
        next if message["id"] == @game.config["id"]
        @users[message["id"]] = Hash.new unless @users.key?(message["id"])
        @users[message["id"]]["nick"] = message["nick"]
        next if !@users[message["id"]]["muteTime"].nil? && @users[message["id"]]["muteTime"] >= Time.now

        executed = false
        @commands.each do |name, command|
          if command.matched?(message) && command.enabled
            command.exec(message)
            executed = true
            @users[message["id"]]["lastTime"] = Time.now
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
      end
    end
  end
end

