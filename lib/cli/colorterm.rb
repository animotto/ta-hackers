# frozen_string_literal: true

module ColorTerm
  def self.method_missing(method, text = nil)
    super unless respond_to_missing?(method)

    cterm = CTerm.new
    cterm.send(method, text)
  end

  def self.respond_to_missing?(method)
    CTerm.has_sgi?(method)
  end

  ##
  # CTerm
  class CTerm
    FOREGROND_COLORS = {
      black: 30,
      red: 31,
      green: 32,
      brown: 33,
      blue: 34,
      magenta: 35,
      cyan: 36,
      white: 37
    }

    BACKGROUND_COLORS = {
      black_back: 40,
      red_back: 41,
      green_back: 42,
      brown_back: 43,
      blue_back: 44,
      magenta_back: 45,
      cyan_back: 46,
      white_back: 47
    }

    STYLES = {
      bold: 1,
      half_bright: 2,
      italic: 3,
      underscore: 4,
      blink: 5,
      reverse: 7
    }

    RESET = 0
    CSI = "\e["
    SGI = 'm'

    def self.has_sgi?(name)
      FOREGROND_COLORS.has_key?(name) || BACKGROUND_COLORS.has_key?(name) || STYLES.has_key?(name)
    end

    def initialize
      @sgi = []
    end

    def get(text)
      sgi = @sgi.join(';')
      return [CSI, sgi, SGI, text, CSI, RESET, SGI].join
    end

    def method_missing(method, text = nil)
      super unless respond_to_missing?(method)

      @sgi << (FOREGROND_COLORS[method] || BACKGROUND_COLORS[method] || STYLES[method])
      return self unless text

      return get(text)
    end

    def respond_to_missing?(method, text = nil)
      self.class.has_sgi?(method)
    end
  end
end
