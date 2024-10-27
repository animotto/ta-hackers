# frozen_string_literal: true

module Printer
  HEADER_CHAR = "\u2022"

  ##
  # List
  class List
    def initialize(header, titles, items)
      @header = header
      @titles = titles
      @items = items

      raise ArgumentError, 'The length of the title and item arrays is not equal' if @titles.length != @items.length
    end

    def to_s
      list = [ColorTerm.magenta.bold("#{HEADER_CHAR} #{@header}")]

      if @items.empty?
        list << '  Empty'
      else
        @titles.map! { |t| ColorTerm.magenta.italic(t) }
        title_length = @titles.inject(0) { |a, t| t.length > a ? t.length : a }
        @titles.each_with_index do |title, i|
          list << ::Kernel.format(
            "  %-#{title_length}s  %s",
            title,
            @items[i]
          )
        end
      end

      list.join("\n")
    end
  end

  ##
  # Table
  class Table
    def initialize(header, titles, items, selected = [])
      @header = header
      @titles = titles
      @items = items
      @selected = selected

      @items.each do |item|
        raise ArgumentError, 'The length of the title and item arrays is not equal' if @titles.length != item.length
      end
    end

    def to_s
      table = [ColorTerm.magenta.bold("#{HEADER_CHAR} #{@header}")]

      if @items.empty?
        table << '  Empty'
      else
        column_length = @titles.map(&:length)
        @items.each do |item|
          item.each_with_index do |col, i|
            c = col.to_s.gsub(/\e\[[\d;]*[[:alpha:]]/, '')
            column_length[i] = c.length if c.length > column_length[i]
          end
        end

        titles = []
        @titles.each_with_index do |title, i|
          titles << ::Kernel.format(
            ColorTerm.magenta.italic("%-#{column_length[i]}s"),
            title
          )
        end
        table << titles.join(' ').prepend('  ')

        @items.each.with_index do |item, i|
          row = []
          item.each_with_index do |col, j|
            row << ::Kernel.format(
              "%-#{column_length[j]}s",
              col
            )
          end
          row = row.join(' ').prepend('  ')
          row = ColorTerm.white.magenta_back(row) if @selected.include?(i)
          table << row
        end
      end

      table.join("\n")
    end
  end

  ##
  # Base printer
  class BasePrinter
    def initialize(data)
      @data = data
    end

    private

    def parse; end
  end

  ##
  # Stats
  class Stats < BasePrinter
    def to_s
      List.new(
        'Player statistics',
        [
          'Rank',
          'Experience',
          'Level',
          'Hacks successful',
          'Hacks failed',
          'Hacks win rate',
          'Defense successful',
          'Defense failed',
          'Defense win rate',
          'Looted money',
          'Looted bitcoins',
          'Collected money',
          'Collected bitcoins'
        ],
        [
          @data[:rank],
          @data[:experience],
          @data[:level],
          @data[:hacks_success],
          @data[:hacks_fail],
          @data[:hacks_winrate],
          @data[:defense_success],
          @data[:defense_fail],
          @data[:defense_winrate],
          @data[:looted_money],
          @data[:looted_bitcoins],
          @data[:collected_money],
          @data[:collected_bitcoins]
        ]
      ).to_s
    end
  end

  ##
  # Profile
  class Profile < BasePrinter
    BUILDERS_BUSY_CHAR = "\u25b0"
    BUILDERS_FREE_CHAR = "\u25b1"
    BITCOIN_CHAR = "\u20bf"

    attr_accessor :tutorial, :shield, :builders_busy,
                  :capacity_money, :capacity_bitcoins

    def initialize(data, game)
      super(data)

      @game = game
      @builders_busy = 0
    end

    def to_s
      parse
      List.new('Profile', @titles, @items).to_s
    end

    private

    def parse
      @titles = [
        'ID',
        'Name',
        'Money',
        'Bitcoins',
        'Credits',
        'Experience',
        'Rank',
        'Builders',
        'X',
        'Y',
        'Country',
        'Skin',
        'Level'
      ]

      if @capacity_money
        money = [@data.money, @capacity_money].join(' / ')
      else
        money = @data.money
      end

      if @capacity_bitcoins
        bitcoins = [@data.bitcoins, @capacity_bitcoins].join(' / ')
      else
        bitcoins = @data.bitcoins
      end

      builders_busy = Array.new(@builders_busy, ColorTerm.green(BUILDERS_BUSY_CHAR))
      builders_free = Array.new(@data.builders - @builders_busy, ColorTerm.white(BUILDERS_FREE_CHAR))

      @items = [
        @data.id,
        @data.name,
        ColorTerm.brown("$ #{money}"),
        ColorTerm.red("#{BITCOIN_CHAR} #{bitcoins}"),
        @data.credits,
        @data.experience,
        @data.rank,
        (builders_busy + builders_free).join(' '),
        @data.x,
        @data.y,
        "#{@game.countries_list.name(@data.country)} (#{@data.country})",
        @data.skin,
        @game.experience_list.level(@data.experience)
      ]

      if @tutorial
        @titles << 'Tutorial'
        @items << @tutorial
      end

      if @shield
        @titles << 'Shield'
        @items << (@shield.installed? ? "#{@game.shield_types.get(@shield.type).title} (#{@shield.time})" : '-')
      end
    end
  end

  ##
  # Logs
  class Logs < BasePrinter
    SUCCESS_CHAR = "\u25b2"

    def to_s
      parse
      Printer::Table.new(
        self.class::TITLE,
        ['', '', 'ID', 'Datetime', 'Level', self.class::PLAYER, 'Name'],
        @items
      ).to_s
    end

    private

    def format_success(data)
      line = []
      line << ((data & Hackers::Network::SUCCESS_CORE).zero? ? SUCCESS_CHAR : ColorTerm.green(SUCCESS_CHAR))
      line << ((data & Hackers::Network::SUCCESS_RESOURCES).zero? ? SUCCESS_CHAR : ColorTerm.green(SUCCESS_CHAR))
      line << ((data & Hackers::Network::SUCCESS_CONTROL).zero? ? SUCCESS_CHAR : ColorTerm.green(SUCCESS_CHAR))
      line.join
    end
  end

  ##
  # Logs security
  class LogsSecurity < Logs
    TITLE = 'Security'
    PLAYER = 'Attacker'

    private

    def parse
      @items = @data.map do |r|
        [
          format_success(r.success),
          ::Kernel.format('%+d', r.rank),
          r.id,
          r.datetime,
          r.attacker_level,
          r.attacker_id,
          r.attacker_name
        ]
      end
    end
  end

  ##
  # Logs hacks
  class LogsHacks < Logs
    TITLE = 'Hacks'
    PLAYER = 'Target'

    private

    def parse
      @items = @data.map do |r|
        [
          format_success(r.success),
          ::Kernel.format('%+d', r.rank),
          r.id,
          r.datetime,
          r.target_level,
          r.target_id,
          r.target_name
        ]
      end
    end
  end

  ##
  # Network
  class Network < BasePrinter
    def initialize(data, game)
      super(data)

      @game = game
    end

    def to_s
      Table.new(
        'Network topology',
        [
          'ID',
          'Name',
          'Type',
          'Level',
          'X',
          'Y',
          'Z',
          'Relations'
        ],
        @data.map do |n|
          [
            n.id,
            @game.node_types.get(n.type).name,
            n.type,
            n.level,
            ::Kernel.format('%+d', n.x),
            ::Kernel.format('%+d', n.y),
            ::Kernel.format('%+d', n.z),
            n.relations.map { |r| r.id }
          ]
        end
      ).to_s
    end
  end

  ##
  # Top players
  class TopPlayers < BasePrinter
    def initialize(data, game)
      super(data)

      @game = game
    end

    def to_s
      Table.new(
        'Top players',
        [
          'ID',
          'Level',
          'Rank',
          'Country',
          'Name'
        ],
        @data.map do |p|
          [
            p.id,
            @game.experience_list.level(p.experience),
            p.rank,
            ::Kernel.format("%s (%d)", @game.countries_list.name(p.country), p.country),
            p.name
          ]
        end,
        [@data.index { |p| p.id == @game.player.profile.id }]
      ).to_s
    end
  end

  ##
  # Top countries
  class TopCountries < BasePrinter
    def initialize(data, game)
      super(data)

      @game = game
    end

    def to_s
      Table.new(
        'Top countries',
        [
          'ID',
          'Rank',
          'Country'
        ],
        @data.map do |c|
          [
            c.id,
            c.rank,
            @game.countries_list.name(c.id)
          ]
        end,
        [@data.index { |c| c.id == @game.player.profile.country }]
      ).to_s
    end
  end
end
