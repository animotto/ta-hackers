# frozen_string_literal: true

module Hackers
  ##
  # Program types
  class ProgramTypes < Dataset
    def load
      @raw_data = @api.program_types
    end

    def exist?(type)
      @raw_data.key?(type)
    end

    def each(&block)
      @raw_data.keys.each(&block)
    end

    def levels(type)
      @raw_data[type]['levels'].keys
    end

    def name(type)
      @raw_data[type]['name']
    end

    def cost(type, level)
      @raw_data[type]['levels'][level]['cost']
    end

    def experience(type, level)
      @raw_data[type]['levels'][level]['experience']
    end

    def price(type, level)
      @raw_data[type]['levels'][level]['price']
    end

    def compile(type, level)
      @raw_data[type]['levels'][level]['compile']
    end

    def disk(type, level)
      @raw_data[type]['levels'][level]['disk']
    end

    def install(type, level)
      @raw_data[type]['levels'][level]['install']
    end

    def upgrade(type, level)
      @raw_data[type]['levels'][level]['upgrade']
    end

    def rate(type, level)
      @raw_data[type]['levels'][level]['rate']
    end

    def strength(type, level)
      @raw_data[type]['levels'][level]['strength']
    end

    def evolver(type, level)
      @raw_data[type]['levels'][level]['evolver']
    end
  end
end
