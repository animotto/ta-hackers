# frozen_string_literal: true

## Contexts

# query
CONTEXT_QUERY = SHELL.add_context(:query, description: 'Analyze queries and data dumps')
# net
CONTEXT_NET = SHELL.add_context(:net, description: 'Network')
# prog
CONTEXT_PROG = SHELL.add_context(:prog, description: 'Programs')
# mission
CONTEXT_MISSION = SHELL.add_context(:mission, description: 'Mission')
# world
CONTEXT_WORLD = SHELL.add_context(:world, description: 'World')
# script
CONTEXT_SCRIPT = SHELL.add_context(:script, description: 'Scripts')
# chat
CONTEXT_CHAT = SHELL.add_context(:chat, description: 'Internal chat')
# market
CONTEXT_MARKET = SHELL.add_context(:market, description: 'Black market')
# top
CONTEXT_TOP = SHELL.add_context(:top, description: 'Top players')

## Commands

# echo
CONTEXT_ROOT_ECHO = SHELL.add_command(
  :echo,
  description: 'Print configuration variables',
  params: ['<var>'],
  global: true
) do |tokens, shell|
  unless GAME.config.key?(tokens[1])
    shell.puts('No such variable')
    next
  end

  shell.puts(GAME.config[tokens[1]])
end

CONTEXT_ROOT_ECHO.completion do |line|
  GAME.config.keys.grep(/^#{Regexp.escape(line)}/)
end

# set
CONTEXT_ROOT_SET = SHELL.add_command(
  :set,
  description: 'Set configuration variables',
  params: ['[var]', '[value]'],
  global: true
) do |tokens, shell|
  if tokens.length < 2
    list = Printer::List.new(
      'Configuartion',
      GAME.config.keys,
      GAME.config.values
    )
    shell.puts(list)
    next
  end

  if tokens.length < 3
    shell.puts('No variable value')
    next
  end

  shell.puts("Variable #{tokens[1]} has been updated")
  if tokens.length == 3
    GAME.config[tokens[1]] = tokens[2]
    next
  end

  GAME.config[tokens[1]] = tokens[2..-1]
end

CONTEXT_ROOT_SET.completion do |line|
  GAME.config.keys.grep(/^#{Regexp.escape(line)}/)
end

# unset
CONTEXT_ROOT_UNSET = SHELL.add_command(
  :unset,
  description: 'Unset configuration variables',
  params: ['<var>'],
  global: true
) do |tokens, shell|
  unless GAME.config.key?(tokens[1])
    shell.puts('No such variable')
    next
  end

  GAME.config.delete(tokens[1])
  shell.puts("Variable #{tokens[1]} has been removed")
end

CONTEXT_ROOT_UNSET.completion do |line|
  GAME.config.keys.grep(/^#{Regexp.escape(line)}/)
end

# save
SHELL.add_command(
  :save,
  description: 'Save configuration'
) do |tokens, shell|
  GAME.config.save
  shell.puts('Configuration has been saved')
end

# connect
SHELL.add_command(
  :connect,
  description: 'Connect to the server'
) do |tokens, shell|
  msg = 'Language translations'
  GAME.language_translations.load
  LOGGER.log(msg)

  msg = 'Application settings'
  GAME.app_settings.load
  LOGGER.log(msg)

  msg = 'Node types'
  GAME.node_types.load
  LOGGER.log(msg)

  msg = 'Program types'
  GAME.program_types.load
  LOGGER.log(msg)

  msg = 'Missions list'
  GAME.missions_list.load
  LOGGER.log(msg)

  msg = 'Skin types'
  GAME.skin_types.load
  LOGGER.log(msg)

  msg = 'Hints list'
  GAME.hints_list.load
  LOGGER.log(msg)

  msg = 'Experience list'
  GAME.experience_list.load
  LOGGER.log(msg)

  msg = 'Builders list'
  GAME.builders_list.load
  LOGGER.log(msg)

  msg = 'Goal types'
  GAME.goal_types.load
  LOGGER.log(msg)

  msg = 'Shield types'
  GAME.shield_types.load
  LOGGER.log(msg)

  msg = 'Rank list'
  GAME.rank_list.load
  LOGGER.log(msg)

  msg = 'Authenticate'
  GAME.auth
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# sid
SHELL.add_command(
  :sid,
  description: 'Show session ID'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  shell.puts(GAME.api.sid)
end

# translations
SHELL.add_command(
  :translations,
  description: 'Language translations'
) do |tokens, shell|
  unless GAME.language_translations.loaded?
    shell.puts('No language translations')
    next
  end

  list = Printer::List.new(
    'Language translations',
    GAME.language_translations.map { |k| k.to_s },
    GAME.language_translations.map { |k| GAME.language_translations.get(k) }
  )
  shell.puts(list)
end

# settings
SHELL.add_command(
  :settings,
  description: 'Application settings'
) do |tokens, shell|
  unless GAME.app_settings.loaded?
    shell.puts('No application settings')
    next
  end

  keys = GAME.app_settings.map { |k| k.to_s }
  values = GAME.app_settings.map { |k| GAME.app_settings.get(k) }
  keys << 'datetime'
  values << GAME.app_settings.datetime

  list = Printer::List.new(
    'Application settings',
    keys,
    values
  )
  shell.puts(list)
end

# nodes
SHELL.add_command(
  :nodes,
  description: 'Node types',
  params: ['[id]']
) do |tokens, shell|
  unless GAME.node_types.loaded?
    shell.puts('No node types')
    next
  end

  unless tokens[1].nil?
    id = tokens[1].to_i
    unless GAME.node_types.exist?(id)
      shell.puts('No such node type')
      next
    end

    node = GAME.node_types.get(id)

    levels = []
    node.levels.each do |level|
      case node.upgrade_currency(level)
      when Hackers::Network::CURRENCY_MONEY
        upgrade_currency = '$'
      when Hackers::Network::CURRENCY_BITCOINS
        upgrade_currency = "\u20bf"
      end

      levels << [
        level,
        "#{node.upgrade_cost(level)}#{upgrade_currency}",
        node.experience_gained(level),
        node.completion_time(level),
        node.node_connections(level),
        node.program_slots(level),
        node.firewall(level)
      ]
    end

    table = Printer::Table.new(
      node.name,
      ['Level', 'Cost', 'Exp', 'Upgrade', 'Conns', 'Slots', 'Firewall'],
      levels
    )
    shell.puts(table)
    next
  end

  table = Printer::Table.new(
    'Node types',
    ['ID', 'Name'],
    GAME.node_types.map { |n| [n.type, n.name] }
  )
  shell.puts(table)
end

# progs
SHELL.add_command(
  :progs,
  description: 'Program types',
  params: ['[id]']
) do |tokens, shell|
  unless GAME.program_types.loaded?
    shell.puts('No program types')
    next
  end

  unless tokens[1].nil?
    id = tokens[1].to_i
    unless GAME.program_types.exist?(id)
      shell.puts('No such program type')
      next
    end

    program_type = GAME.program_types.get(id)

    levels = []
    program_type.levels.each do |level|
      levels << [
        level,
        program_type.upgrade_cost(level),
        program_type.experience_gained(level),
        program_type.compilation_price(level),
        program_type.compilation_time(level),
        program_type.disk_space(level),
        program_type.install_time(level),
        program_type.research_time(level),
        program_type.required_evolver_level(level)
      ]
    end

    table = Printer::Table.new(
      program_type.name,
      ['Level', 'Upgrade', 'Exp', 'Price', 'Compile', 'Disk', 'Install', 'Research', 'Evolver'],
      levels
    )
    shell.puts(table)
    next
  end

  table = Printer::Table.new(
    'Program types',
    ['ID', 'Name'],
    GAME.program_types.map { |p| [p.type, p.name] }
  )
  shell.puts(table)
end

# missions
SHELL.add_command(
  :missions,
  description: 'Missions list',
  params: ['[id]']
) do |tokens, shell|
  unless GAME.missions_list.loaded?
    shell.puts('No missions list')
    next
  end

  missions_list = GAME.missions_list

  unless tokens[1].nil?
    id = tokens[1].to_i
    unless missions_list.exist?(id)
      shell.puts('No such mission')
      next
    end

    mission = missions_list.get(id)

    list = Printer::List.new(
      'Mission',
      [
        'ID',
        'Group',
        'Name',
        'Giver name',
        'Country',
        'Coordinates',
        'Reward money',
        'Reward bitcoins',
        'Additional money',
        'Additional bitcoins',
        'Required missions',
        'Required core level',
        'Goals',
        'Message info',
        'Message completion',
        'Message news'
      ],
      [
        mission.id,
        mission.group,
        mission.name,
        mission.giver_name,
        "#{GAME.countries_list.name(mission.country)} (#{mission.country})",
        "#{mission.x}, #{mission.y}",
        mission.reward_money,
        mission.reward_bitcoins,
        mission.additional_money,
        mission.additional_bitcoins,
        mission.required_missions,
        mission.required_core_level,
        mission.goals,
        mission.message_info,
        mission.message_completion,
        mission.message_news
      ]
    )
    shell.puts(list)
    next
  end

  table = Printer::Table.new(
    'Missions list',
    ['ID', 'Group', 'Giver name', 'Name'],
    missions_list.map { |m| [m.id, m.group, m.giver_name, m.name] }
  )
  shell.puts(table)
end

# skins
SHELL.add_command(
  :skins,
  description: 'Skin types'
) do |tokens, shell|
  unless GAME.skin_types.loaded?
    shell.puts('No skin types')
    next
  end

  list = Printer::Table.new(
    'Skin types',
    ['ID', 'Price', 'Rank', 'Name'],
    GAME.skin_types.map { |s| [s.id, s.price, s.rank, s.name] }
  )
  shell.puts(list)
end

# news
SHELL.add_command(
  :news,
  description: 'News'
) do |tokens, shell|
  msg = 'News'
  GAME.news_list.load
  LOGGER.log(msg)

  GAME.news_list.each do |news|
    shell.puts(
      format(
        "\e[34m%s \e[33m%s\e[0m",
        news.datetime,
        news.title
      )
    )
    shell.puts(
      format(
        "\e[35m%s\e[0m",
        news.body
      )
    )
    shell.puts
  end
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# hints
SHELL.add_command(
  :hints,
  description: 'Hints list'
) do |tokens, shell|
  unless GAME.hints_list.loaded?
    shell.puts('No hints list')
    next
  end

  list = Printer::List.new(
    'Hints',
    GAME.hints_list.map { |h| h.id.to_s },
    GAME.hints_list.map { |h| h.description }
  )
  shell.puts(list)
end

# experience
SHELL.add_command(
  :experience,
  description: 'Experience list',
  params: ['[experience]']
) do |tokens, shell|
  unless GAME.experience_list.loaded?
    shell.puts('No experience list')
    next
  end

  experience_list = GAME.experience_list

  unless tokens[1].nil?
    experience = tokens[1].to_i
    shell.puts("Level: #{experience_list.level(experience)}")

    next
  end

  list = Printer::List.new(
    'Experience list',
    experience_list.map { |e| e.level.to_s },
    experience_list.map { |e| e.experience.to_s }
  )
  shell.puts(list)
end

# builders
SHELL.add_command(
  :builders,
  description: 'Builders list'
) do |tokens, shell|
  unless GAME.builders_list.loaded?
    shell.puts('No builders list')
    next
  end

  table = Printer::Table.new(
    'Builders',
    ['Amount', 'Price'],
    GAME.builders_list.map { |b| [b.amount, b.price] }
  )
  shell.puts(table)
end

# goals
SHELL.add_command(
  :goals,
  description: 'Goals types'
) do |tokens, shell|
  unless GAME.goal_types.loaded?
    shell.puts('No goals types')
    next
  end

  table = Printer::Table.new(
    'Goal types',
    ['ID', 'Name', 'Amount', 'Credits', 'Description'],
    GAME.goal_types.map { |g| [g.id, g.name, g.amount, g.credits, g.description] }
  )
  shell.puts(table)
end

# shields
SHELL.add_command(
  :shields,
  description: 'Shield types'
) do |tokens, shell|
  unless GAME.shield_types.loaded?
    shell.puts('No shield types')
    next
  end

  table = Printer::Table.new(
    'Shield types',
    ['ID', 'Hours', 'Price', 'Title'],
    GAME.shield_types.map { |s| [s.id, s.hours, s.price, s.title] }
  )
  shell.puts(table)
end

# ranks
SHELL.add_command(
  :ranks,
  description: 'Rank list'
) do |tokens, shell|
  unless GAME.rank_list.loaded?
    shell.puts('No rank list')
    next
  end

  table = Printer::Table.new(
    'Rank list',
    ['ID', 'Title', 'Gain', 'Maintain', 'Money', 'Bitcoins'],
    GAME.rank_list.map { |r| [r.id, r.title, r.rank_gain, r.rank_maintain, r.bonus_money, r.bonus_bitcoins] }
  )
  shell.puts(table)
end

# countries
SHELL.add_command(
  :countries,
  description: 'Contries list'
) do |tokens, shell|
  unless GAME.countries_list.loaded?
    shell.puts('No countries list')
    next
  end

  list = Printer::List.new(
    'Countries list',
    GAME.countries_list.map { |c| c.id.to_s },
    GAME.countries_list.map { |c| c.name }
  )
  shell.puts(list)
end

# new
SHELL.add_command(
  :new,
  description: 'Create new account'
) do |tokens, shell|
  msg = 'Player create'
  account = GAME.create_player
  LOGGER.log(msg)

  list = Printer::List.new(
    'New account',
    ['ID', 'Password', 'Session ID'],
    [account.id, account.password, account.sid]
  )
  shell.puts(list)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# rename
SHELL.add_command(
  :rename,
  description: 'Set new name',
  params: ['<name>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Player set name'
  GAME.player.rename(tokens[1])
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# info
SHELL.add_command(
  :info,
  description:'Get player info',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i

  msg = 'Player get info'
  profile = GAME.player_info(id)
  LOGGER.log(msg)

  profile = Printer::Profile.new(profile, GAME)
  shell.puts(profile)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# details
SHELL.add_command(
  :details,
  description: "Get detailed info about player's network",
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i

  msg = 'Get net details world'
  details = GAME.player_details(id)
  LOGGER.log(msg)

  profile = Printer::Profile.new(details.profile, GAME)
  shell.puts(profile)
  shell.puts

  table = Printer::Table.new(
    'Nodes',
    ['ID', 'Type', 'Level', 'Timer', 'Name'],
    details.network.map do |n|
      [
        n.id,
        n.type,
        n.level,
        n.timer,
        GAME.node_types.get(n.type).name
      ]
    end
  )
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# hq
SHELL.add_command(
  :hq,
  description: 'Set player HQ',
  params: ['<x>', '<y>', '<country>']
) do |tokens, shell|
  x = tokens[1].to_i
  y = tokens[2].to_i
  country = tokens[3].to_i

  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Set player HQ'
  GAME.player.set_hq(x, y, country)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# skin
SHELL.add_command(
  :skin,
  description: 'Set player skin',
  params: ['<skin>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  skin = tokens[1].to_i

  msg = 'Player set skin'
  GAME.player.set_skin(skin)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# tutorial
SHELL.add_command(
  :tutorial,
  description: 'Set tutorial',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  tutorial = tokens[1].to_i

  msg = 'Player set tutorial'
  GAME.player.set_tutorial(tutorial)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# email
SHELL.add_command(
  :email,
  description: 'Email subscribe',
  params: ['<email>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Email subscribe'
  GAME.player.subscribe_email(tokens[1])
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# cpgen
SHELL.add_command(
  :cpgen,
  description: 'Generate code for platform change'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Cp generate code'
  code = GAME.cp_generate_code
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Generated code\e[0m")
  shell.puts("  Code: #{code}")
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# cpuse
SHELL.add_command(
  :cpuse,
  description: 'Use code for platform change',
  params: ['<code>', '<platform>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Cp use code'
  account = GAME.cp_use_code(tokens[1], tokens[2])
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Account credentials\e[0m")
  shell.puts("  ID: #{account.id}")
  shell.puts("  Password: #{account.password}")
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# stats
SHELL.add_command(
  :stats,
  description: 'Show player statistics'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Player stats'
  GAME.player.stats.load
  LOGGER.log(msg)

  stats = GAME.player.stats
  hacks_winrate = 0
  hacks_total = stats.hacks_success + stats.hacks_fail
  win_rate = (stats.hacks_success.to_f / hacks_total * 100).to_i unless hacks_total.zero?
  defense_winrate = 0
  defense_total = stats.defense_success + stats.defense_fail
  defense_winrate = (stats.defense_success.to_f / defense_total * 100).to_i unless defense_total.zero?

  data = {
    rank: stats.rank,
    experience: stats.experience,
    level: GAME.experience_list.level(stats.experience),
    hacks_success: stats.hacks_success,
    hacks_fail: stats.hacks_fail,
    hacks_winrate: "#{hacks_winrate}%",
    defense_success: stats.defense_success,
    defense_fail: stats.defense_fail,
    defense_winrate: "#{defense_winrate}%",
    looted_money: stats.loot_money,
    looted_bitcoins: stats.loot_bitcoins,
    collected_money: stats.collect_money,
    collected_bitcoins: stats.collect_bitcoins
  }

  list = Printer::Stats.new(data)
  shell.puts(list)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
