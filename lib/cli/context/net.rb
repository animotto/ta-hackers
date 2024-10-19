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
  node_types = GAME.node_types

  capacity_money = 0
  capacity_bitcoins = 0
  net.each do |node|
    node_type = node_types.get(node.type)
    if node_type.instance_of?(Hackers::NodeTypes::Core)
      capacity_money += node_type.capacity_money(node.level)
      capacity_bitcoins += node_type.capacity_bitcoins(node.level)
    elsif node_type.kind_of?(Hackers::NodeTypes::Database)
      capacity_money += node_type.capacity(node.level)
    elsif node_type.kind_of?(Hackers::NodeTypes::BitcoinMixer)
      capacity_bitcoins += node_type.capacity(node.level)
    end
  end

  builders = 0
  net.each { |node| builders += node.builders if node.timer.negative? }

  list_profile = Printer::Profile.new(profile, GAME)
  list_profile.tutorial = player.tutorial
  list_profile.capacity_money = capacity_money
  list_profile.capacity_bitcoins = capacity_bitcoins
  list_profile.builders_busy = builders
  list_profile.shield = player.shield
  shell.puts(list_profile)

  unless skins.empty?
    list_skins = Printer::List.new(
      'Skins',
      skins.map { |s| s.type.to_s },
      skins.map { |s| GAME.skin_types.get(s.type).name }
    )
    shell.puts
    shell.puts(list_skins)
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

    list_record = Printer::List.new(
      'Logs record',
      [
        'ID',
        'Datetime',
        'Attacker ID',
        'Attacker name',
        'Attacker level',
        'Attacker country',
        'Target ID',
        'Target name',
        'Target level',
        'Target country',
        'Money',
        'Bitcoins',
        'Success',
        'Rank',
        'Test'
      ],
      [
        record.id,
        record.datetime,
        record.attacker_id,
        record.attacker_name,
        record.attacker_level,
        "#{GAME.countries_list.name(record.attacker_country)} (#{record.attacker_country})",
        record.target_id,
        record.target_name,
        record.target_level,
        "#{GAME.countries_list.name(record.target_country)} (#{record.target_country})",
        record.money,
        record.bitcoins,
        record.success,
        Kernel.format('%+d', record.rank),
        record.test
      ]
    )
    shell.puts(list_record)
    shell.puts

    table_programs = Printer::Table.new(
      'Programs',
      ['Type', 'Name', 'Amount'],
      record.programs.map do |p|
        [
          p.type,
          GAME.program_types.get(p.type).name,
          p.amount
        ]
      end
    )
    shell.puts(table_programs)

    next
  end

  table_security = Printer::LogsSecurity.new(logs.security)
  shell.puts(table_security)
  shell.puts
  table_hacks = Printer::LogsHacks.new(logs.hacks)
  shell.puts(table_hacks)
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

  list = Printer::List.new(
    'Readme',
    readme.each_with_index.map { |_, i| i.to_s },
    readme.each.map { |m| m }
  )
  shell.puts(list)
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

  list = Printer::List.new(
    'Readme',
    readme.each_with_index.map { |_, i| i.to_s },
    readme.each.map { |m| m }
  )
  shell.puts(list)
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

  list = Printer::List.new(
    'Readme',
    readme.each_with_index.map { |_, i| i.to_s },
    readme.each.map { |m| m }
  )
  shell.puts(list)
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

  nodes = []
  net.each do |node|
    node_type = GAME.node_types.get(node.type)

    timer = String.new
    if node.timer.negative?
      builders_busy = Array.new(node.builders, "\e[32m\u25b0")
      builders_free = Array.new(profile.builders - node.builders, "\e[37m\u25b1")
      timer += (builders_busy + builders_free).join(' ') + "\e[0m "
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

    upgrade_currency = ''
    upgrade_cost = '-'
    upgrade_level = node.level + 1
    if upgrade_level <= node_type.levels.length
      case node_type.upgrade_currency(upgrade_level)
      when Hackers::Network::CURRENCY_MONEY
        upgrade_currency = '$'
      when Hackers::Network::CURRENCY_BITCOINS
        upgrade_currency = "\u20bf"
      end

      upgrade_cost = node_type.upgrade_cost(upgrade_level)
    end

    nodes << [
      node.id,
      node_type.name,
      node.type,
      node.level,
      "#{upgrade_cost}#{upgrade_currency}",
      timer
    ]
  end

  table = Printer::Table.new(
    'Nodes',
    ['ID', 'Name', 'Type', 'Level', 'Upgrade', 'Timer'],
    nodes
  )
  shell.puts(table)
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
  params: ['[id]']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  unless GAME.player.loaded?
    msg = 'Network maintenance'
    GAME.player.load
    LOGGER.log(msg)
  end

  net = GAME.player.net

  if tokens[1].nil?
    net.each do |node|
      next unless node.kind_of?(Hackers::Nodes::Production) && node.timer.positive?

      msg = 'Collect node'
      node.collect
      LOGGER.log(msg)
    end

    next
  end

  id = tokens[1].to_i
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

  table = Printer::Network.new(player.net, GAME)
  shell.puts(table)
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
