# frozen_string_literal: true

module Hackers
  EXCEPTION_TYPE = 'Exception'

  ##
  # Base exception
  class ExceptionError < RequestError; end

  ##
  # The API server always returns a success response, even the creation of a new node fails
  # We fix this behavior and raise this exception
  class CreateNodeError < ExceptionError
    def initialize(*)
      super
      @type = EXCEPTION_TYPE
      @description = 'Create node error'
    end
  end

  ##
  # Exception: maximum node level reached
  class MaximumNodeLevelError < ExceptionError; end

  ##
  # Exception: too many builders requested
  class TooManyBuilders < ExceptionError; end

  ##
  # Exception: mission already finished
  class MissionAlreadyFinishedError < ExceptionError; end

  ##
  # Exceptions list
  EXCEPTIONS = {
    'maximum node level reached' => MaximumNodeLevelError,
    'too many builders requested' => TooManyBuilders,
    'mission already finished' => MissionAlreadyFinishedError
  }.freeze

end
