# frozen_string_literal: true

require 'thread'

CHAT_ROOMS = {}

def chat_read(shell, room)
  loop do
    begin
      messages = CHAT_ROOMS[room][:chat].read
    rescue Trickster::Hackers::RequestError => e
      LOGGER.error("Chat read (#{e})")
    else
      chat_log(shell, room, messages)
    end

    sleep(GAME.appSettings['chat_refresh_interval'].to_i)
  end
end

def chat_log(shell, room, messages)
  messages.each do |message|
    shell.puts(
      format(
        "\e[1;33m\u2764 \e[22;34m[%s:%d] \e[22;31m%d \e[1;35m%s \e[22;33m%s\e[0m",
        GAME.getCountryNameByID(room.to_s),
        room,
        GAME.getLevelByExp(message.experience),
        message.nick,
        message.message
      )
    )
  end
end

## Commands

# open
CONTEXT_CHAT_OPEN = CONTEXT_CHAT.add_command(
  :open,
  description: 'Open room',
  params: ['<room>']
) do |tokens, shell|
  if GAME.sid.empty? || GAME.appSettings.empty?
    shell.puts('Not connected')
    next
  end

  room = tokens[1].to_i
  if CHAT_ROOMS.key?(room)
    shell.puts("Room #{room} already opened")
    next
  end

  CHAT_ROOMS[room] = {
    :chat => GAME.getChat(room),
    :thread => Thread.new { chat_read(shell, room) }
  }
end

CONTEXT_CHAT_OPEN.completion do |line|
  GAME.countriesList.keys.grep(/^#{Regexp.escape(line)}/)
end

# close
CONTEXT_CHAT_CLOSE = CONTEXT_CHAT.add_command(
  :close,
  description: 'Close room',
  params: ['<room>']
) do |tokens, shell|
  room = tokens[1].to_i
  unless CHAT_ROOMS.key?(room)
    shell.puts('No such opened room')
    next
  end

  CHAT_ROOMS[room][:thread].kill
  CHAT_ROOMS.delete(room)
end

CONTEXT_CHAT_CLOSE.completion do |line|
  CHAT_ROOMS.keys.map(&:to_s).grep(/^#{Regexp.escape(line)}/)
end

# list
CONTEXT_CHAT.add_command(
  :list,
  description: 'List opened rooms'
) do |tokens, shell|
  if CHAT_ROOMS.empty?
    shell.puts('No opened rooms')
    next
  end

  shell.puts "Opened rooms:"
  CHAT_ROOMS.each_key do |k|
    shell.puts(
      format(
      " \e[1;33m\u2022\e[0m %-4d (%s)",
      k,
      GAME.getCountryNameByID(k.to_s),
      )
    )
  end
end

# say
CONTEXT_CHAT_SAY = CONTEXT_CHAT.add_command(
  :say,
  description: 'Say to the room',
  params: ['<room>', '<text>']
) do |tokens, shell|
  room = tokens[1].to_i
  unless CHAT_ROOMS.key?(room)
    @shell.puts('No such opened room')
    next
  end

  messages = CHAT_ROOMS[room][:chat].write(tokens[2..-1].join(' '))
  chat_log(shell, room, messages)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("Chat write (#{e})")
end

CONTEXT_CHAT_SAY.completion do |line|
  CHAT_ROOMS.keys.map(&:to_s).grep(/^#{Regexp.escape(line)}/)
end

# talk
CONTEXT_CHAT_TALK = CONTEXT_CHAT.add_command(
  :talk,
  description: 'Talk in the room',
  params: ['<room>']
) do |tokens, shell|
  room = tokens[1].to_i
  unless CHAT_ROOMS.key?(room)
    shell.puts('No such opened room')
    next
  end

  shell.puts('Enter ! or ^D to quit')
  loop do
    prompt = "#{GAME.getCountryNameByID(room.to_s)}:#{room} \e[1;33m\u2765\e[0m "
    message = shell.readline(prompt, true)
    if message.nil?
      shell.puts
      break
    end

    message.strip!
    next if message.empty?

    break if message == '!'

    messages = CHAT_ROOMS[room][:chat].write(message)
    chat_log(shell, room, messages)
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("Chat write (#{e})")
  end
end

CONTEXT_CHAT_TALK.completion do |line|
  CHAT_ROOMS.keys.map(&:to_s).grep(/^#{Regexp.escape(line)}/)
end

# users
CONTEXT_CHAT_USERS = CONTEXT_CHAT.add_command(
  :users,
  description: 'Show users list in the room',
  params: ['<room>']
) do |tokens, shell|
  if GAME.sid.empty? || GAME.appSettings.empty?
    shell.puts('Not connected')
    next
  end

  room = tokens[1].to_i

  chat = GAME.getChat(room)
  messages = chat.read
  if messages.empty?
    shell.puts("No users in room #{room}")
    next
  end

  messages.uniq! { |m| m.id }
  shell.puts(
    format(
      'Users in room %d (%s)',
      room,
      GAME.getCountryNameByID(room.to_s)
    )
  )

  messages.each do |message|
    shell.puts(
      format(
        ' %-30s .. %d',
        message.nick,
        message.id
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("Chat read (#{e})")
end

CONTEXT_CHAT_USERS.completion do |line|
  GAME.countriesList.keys.grep(/^#{Regexp.escape(line)}/)
end
