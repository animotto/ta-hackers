# frozen_string_literal: true

## Commands

# list
CONTEXT_PROG.add_command(
  :list,
  description: 'Show programs list'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  programs = player.programs

  shell.puts("\e[1;35m\u2022 Programs\e[0m")
  shell.puts(
    format(
      "  \e[35m%-12s %-12s %-4s %-6s %-5s %-12s\e[0m",
      'ID',
      'Name',
      'Type',
      'Amount',
      'Level',
      'Timer'
    )
  )

  programs.each do |program|
    timer = String.new
    timer = GAME.timerToDHMS(program.timer * -1) if program.timer.negative?

    shell.puts(
      format(
        '  %-12d %-12s %-4d %-6d %-5d %-12s',
        program.id,
        GAME.program_types.get(program.type).name,
        program.type,
        program.amount,
        program.level,
        timer
      )
    )
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# queue
CONTEXT_PROG.add_command(
  :queue,
  description: 'Show programs queue'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  programs = player.programs
  queue = player.queue

  shell.puts("\e[1;35m\u2022 Programs queue\e[0m")
  shell.puts(
    format(
      "  \e[35m%-12s %-4s %-6s %-5s\e[0m",
      'Name',
      'Type',
      'Amount',
      'Timer'
    )
  )

  total = 0
  queue.each do |item|
    program = programs.detect { |p| p.type == item.type }
    program_type = GAME.program_types.get(item.type)
    compile = program_type.compilation_time(program.level)
    total += item.amount * compile - item.timer
    shell.puts(
      format(
        '  %-12s %-4d %-6d %-5d',
        program_type.name,
        item.type,
        item.amount,
        compile - item.timer
      )
    )
  end

  shell.puts
  shell.puts("  \e[35mSequence: #{GAME.syncSeq}\e[0m")
  shell.puts("  \e[35mTotal: #{GAME.timerToDHMS(total)}\e[0m") unless total.zero?
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# create
CONTEXT_PROG.add_command(
  :create,
  description: 'Create program',
  params: ['<type>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  type = tokens[1].to_i

  msg = 'Create program'
  id = GAME.cmdCreateProgram(type)
  LOGGER.log(msg)
  shell.puts("Program #{type} has been created")
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# upgrade
CONTEXT_PROG.add_command(
  :upgrade,
  description: 'Upgrade program',
  params: ['<id>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i

  msg = 'Upgrade program'
  GAME.cmdUpgradeProgram(id)
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
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i

  msg = 'Finish program'
  GAME.cmdFinishProgram(id)
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
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  unless (tokens.length - 1).even?
    shell.puts('Invalid programs data')
    next
  end

  programs = {}
  0.step(tokens.length - 1, 2) do |i|
    programs[tokens[i + 1].to_i] = tokens[i + 2].to_i
  end

  msg = 'Delete program'
  programs = GAME.cmdDeleteProgram(programs)
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Programs\e[0m")
  shell.puts(
    format(
      "  \e[35m%-12s %-4s %-6s\e[0m",
      'Name',
      'Type',
      'Amount'
    )
  )

  programs.each do |k, v|
    shell.puts(
      format(
        '  %-12s %-4d %-6d',
        GAME.program_types.get(k).name,
        k,
        v["amount"]
      )
    )
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
  if GAME.sid.empty?
    shell.puts('No session ID')
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
  GAME.player.queue_sync
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Programs queue\e[0m")
  shell.puts(
    format(
      "  \e[35m%-12s %-4s %-6s %-5s\e[0m",
      'Name',
      'Type',
      'Amount',
      'Timer'
    )
  )

  total = 0
  queue.each do |item|
    program = programs.detect { |p| p.type == item.type }
    program_type = GAME.program_types.get(item.type)
    compile = program_type.compilation_time(program.level)
    total += item.amount * compile - item.timer
    shell.puts(
      format(
        '  %-12s %-4d %-6d %-5d',
        program_type.name,
        item.type,
        item.amount,
        compile - item.timer
      )
    )
  end

  shell.puts
  shell.puts("  \e[35mSequence: #{GAME.syncSeq}\e[0m")
  shell.puts("  \e[35mTotal: #{GAME.timerToDHMS(total)}\e[0m") unless total.zero?
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# revive
CONTEXT_PROG.add_command(
  :revive,
  description: 'Revive AI program',
  params: ['<id>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i

  msg = 'AI program revive'
  id = GAME.cmdAIProgramRevive(id)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
