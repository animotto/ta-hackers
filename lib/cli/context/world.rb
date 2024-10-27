# frozen_string_literal: true

## Commands

# targets
CONTEXT_WORLD.add_command(
  :targets,
  description: 'Show targets'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  unless GAME.player.profile.country
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  msg = 'World'
  GAME.world.load
  LOGGER.log(msg)

  world = GAME.world
  targets = world.targets

  items = []
  targets.each do |target|
    items << [
      target.id,
      GAME.experience_list.level(target.experience),
      "#{GAME.countries_list.name(target.country)} (#{target.country})",
      target.name
    ]
  end

  table = Printer::Table.new(
    'Targets',
    ['ID', 'Level', 'Country', 'Name'],
    items
  )
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# new
CONTEXT_WORLD.add_command(
  :new,
  description: 'Get new targets'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Get new targets'
  GAME.world.targets.new
  LOGGER.log(msg)

  world = GAME.world
  targets = world.targets

  items = []
  targets.each do |target|
    items << [
      target.id,
      GAME.experience_list.level(target.experience),
      "#{GAME.countries_list.name(target.country)} (#{target.country})",
      target.name
    ]
  end

  table = Printer::Table.new(
    'Targets',
    ['ID', 'Level', 'Country', 'Name'],
    items
  )
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# bonuses
CONTEXT_WORLD.add_command(
  :bonuses,
  description: 'Show bonuses'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  unless GAME.player.profile.id
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  msg = 'World'
  GAME.world.load
  LOGGER.log(msg)

  world = GAME.world
  bonuses = world.bonuses

  items = []
  bonuses.each do |bonus|
    items << [
      bonus.id,
      bonus.amount
    ]
  end

  table = Printer::Table.new(
    'Bonuses',
    ['ID', 'Amount'],
    items
  )
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# collect
CONTEXT_WORLD_COLLECT = CONTEXT_WORLD.add_command(
  :collect,
  description: 'Collect bonus',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i

  unless GAME.world.loaded?
    msg = 'World'
    GAME.world.load
    LOGGER.log(msg)
  end

  world = GAME.world
  bonuses = world.bonuses

  unless bonuses.exist?(id)
    shell.puts('No such bonus')
    next
  end

  msg = 'Bonus collect'
  bonuses.get(id).collect
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

CONTEXT_WORLD_COLLECT.completion do |line|
  next unless GAME.world.loaded?

  bonuses = GAME.world.bonuses
  list = bonuses.select { |b| b.id.to_s =~ /^#{Regexp.escape(line)}/  }
  list.map { |b| b.id.to_s }
end

# goals
CONTEXT_WORLD.add_command(
  :goals,
  description: 'Show goals'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  unless GAME.player.profile.id
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  msg = 'World'
  GAME.world.load
  LOGGER.log(msg)

  world = GAME.world
  goals = world.goals

  items = []
  goals.each do |goal|
    goal_type = GAME.goal_types.get(goal.type)
    items << [
      goal.id,
      goal_type.credits,
      goal.finished,
      goal.type,
      goal_type.name
    ]
  end

  table = Printer::Table.new(
    'Goals',
    ['ID', 'Credits', 'Finished', 'Type', 'Name'],
    items
  )
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# update
CONTEXT_WORLD_UPDATE = CONTEXT_WORLD.add_command(
  :update,
  description: 'Update goal',
  params: ['<id>', '<finished>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i
  finished = tokens[2].to_i

  unless GAME.world.loaded?
    msg = 'World'
    GAME.world.load
    LOGGER.log(msg)
  end

  world = GAME.world
  goals = world.goals

  unless goals.exist?(id)
    shell.puts('No such goal')
    next
  end

  msg = 'Goal update'
  goals.get(id).update(finished)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

CONTEXT_WORLD_UPDATE.completion do |line|
  next unless GAME.world.loaded?

  goals = GAME.world.goals
  list = goals.select { |g| g.id.to_s =~ /^#{Regexp.escape(line)}/  }
  list.map { |g| g.id.to_s }
end

# reject
CONTEXT_WORLD_REJECT = CONTEXT_WORLD.add_command(
  :reject,
  description: 'Reject goal',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i

  unless GAME.world.loaded?
    msg = 'World'
    GAME.world.load
    LOGGER.log(msg)
  end

  world = GAME.world
  goals = world.goals

  unless goals.exist?(id)
    shell.puts('No such goal')
    next
  end

  msg = 'Goal reject'
  goals.get(id).reject
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

CONTEXT_WORLD_REJECT.completion do |line|
  next unless GAME.world.loaded?

  goals = GAME.world.goals
  list = goals.select { |g| g.id.to_s =~ /^#{Regexp.escape(line)}/  }
  list.map { |g| g.id.to_s }
end
