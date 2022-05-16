# frozen_string_literal: true

module Hackers
  ##
  # Dataset
  class Dataset
    attr_accessor :raw_data

    def initialize(api)
      @api = api
    end

    def loaded?
      !@raw_data.nil?
    end

    def load; end

    private

    def parse; end
  end
end

require_relative 'dataset/app_settings'
require_relative 'dataset/language_translations'
require_relative 'dataset/nodes'
require_relative 'dataset/node_types'
require_relative 'dataset/programs'
require_relative 'dataset/program_types'
require_relative 'dataset/missions_list'
require_relative 'dataset/skin_types'
require_relative 'dataset/hints_list'
require_relative 'dataset/experience_list'
require_relative 'dataset/builders_list'
require_relative 'dataset/goal_types'
require_relative 'dataset/network'
require_relative 'dataset/chat'
