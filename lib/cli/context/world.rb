# frozen_string_literal: true

## Commands

# targets
CONTEXT_WORLD.add_command(
  :targets,
  description: 'Show targets'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  msg = 'World'
  world = GAME.cmdPlayerWorld(net['profile'].country)
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Targets\e[0m")
  shell.puts(
    format(
      "  \e[35m%-12s %-6s %-8s %-8s %-8s %s\e[0m",
      'ID',
      'Level',
      'X',
      'Y',
      'Country',
      'Name'
    )
  )

  world['targets'].each do |k, v|
    shell.puts(
      format(
        '  %-12d %-6d %+-8d %+-8d %-8d %s',
        k,
        GAME.getLevelByExp(v['experience']),
        v['x'],
        v['y'],
        v['country'],
        v['name']
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# new
CONTEXT_WORLD.add_command(
  :new,
  description: 'Get new targets'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Get new targets'
  targets = GAME.cmdGetNewTargets
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Targets\e[0m")
  shell.puts(
    format(
      "  \e[35m%-12s %-6s %-8s %-8s %-8s %s\e[0m",
      'ID',
      'Level',
      'X',
      'Y',
      'Country',
      'Name'
    )
  )

  targets['targets'].each do |k, v|
    shell.puts(
      format(
        '  %-12d %-6d %+-8d %+-8d %-8d %s',
        k,
        GAME.getLevelByExp(v['experience']),
        v['x'],
        v['y'],
        v['country'],
        v['name']
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# bonuses
CONTEXT_WORLD.add_command(
  :bonuses,
  description: 'Show bonuses'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  msg = 'World'
  world = GAME.cmdPlayerWorld(net['profile'].country)
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Bonuses\e[0m")
  shell.puts(
    format(
      "  \e[35m%-12s %-2s\e[0m",
      'ID',
      'Amount'
    )
  )

  world['bonuses'].each do |k, v|
    shell.puts(
      format(
        '  %-12d %-2d',
        k,
        v['amount']
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# collect
CONTEXT_WORLD.add_command(
  :collect,
  description: 'Collect bonus',
  params: ['<id>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i

  msg = 'Bonus collect'
  GAME.cmdBonusCollect(id)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# goals
CONTEXT_WORLD.add_command(
  :goals,
  description: 'Show goals'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  msg = 'World'
  world = GAME.cmdPlayerWorld(net['profile'].country)
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Goals\e[0m")
  shell.puts(
    format(
      "  \e[35m%-12s %-7s %-8s %-4s %s\e[0m",
      'ID',
      'Credits',
      'Finished',
      'Type',
      'Title'
    )
  )

  world['goals'].each do |id, goal|
    shell.puts(
      format(
        '  %-12d %-7d %-8d %-4d %s',
        id,
        GAME.goalsTypes[goal['type']]['credits'],
        goal['finished'],
        goal['type'],
        GAME.goalsTypes[goal['type']]['name']
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# update
CONTEXT_WORLD.add_command(
  :update,
  description: 'Update goal',
  params: ['<id>', '<record>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i
  record = tokens[2].to_i

  msg = 'Goal update'
  GAME.cmdGoalUpdate(id, record)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# reject
CONTEXT_WORLD.add_command(
  :reject,
  description: 'Reject goal',
  params: ['<id>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i

  msg = 'Goal reject'
  GAME.cmdGoalReject(id)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
