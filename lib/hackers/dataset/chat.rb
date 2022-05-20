# frozen_string_literal: true

module Hackers
  ##
  # Chat
  class Chat < Dataset
    include Enumerable

    Room = Struct.new(:id, :last_message)

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
      serializer = Serializer::Chat.new(raw_data)
      data = serializer.parse(0)
      parse(data, room)
    end

    def write(room, message)
      return unless opened?(room)

      serializer_message = Serializer::ChatMessage.new
      room = @rooms.detect { |r| r.id == room }
      raw_data = @api.write_chat(
        room.id,
        serializer_message.generate(message),
        room.last_message
      )

      serializer_chat = Serializer::Chat.new(raw_data)
      data = serializer_chat.parse(0)
      parse(data, room)
    end

    private

    def parse(data, room)
      messages = []
      data.each do |message|
        room.last_message = message.datetime
        messages << message
      end

      messages
    end
  end
end
