# frozen_string_literal: true

require 'thread'

CHAT_ROOMS = {}
CHAT_LOG_CHAR = "\u2764"
CHAT_LIST_CHAR = "\u2022"
CHAT_TALK_CHAR = "\u2765"

def chat_read(shell, room)
  loop do
    begin
      messages = GAME.chat.read(room)
    rescue Hackers::RequestError => e
      LOGGER.error("Chat read (#{e})")
    else
      chat_log(shell, room, messages)
    end

    sleep(GAME.app_settings.get('chat_refresh_interval'))
  end
end

def chat_log(shell, room, messages)
  messages.each do |message|
    shell.puts(
      ::Kernel.format(
        '%s [%s:%s] %s %s %s',
        ColorTerm.brown.bold(CHAT_LOG_CHAR),
        ColorTerm.blue(GAME.countries_list.name(room)),
        ColorTerm.blue(room),
        ColorTerm.red(GAME.experience_list.level(message.experience)),
        ColorTerm.magenta.bold(message.name),
        ColorTerm.brown(message.message)
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
  unless GAME.connected? || GAME.app_settings.loaded?
    shell.puts(NOT_CONNECTED)
    next
  end

  room = tokens[1].to_i
  if CHAT_ROOMS.key?(room)
    shell.puts("Room #{room} already opened")
    next
  end

  GAME.chat.open(room)
  CHAT_ROOMS[room] = Thread.new { chat_read(shell, room) }
end

CONTEXT_CHAT_OPEN.completion do |line|
  countries = GAME.countries_list.select { |c| c.id.to_s =~ /^#{Regexp.escape(line)}/ }
  countries.map { |c| c.id.to_s }
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

  CHAT_ROOMS[room].kill
  CHAT_ROOMS.delete(room)
  GAME.chat.close(room)
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
      ::Kernel.format(
        ' %s %-4d (%s)',
        ColorTerm.brown.bold(CHAT_LIST_CHAR),
        k,
        GAME.countries_list.name(k)
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

  messages = GAME.chat.write(room, tokens[2..].join(' '))
  chat_log(shell, room, messages)
rescue Hackers::RequestError => e
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

  shell.puts('Enter ! or press ^D to quit')
  loop do
    prompt = "#{GAME.countries_list.name(room)}:#{room} #{ColorTerm.brown.bold(CHAT_TALK_CHAR)} "
    message = shell.readline(prompt, true)
    if message.nil?
      shell.puts
      break
    end

    message.strip!
    next if message.empty?

    break if message == '!'

    messages = GAME.chat.write(room, message)
    chat_log(shell, room, messages)
  rescue Hackers::RequestError => e
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
  unless GAME.connected? || GAME.app_settings.loaded?
    shell.puts(NOT_CONNECTED)
    next
  end

  room = tokens[1].to_i

  chat = Hackers::Chat.new(GAME.api)
  chat.open(room)
  messages = chat.read(room)
  chat.close(room)
  if messages.empty?
    shell.puts("No users in room #{room}")
    next
  end

  messages.uniq! { |m| m.id }
  shell.puts(
    format(
      'Users in room %d (%s)',
      room,
      GAME.countries_list.name(room)
    )
  )

  messages.each do |message|
    shell.puts(
      format(
        ' %-30s .. %d',
        message.name,
        message.id
      )
    )
  end
rescue Hackers::RequestError => e
  LOGGER.error("Chat read (#{e})")
end

CONTEXT_CHAT_USERS.completion do |line|
  countries = GAME.countries_list.select { |c| c.id.to_s =~ /^#{Regexp.escape(line)}/ }
  countries.map { |c| c.id.to_s }
end
