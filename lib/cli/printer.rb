# frozen_string_literal: true

module Printer
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
      title_length = @titles.inject(0) { |a, t| t.length > a ? t.length : a }
      list = ["\e[1;35m\u2022 #{@header}\e[0m"]
      @titles.each_with_index do |title, i|
        list << Kernel.format(
          "  \e[35m%-#{title_length}s\e[0m  %s",
          title,
          @items[i]
        )
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
      table = ["\e[1;35m\u2022 #{@header}\e[0m"]

      column_length = @titles.map(&:length)
      @items.each do |item|
        item.each_with_index do |col, i|
          length = col.to_s.length
          column_length[i] = length if length > column_length[i]
        end
      end

      titles = []
      @titles.each_with_index do |title, i|
        titles << Kernel.format(
          "\e[35m%-#{column_length[i]}s\e[0m",
          title
        )
      end
      table << titles.join(' ').prepend('  ')

      @items.each.with_index do |item, i|
        row = []
        item.each_with_index do |col, j|
          row << Kernel.format(
            "%-#{column_length[j]}s",
            col
          )
        end
        row = row.join(' ').prepend('  ')
        row = "\e[37;45m#{row}\e[0m" if @selected.include?(i)
        table << row
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
end
