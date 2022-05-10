# frozen_string_literal

## Commands

# profile
CONTEXT_NET.add_command(:profile, description: 'Show profile') do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  builders = 0
  net['nodes'].each { |k, v| builders += v['builders'] if v['timer'].negative? }
  shell.puts("\e[1;35m\u2022 Profile\e[0m")
  shell.puts(format('  %-15s %d', 'ID', net['profile'].id))
  shell.puts(format('  %-15s %s', 'Name', net['profile'].name))
  shell.puts(format("  %-15s \e[33m$ %d\e[0m", 'Money', net['profile'].money))
  shell.puts(format("  %-15s \e[31m\u20bf %d\e[0m", 'Bitcoins', net['profile'].bitcoins))
  shell.puts(format('  %-15s %d', 'Credits', net['profile'].credits))
  shell.puts(format('  %-15s %d', 'Experience', net['profile'].experience))
  shell.puts(format('  %-15s %d', 'Rank', net['profile'].rank))
  shell.puts(format('  %-15s %s', 'Builders', "\e[32m" + "\u25b0" * builders + "\e[37m" + "\u25b1" * (net['profile'].builders - builders) + "\e[0m"))
  shell.puts(format('  %-15s %d', 'X', net['profile'].x))
  shell.puts(format('  %-15s %d', 'Y', net['profile'].y))
  shell.puts(format('  %-15s %d', 'Country', net['profile'].country))
  shell.puts(format('  %-15s %d', 'Skin', net['profile'].skin))
  shell.puts(format('  %-15s %d', 'Level', GAME.getLevelByExp(net['profile'].experience)))
  shell.puts(format('  %-15s %d', 'Tutorial', net['tutorial']))
  unless net['shield']['type'].zero?
    shell.puts(format('  %-15s %s (%d)', 'Shield', GAME.shieldTypes[net['shield']['type']]['name'], net['shield']['timer']))
  end
  shell.puts('  Skins:') unless net['skins'].empty?
  net['skins'].each do |skin|
    shell.puts(format('   %-3d %-15s', skin, GAME.skinTypes[skin]['name']))
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# logs
CONTEXT_NET.add_command(:logs, description: 'Show logs') do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Security\e[0m")
  shell.puts(
    format(
      "  \e[35m%-7s %-10s %-19s %-10s %-5s %s\e[0m",
      '',
      'ID',
      'Date',
      'Attacker',
      'Level',
      'Name'
    )
  )
  logs_security = net['logs'].select do |k, v|
    v['target']['id'] == GAME.config['id']
  end
  logs_security = logs_security.to_a.reverse.to_h
  logs_security.each do |k, v|
    shell.puts(
      format(
        "  %s%s%s %+-3d %-10s %-19s %-10s %-5d %s",
        v['success'] & Trickster::Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        v['success'] & Trickster::Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        v['success'] & Trickster::Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        v['rank'],
        k,
        v['date'],
        v['attacker']['id'],
        v['attacker']['level'],
        v['attacker']['name']
      )
    )
  end

  shell.puts
  shell.puts("\e[1;35m\u2022 Hacks\e[0m")
  shell.puts(
    format(
      "  \e[35m%-7s %-10s %-19s %-10s %-5s %s\e[0m",
      '',
      'ID',
      'Date',
      'Target',
      'Level',
      'Name'
    )
  )
  logs_hacks = net['logs'].select do |k, v|
    v['attacker']['id'] == GAME.config['id']
  end
  logs_hacks = logs_hacks.to_a.reverse.to_h
  logs_hacks.each do |k, v|
    shell.puts(
      format(
        "  %s%s%s %+-3d %-10s %-19s %-10s %-5d %s",
        v['success'] & Trickster::Hackers::Game::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        v['success'] & Trickster::Hackers::Game::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        v['success'] & Trickster::Hackers::Game::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
        v['rank'],
        k,
        v['date'],
        v['target']['id'],
        v['target']['level'],
        v['target']['name']
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# readme
CONTEXT_NET.add_command(:readme, description: 'Show readme') do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Readme\e[0m")
  net['readme'].each_with_index do |message, i|
    shell.puts("  [#{i}] #{message}")
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# write
CONTEXT_NET.add_command(
  :write,
  description: 'Write message to readme',
  params: ['<message>']
) do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  msg = 'Set readme'
  net['readme'].write(tokens[1])
  GAME.cmdPlayerSetReadme(net['readme'])
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Readme\e[0m")
  net['readme'].each_with_index do |message, i|
    shell.puts("  [#{i}] #{message}")
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# remove
CONTEXT_NET.add_command(
  :remove,
  description: 'Remove message from readme',
  params: ['<id>']
) do |shell, context, tokens|
  if tokens[1].nil?
    shell.puts('Specify message ID')
    next
  end

  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  id = tokens[1].to_i
  unless net['readme'].id?(id)
    shell.puts('No such message ID')
    next
  end

  msg = 'Set readme'
  net["readme"].remove(id)
  GAME.cmdPlayerSetReadme(net['readme'])
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Readme\e[0m")
  net['readme'].each_with_index do |message, i|
    shell.puts("  [#{i}] #{message}")
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# clear
CONTEXT_NET.add_command(:clear, description: 'Clear readme') do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  msg = 'Set readme'
  net['readme'].clear
  GAME.cmdPlayerSetReadme(net['readme'])
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# nodes
CONTEXT_NET.add_command(:nodes, description: 'Show nodes') do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

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

  production = GAME.nodeTypes.select { |k, v| v['titles'][0] == Trickster::Hackers::Game::PRODUCTION_TITLE }
  net['nodes'].each do |k, v|
    timer = String.new
    if v['timer'].negative?
      timer += "\e[32m" + "\u25b0" * v['builders'] + "\e[37m" + "\u25b1" * (net['profile'].builders - v['builders']) + "\e[0m " unless v['builders'].nil?
      timer += GAME.timerToDHMS(v['timer'] * -1)
    else
      if production.key?(v['type'])
        level = production[v['type']]['levels'][v['level']]
        case level['data'][0]
        when Trickster::Hackers::Game::CURRENCY_MONEY
          timer += "\e[33m$ "
        when Trickster::Hackers::Game::CURRENCY_BITCOINS
          timer += "\e[31m\u20bf "
        end
        produced = (level['data'][2].to_f / 60 / 60 * v['timer']).to_i
        timer += produced < level['data'][1] ? produced.to_s : level['data'][1].to_s
        timer += '/' + level['data'][1].to_s
        timer += "\e[0m"
      end
    end
    shell.puts(
      format(
        '  %-12d %-12s %-4d %-5d %-17s',
        k,
        GAME.nodeTypes[v['type']]['name'],
        v['type'],
        v['level'],
        timer
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# create
CONTEXT_NET.add_command(
  :create,
  description: 'Create node',
  params: ['<type>']
) do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  type = tokens[1].to_i

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  msg = 'Create node'
  GAME.cmdCreateNodeUpdateNet(type, net['net'])
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# upgrade
CONTEXT_NET.add_command(
  :upgrade,
  description: 'Upgrade node',
  params: ['<id>']
) do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i

  msg = 'Upgrade node'
  GAME.cmdUpgradeNode(id)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# finish
CONTEXT_NET.add_command(
  :finish,
  description: 'Finish node',
  params: ['<id>']
) do |shell, context, tokens|
  if GAME.sid.empty?
    SHELL.puts('No session ID')
    next
  end

  id = tokens[1].to_i

  msg = 'Finish node'
  GAME.cmdFinishNode(id)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# cancel
CONTEXT_NET.add_command(
  :cancel,
  description: 'Cancel node upgrade',
  params: ['<id>']
) do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i

  msg = 'Cancel node'
  GAME.cmdNodeCancel(id)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# delete
CONTEXT_NET.add_command(
  :delete,
  description: 'Delete node',
  params: ['<id>']
) do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  msg = 'Delete node'
  GAME.cmdDeleteNodeUpdateNet(id, net['net'])
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# builders
CONTEXT_NET.add_command(
  :builders,
  description: 'Set node builders',
  params: ['<id>', '<amount>']
) do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  id = tokens[1].to_i
  builders = tokens[2].to_i

  msg = 'Node set builders'
  GAME.cmdNodeSetBuilders(id, builders)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# collect
CONTEXT_NET.add_command(
  :collect,
  description: 'Collect node resources',
  params: ['[id]']
) do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  nodes = []
  if tokens[1].nil?
    msg = 'Network maintenance'
    net = GAME.cmdNetGetForMaint
    LOGGER.log(msg)

    nodes = net['nodes'].select { |k, v| (v['type'] == 11 || v['type'] == 13) && v['timer'] >= 0 }.map { |k, v| k }
  else
    nodes << tokens[1].to_i
  end

  msg = 'Collect node'
  nodes.each do |node|
    GAME.cmdCollectNode(node)
    LOGGER.log("#{msg} (#{node})")
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# net
CONTEXT_NET.add_command(:net, description: 'Show network structure') do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Network maintenance'
  net = GAME.cmdNetGetForMaint
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Network structure\e[0m")
  shell.puts(
    format(
    "  \e[35m%-5s %-12s %-12s %-5s %-4s %-4s %-4s %s\e[0m",
      'Index',
      'ID',
      'Name',
      'Type',
      'X',
      'Y',
      'Z',
      'Relations'
    )
  )

  net['net'].each_index do |i|
    id = net['net'][i]['id']
    next unless net['nodes'].key?(id)

    type = net['nodes'][id]['type']
    shell.puts(
      format(
        '  %-5d %-12d %-12s %-5d %-+4d %-+4d %-+4d %s',
        i,
        id,
        GAME.nodeTypes[type]['name'],
        type,
        net['net'][i]['x'],
        net['net'][i]['y'],
        net['net'][i]['z'],
        net['net'][i]['rels']
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
