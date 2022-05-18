# frozen_string_literal: true

module Hackers
  module Utils
    ##
    # Converts a timer to human readable format
    def self.timer_dhms(timer)
      dhms = []
      dhms << format('%02d', timer / 60 / 60 / 24)
      dhms << format('%02d', timer / 60 / 60 % 24)
      dhms << format('%02d', timer / 60 % 60)
      dhms << format('%02d', timer / 60 % 60)
      dhms << format('%02d', timer % 60)
      dhms.join(':')
    end
  end
end
