# frozen_string_literal

## Commands

# profile
CONTEXT_NET.add_command(
  :profile,
  description: 'Show profile'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  net = player.net
  profile = player.profile
  skins = player.skins
  shield = player.shield

  builders = 0
  net.each { |node| builders += node.builders if node.timer.negative? }
  shell.puts("\e[1;35m\u2022 Profile\e[0m")
  shell.puts(format('  %-15s %d', 'ID', profile.id))
  shell.puts(format('  %-15s %s', 'Name', profile.name))
  shell.puts(format("  %-15s \e[33m$ %d\e[0m", 'Money', profile.money))
  shell.puts(format("  %-15s \e[31m\u20bf %d\e[0m", 'Bitcoins', profile.bitcoins))
  shell.puts(format('  %-15s %d', 'Credits', profile.credits))
  shell.puts(format('  %-15s %d', 'Experience', profile.experience))
  shell.puts(format('  %-15s %d', 'Rank', profile.rank))
  shell.puts(format('  %-15s %s', 'Builders', "\e[32m" + "\u25b0" * builders + "\e[37m" + "\u25b1" * (profile.builders - builders) + "\e[0m"))
  shell.puts(format('  %-15s %d', 'X', profile.x))
  shell.puts(format('  %-15s %d', 'Y', profile.y))
  shell.puts(format('  %-15s %s (%d)', 'Country', GAME.countries_list.name(profile.country), profile.country))
  shell.puts(format('  %-15s %d', 'Skin', profile.skin))
  shell.puts(format('  %-15s %d', 'Level', GAME.experience_list.level(profile.experience)))
  shell.puts(format('  %-15s %d', 'Tutorial', player.tutorial))

  if shield.installed?
    shell.puts(format('  %-15s %s (%d)', 'Shield', GAME.shield_types.get(player.shield.type).title, shield.time))
  end

  unless skins.empty?
    shell.puts('  Skins:')
    skins.each do |skin|
      shell.puts(format('   %-3d %-15s', skin.type, GAME.skin_types.get(skin.type).name))
    end
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# logs
CONTEXT_NET.add_command(
  :logs,
  description: 'Show logs',
  params: ['[id]']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  logs = player.logs

  unless tokens[1].nil?
    id = tokens[1].to_i
    record = logs.logs.detect { |r| r.id == id }
    if record.nil?
      shell.puts('No such record')
      next
    end

    shell.puts('Logs record:')

    shell.puts(" ID: #{record.id}")
    shell.puts(" Datetime: #{record.datetime}")

    shell.puts(" Attacker ID: #{record.attacker_id}")
    shell.puts(" Attacker name: #{record.attacker_name}")
    shell.puts(" Attacker level: #{record.attacker_level}")
    shell.puts(" Attacker country: #{GAME.countries_list.name(record.attacker_country)} (#{record.attacker_country})")

    shell.puts(" Target ID: #{record.target_id}")
    shell.puts(" Target name: #{record.target_name}")
    shell.puts(" Target level: #{record.target_level}")
    shell.puts(" Target country: #{GAME.countries_list.name(record.target_country)} (#{record.target_country})")

    shell.puts(" Money: #{record.money}")
    shell.puts(" Bitcoins: #{record.bitcoins}")
    shell.puts(" Success: #{record.success}")
    shell.puts(" Rank: #{record.rank}")
    shell.puts(" Test: #{record.test}")

    shell.puts(' Programs:')
    record.programs.each do |program|
      program_type = GAME.program_types.get(program.type)
      shell.puts("  #{program_type.name}: #{program.amount}")
    end

    next
  end

  shell.puts("\e[1;35m\u2022 Security\e[0m")
  if logs.security.empty?
    shell.puts('  Empty')
  else
    shell.puts(
      format(
        "  \e[35m%-7s %-10s %-19s %-10s %-5s %s\e[0m",
        '',
        'ID',
        'Datetime',
        'Attacker',
        'Level',
        'Name'
      )
    )
  end

  logs.security.each do |record|
    shell.puts(
      format(
        "  %s%s%s %+-3d %-10s %-19s %-10s %-5d %s",
        record.success & Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        record.success & Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        record.success & Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        record.rank,
        record.id,
        record.datetime,
        record.attacker_id,
        record.attacker_level,
        record.attacker_name,
      )
    )
  end

  shell.puts
  shell.puts("\e[1;35m\u2022 Hacks\e[0m")
  if logs.hacks.empty?
    shell.puts('  Empty')
  else
    shell.puts(
      format(
        "  \e[35m%-7s %-10s %-19s %-10s %-5s %s\e[0m",
        '',
        'ID',
        'Datetime',
        'Target',
        'Level',
        'Name'
      )
    )
  end

  logs.hacks.each do |record|
    shell.puts(
      format(
        "  %s%s%s %+-3d %-10s %-19s %-10s %-5d %s",
        record.success & Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        record.success & Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        record.success & Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        record.rank,
        record.id,
        record.datetime,
        record.target_id,
        record.target_level,
        record.target_name,
      )
    )
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# readme
CONTEXT_NET.add_command(
  :readme,
  description: 'Show readme'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  readme = GAME.player.readme

  shell.puts("\e[1;35m\u2022 Readme\e[0m")
  readme.each_with_index do |message, i|
    shell.puts("  [#{i}] #{message}")
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# write
CONTEXT_NET.add_command(
  :write,
  description: 'Write message to readme',
  params: ['<message>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  readme = player.readme
  readme.write(tokens[1])

  msg = 'Set readme'
  readme.update
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Readme\e[0m")
  readme.each_with_index do |message, i|
    shell.puts("  [#{i}] #{message}")
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# remove
CONTEXT_NET.add_command(
  :remove,
  description: 'Remove message from readme',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  readme = player.readme

  id = tokens[1].to_i
  unless readme.message?(id)
    shell.puts('No such message ID')
    next
  end

  readme.remove(id)

  msg = 'Set readme'
  readme.update
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Readme\e[0m")
  readme.each_with_index do |message, i|
    shell.puts("  [#{i}] #{message}")
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# clear
CONTEXT_NET.add_command(
  :clear,
  description: 'Clear readme'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  readme = player.readme
  readme.clear

  msg = 'Set readme'
  readme.update
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# nodes
CONTEXT_NET.add_command(
  :nodes,
  description: 'Show nodes'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  profile = player.profile
  net = player.net

  shell.puts("\e[1;35m\u2022 Nodes\e[0m")
  shell.puts(
    format(
      "  \e[35m%-12s %-12s %-4s %-5s %-16s\e[0m",
      'ID',
      'Name',
      'Type',
      'Level',
      'Timer'
    )
  )

  net.each do |node|
    node_type = GAME.node_types.get(node.type)

    timer = String.new
    if node.timer.negative?
      timer += "\e[32m" + "\u25b0" * node.builders + "\e[37m" + "\u25b1" * (profile.builders - node.builders) + "\e[0m "
      timer += Hackers::Utils.timer_dhms(node.timer * -1)
    else
      if node_type.kind_of?(Hackers::NodeTypes::Production)
        case node_type.production_currency(node.level)
        when Hackers::Network::CURRENCY_MONEY
          timer += "\e[33m$ "
        when Hackers::Network::CURRENCY_BITCOINS
          timer += "\e[31m\u20bf "
        end
        produced = (node_type.production_speed(node.level).to_f / 60 / 60 * node.timer).to_i
        timer += produced < node_type.production_limit(node.level) ? produced.to_s : node_type.production_limit(node.level).to_s
        timer += '/' + node_type.production_limit(node.level).to_s
        timer += "\e[0m"
      end
    end

    shell.puts(
      format(
        '  %-12d %-12s %-4d %-5d %-17s',
        node.id,
        node_type.name,
        node.type,
        node.level,
        timer
      )
    )
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# create
CONTEXT_NET.add_command(
  :create,
  description: 'Create node',
  params: ['<type>', '<parent>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  type = tokens[1].to_i
  parent = tokens[2].to_i

  unless GAME.player.loaded?
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  net = GAME.player.net

  unless GAME.node_types.exist?(type)
    shell.puts('No such node type')
    next
  end

  unless net.exist?(parent)
    shell.puts('No such parent node')
    next
  end

  msg = 'Create node'
  net.node(parent).create(type)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# upgrade
CONTEXT_NET.add_command(
  :upgrade,
  description: 'Upgrade node',
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

  net = GAME.player.net

  unless net.exist?(id)
    shell.puts('No such node')
    next
  end

  msg = 'Upgrade node'
  net.node(id).upgrade
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# finish
CONTEXT_NET.add_command(
  :finish,
  description: 'Finish node',
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

  net = GAME.player.net

  unless net.exist?(id)
    shell.puts('No such node')
    next
  end

  msg = 'Finish node'
  net.node(id).finish
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# cancel
CONTEXT_NET.add_command(
  :cancel,
  description: 'Cancel node upgrade',
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

  net = GAME.player.net

  unless net.exist?(id)
    shell.puts('No such node')
    next
  end

  msg = 'Cancel node'
  net.node(id).cancel
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# delete
CONTEXT_NET.add_command(
  :delete,
  description: 'Delete node',
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

  net = GAME.player.net

  unless net.exist?(id)
    shell.puts('No such node')
    next
  end

  msg = 'Delete node'
  net.node(id).delete
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# builders
CONTEXT_NET.add_command(
  :builders,
  description: 'Set node builders',
  params: ['<id>', '<amount>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i
  builders = tokens[2].to_i

  unless GAME.player.loaded?
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  net = GAME.player.net

  unless net.exist?(id)
    shell.puts('No such node')
    next
  end

  msg = 'Node set builders'
  net.node(id).set_builders(builders)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# collect
CONTEXT_NET.add_command(
  :collect,
  description: 'Collect node resources',
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

  net = GAME.player.net

  unless net.exist?(id)
    shell.puts('No such node')
    next
  end

  node = net.node(id)
  unless node.kind_of?(Hackers::Nodes::Production)
    shell.puts('Node is not production')
    next
  end

  msg = 'Collect node'
  node.collect
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# net
CONTEXT_NET.add_command(
  :net,
  description: 'Show network topology'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Network maintenance'
  GAME.player.load
  LOGGER.log(msg)

  player = GAME.player
  net = player.net

  shell.puts("\e[1;35m\u2022 Network topology\e[0m")
  shell.puts(
    format(
    "  \e[35m%-12s %-12s %-5s %-6s %-4s %-4s %-4s %s\e[0m",
      'ID',
      'Name',
      'Type',
      'Level',
      'X',
      'Y',
      'Z',
      'Relations'
    )
  )

  net.each do |node|
    node_type = GAME.node_types.get(node.type)
    relations = node.relations.map { |r| r.id }

    shell.puts(
      format(
        '  %-12d %-12s %-5d %-6d %-+4d %-+4d %-+4d %s',
        node.id,
        node_type.name,
        node.type,
        node.level,
        node.x,
        node.y,
        node.z,
        relations
      )
    )
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

##
# connect
CONTEXT_NET.add_command(
  :connect,
  description: 'Make a connection between nodes',
  params: ['<from_id>', '<to_id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  from_id = tokens[1].to_i
  to_id = tokens[2].to_i

  unless GAME.player.loaded?
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  player = GAME.player
  net = player.net

  unless net.exist?(from_id) && net.exist?(to_id)
    shell.puts('No such nodes')
    next
  end

  net.node(from_id).connect(net.node(to_id))

  msg = 'Network update'
  net.update
  LOGGER.log(msg)
end

##
# diconnect
CONTEXT_NET.add_command(
  :disconnect,
  description: 'Destroy the connection between nodes',
  params: ['<from_id>', '<to_id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  from_id = tokens[1].to_i
  to_id = tokens[2].to_i

  unless GAME.player.loaded?
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  player = GAME.player
  net = player.net

  unless net.exist?(from_id) && net.exist?(to_id)
    shell.puts('No such nodes')
    next
  end

  net.node(from_id).disconnect(net.node(to_id))

  msg = 'Network update'
  net.update
  LOGGER.log(msg)
end
