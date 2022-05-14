# frozen_string_literal: true

module Hackers
  ##
  # Data set
  class Dataset
    attr_reader :raw_data

    def initialize(api)
      @api = api
    end

    def loaded?
      !@raw_data.nil?
    end

    def load; end
  end
end

require_relative 'dataset/app_settings'
require_relative 'dataset/language_translations'
require_relative 'dataset/node_types'
require_relative 'dataset/program_types'
require_relative 'dataset/missions_list'
require_relative 'dataset/skin_types'
