# frozen_string_literal: true

module Hackers
  ##
  # Chat
  class Chat < Dataset
    include Enumerable

    Room = Struct.new(:id, :last_message)
    Message = Struct.new(
      :datetime,
      :name,
      :message,
      :id,
      :experience,
      :rank,
      :country
    )

    def initialize(api)
      @api = api

      @rooms = []
    end

    def each(&block)
      @rooms.each(&block)
    end

    def opened?(room)
      @rooms.any? { |r| r.id == room }
    end

    def open(room)
      return if opened?(room)

      @rooms << Room.new(room, String.new)
    end

    def close(room)
      @rooms.delete_if { |r| r.id == room }
    end

    def read(room)
      return unless opened?(room)

      room = @rooms.detect { |r| r.id == room }
      raw_data = @api.read_chat(room.id, room.last_message)
      data = Serializer.parseData(raw_data)
      parse(data.dig(0), room)
    end

    def write(room, message)
      return unless opened?(room)

      room = @rooms.detect { |r| r.id == room }
      raw_data = @api.write_chat(
        room.id,
        Serializer.normalizeData(message, false),
        room.last_message
      )

      data = Serializer.parseData(raw_data)
      parse(data.dig(0), room)
    end

    private

    def parse(data, room)
      messages = []
      return messages if data.nil?

      data.reverse.each do |record|
        room.last_message = record[0]
        messages << Message.new(
          record[0],
          record[1],
          record[2],
          record[3].to_i,
          record[4].to_i,
          record[5].to_i,
          record[6].to_i
        )
      end

      messages
    end
  end
end
