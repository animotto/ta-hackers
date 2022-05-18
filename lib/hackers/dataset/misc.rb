# frozen_string_literal: true

module Hackers
  Account = Struct.new(:id, :password, :sid)
  PlayerDetails = Struct.new(:profile, :network)
end
