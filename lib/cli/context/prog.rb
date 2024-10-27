# frozen_string_literal: true

## Commands

# list
CONTEXT_PROG.add_command(
  :list,
  description: 'Show programs list'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  programs = player.programs

  items = []
  programs.each do |program|
    timer = String.new
    timer = Hackers::Utils.timer_dhms(program.timer * -1) if program.timer.negative?

    items << [
      program.id,
      GAME.program_types.get(program.type).name,
      program.type,
      program.amount,
      program.level,
      timer
    ]
  end

  table = Printer::Table.new(
    'Programs',
    ['ID', 'Name', 'Type', 'Amount', 'Level', 'Timer'],
    items
  )
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# queue
CONTEXT_PROG.add_command(
  :queue,
  description: 'Show programs queue'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  programs = player.programs
  queue = player.queue

  items = []
  total = 0
  queue.each do |item|
    program = programs.detect { |p| p.type == item.type }
    program_type = GAME.program_types.get(item.type)
    compile = program_type.compilation_time(program.level)
    total += item.amount * compile - item.timer
    items << [
      program_type.name,
      item.type,
      item.amount,
      compile - item.timer
    ]
  end

  table = Printer::Table.new(
    'Programs queue',
    ['Name', 'Type', 'Amount', 'Timer'],
    items
  )
  shell.puts(table)

  shell.puts
  list = Printer::List.new(
    'Queue info',
    ['Sequence', 'Total'],
    [queue.sequence, Hackers::Utils.timer_dhms(total)]
  )
  shell.puts(list)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# create
CONTEXT_PROG.add_command(
  :create,
  description: 'Create program',
  params: ['<type>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  type = tokens[1].to_i

  msg = 'Create program'
  GAME.player.programs.create(type)
  LOGGER.log(msg)

  shell.puts("Program #{GAME.program_types.get(type).name} (#{type}) has been created")
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# upgrade
CONTEXT_PROG.add_command(
  :upgrade,
  description: 'Upgrade program',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i

  unless GAME.player.loaded?
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  programs = GAME.player.programs

  unless programs.exist?(id)
    shell.puts('No such program')
    next
  end

  msg = 'Upgrade program'
  programs.get(id).upgrade
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# finish
CONTEXT_PROG.add_command(
  :finish,
  description: 'Finish program',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i

  unless GAME.player.loaded?
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  programs = GAME.player.programs

  unless programs.exist?(id)
    shell.puts('No such program')
    next
  end

  msg = 'Finish program'
  programs.get(id).finish
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# edit
CONTEXT_PROG.add_command(
  :edit,
  description: 'Edit programs',
  params: ['<type>', '<amount>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  unless (tokens.length - 1).even?
    shell.puts('Invalid programs data')
    next
  end

  unless GAME.player.loaded?
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  programs = GAME.player.programs

  0.step(tokens.length - 1, 2) do |i|
    programs.edit(tokens[i + 1].to_i, tokens[i + 2].to_i)
  end

  msg = 'Delete program'
  programs.update
  LOGGER.log(msg)

  items = []
  programs.each do |program|
    timer = String.new
    timer = Hackers::Utils.timer_dhms(program.timer * -1) if program.timer.negative?

    items << [
      program.id,
      GAME.program_types.get(program.type).name,
      program.type,
      program.amount,
      program.level,
      timer
    ]

  table = Printer::Table.new(
    'Programs',
    ['ID', 'Name', 'Type', 'Amount', 'Level', 'Timer'],
    items
  )
  shell.puts(table)
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# sync
CONTEXT_PROG.add_command(
  :sync,
  description: 'Set programs queue',
  params: ['<type>', '<amount>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  unless (tokens.length - 1).even?
    shell.puts('Invalid programs data')
    next
  end

  player = GAME.player
  programs = player.programs
  queue = player.queue

  0.step(tokens.length - 1, 2) do |i|
    queue.add(tokens[i + 1].to_i, tokens[i + 2].to_i)
  end

  msg = 'Sync queue'
  queue.sync
  LOGGER.log(msg)

  items = []
  total = 0
  queue.each do |item|
    program = programs.detect { |p| p.type == item.type }
    program_type = GAME.program_types.get(item.type)
    compile = program_type.compilation_time(program.level)
    total += item.amount * compile - item.timer
    items << [
      program_type.name,
      item.type,
      item.amount,
      compile - item.timer
    ]
  end

  table = Printer::Table.new(
    'Programs queue',
    ['Name', 'Type', 'Amount', 'Timer'],
    items
  )
  shell.puts(table)

  shell.puts
  list = Printer::List.new(
    'Queue info',
    ['Sequence', 'Total'],
    [queue.sequence, Hackers::Utils.timer_dhms(total)]
  )
  shell.puts(list)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# revive
CONTEXT_PROG.add_command(
  :revive,
  description: 'Revive AI program',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i

  unless GAME.player.loaded?
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  programs = GAME.player.programs

  unless programs.exist?(id)
    shell.puts('No such program')
    next
  end

  msg = 'AI program revive'
  programs.get(id).revive
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
