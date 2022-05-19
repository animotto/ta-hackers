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
    shell.puts('Configuration:')
    GAME.config.each do |k, v|
      shell.puts(
        format(
          ' %-16s .. %s',
          k,
          v
        )
      )
    end
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

  shell.puts("Session ID: #{GAME.api.sid}")
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

  shell.puts('Language translations:')
  GAME.language_translations.each do |k|
    shell.puts(
      format(
        ' %-32s .. %s',
        k,
        GAME.language_translations.get(k)
      )
    )
  end
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

  shell.puts("Datetime: #{GAME.app_settings.datetime}")

  shell.puts('Application settings:')
  GAME.app_settings.each do |name|
    shell.puts(
      format(
        ' %-32s .. %s',
        name,
        GAME.app_settings.get(name)
      )
    )
  end
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
    shell.puts("#{node.name}:")
    shell.puts(
      format(
        ' %-5s %-10s %-5s %-7s %-5s %-5s %-5s',
        'Level',
        'Cost',
        'Exp',
        'Upgrade',
        'Conns',
        'Slots',
        'Firewall',
      )
    )

    node.levels.each do |level|
      case node.upgrade_currency(level)
      when Hackers::Network::CURRENCY_MONEY
        upgrade_currency = '$'
      when Hackers::Network::CURRENCY_BITCOINS
        upgrade_currency = "\u20bf"
      end

      shell.puts(
        format(
          ' %-5d %-10s %-5d %-7d %-5d %-5d %-8d',
          level,
          "#{node.upgrade_cost(level)}#{upgrade_currency}",
          node.experience_gained(level),
          node.completion_time(level),
          node.node_connections(level),
          node.program_slots(level),
          node.firewall(level)
        )
      )
    end

    next
  end

  shell.puts('Node types:')
  GAME.node_types.each do |node|
    shell.puts(
      format(
        ' %-2s .. %s',
        node.type,
        node.name
      )
    )
  end
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

    shell.puts("#{program_type.name}:")
    shell.puts(
      format(
        ' %-5s %-8s %-4s %-5s %-7s %-4s %-7s %-8s %-7s',
        'Level',
        'Upgrade',
        'Exp',
        'Price',
        'Compile',
        'Disk',
        'Install',
        'Research',
        'Evolver'
      )
    )

    program_type.levels.each do |level|
      shell.puts(
        format(
          ' %-5d %-8d %-4d %-5d %-7d %-4d %-7.1f %-8s %-7d',
          level,
          program_type.upgrade_cost(level),
          program_type.experience_gained(level),
          program_type.compilation_price(level),
          program_type.compilation_time(level),
          program_type.disk_space(level),
          program_type.install_time(level),
          program_type.research_time(level),
          program_type.required_evolver_level(level)
        )
      )
    end
    next
  end

  shell.puts('Program types:')
  GAME.program_types.each do |program|
    shell.puts(
      format(
        ' %-2s .. %s',
        program.type,
        program.name
      )
    )
  end
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

    shell.puts(format('%-20s %d', 'ID', mission.id))
    shell.puts(format('%-20s %s', 'Group', mission.group))
    shell.puts(format('%-20s %s', 'Name', mission.name))
    shell.puts(format('%-20s %s', 'Giver name', mission.giver_name))
    shell.puts(format('%-20s %s (%d)', 'Country', GAME.countries_list.name(mission.country), mission.country))
    shell.puts(format('%-20s %d, %d', 'Coordinates', mission.x, mission.y))
    shell.puts(format('%-20s %d', 'Reward money', mission.reward_money))
    shell.puts(format('%-20s %d', 'Reward bitcoins', mission.reward_bitcoins))
    shell.puts(format('%-20s %d', 'Additional money', mission.additional_money))
    shell.puts(format('%-20s %d', 'Additional bitcoins', mission.additional_bitcoins))
    shell.puts(format('%-20s %s', 'Required missions', mission.required_missions))
    shell.puts(format('%-20s %d', 'Required core level', mission.required_core_level))
    shell.puts(format('%-20s %s', 'Goals', mission.goals))
    shell.puts(format('%-20s %s', 'Message info', mission.message_info))
    shell.puts(format('%-20s %s', 'Message completion', mission.message_completion))
    shell.puts(format('%-20s %s', 'Message news', mission.message_news))
    next
  end

  shell.puts('Missions list:')
  missions_list.each do |mission|
    shell.puts(
      format(
        ' %-4d %-10s %-13s %s',
        mission.id,
        mission.group,
        mission.giver_name,
        mission.name
      )
    )
  end
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

  shell.puts('Skin types:')
  GAME.skin_types.each do |skin|
    shell.puts(
      format(
        ' %-4d %-5d %-4d %s',
        skin.id,
        skin.price,
        skin.rank,
        skin.name
      )
    )
  end
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

  GAME.hints_list.each do |hint|
    shell.puts(
      format(
        ' %-4d %s',
        hint.id,
        hint.description
      )
    )
  end
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

  shell.puts('Experience list:')
  experience_list.each do |level|
    shell.puts(
      format(
        ' %-3d %d',
        level.level,
        level.experience
      )
    )
  end
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

  shell.puts('Builders list:')
  GAME.builders_list.each do |builder|
    shell.puts(
      format(
        ' %-3d %d',
        builder.amount,
        builder.price
      )
    )
  end
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

  shell.puts('Goal types:')
  shell.puts(
    format(
      ' %-3s %-20s %-6s %-7s %s',
      'ID',
      'Name',
      'Amount',
      'Credits',
      'Description'
    )
  )
  GAME.goal_types.each do |goal|
    shell.puts(
      format(
        ' %-3d %-20s %-6d %-7d %s',
        goal.id,
        goal.name,
        goal.amount,
        goal.credits,
        goal.description
      )
    )
  end
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

  shell.puts('Shield types:')
  GAME.shield_types.each do |shield|
    shell.puts(
      format(
        ' %-3d %-3d %-4d %s',
        shield.id,
        shield.hours,
        shield.price,
        shield.title
      )
    )
  end
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

  shell.puts('Rank list:')
  GAME.rank_list.each do |rank|
    shell.puts(
      format(
        ' %-3d %-14s %-5d %-5d %-7d %-7d',
        rank.id,
        rank.title,
        rank.rank_gain,
        rank.rank_maintain,
        rank.bonus_money,
        rank.bonus_bitcoins
      )
    )
  end
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

  shell.puts('Countries list:')
  GAME.countries_list.each do |country|
    shell.puts(
      format(
        ' %-4d %s',
        country.id,
        country.name
      )
    )
  end
end

# new
SHELL.add_command(
  :new,
  description: 'Create new account'
) do |tokens, shell|
  msg = 'Player create'
  account = GAME.create_player
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 New account\e[0m")
  shell.puts("  ID: #{account.id}")
  shell.puts("  Password: #{account.password}")
  shell.puts("  Session ID: #{account.sid}")
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

  shell.puts("\e[1;35m\u2022 Player info\e[0m")
  shell.puts(format('  %-15s %d', 'ID', profile.id))
  shell.puts(format('  %-15s %s', 'Name', profile.name))
  shell.puts(format("  %-15s \e[33m$ %d\e[0m", 'Money', profile.money))
  shell.puts(format("  %-15s \e[31m\u20bf %d\e[0m", 'Bitcoins', profile.bitcoins))
  shell.puts(format('  %-15s %d', 'Credits', profile.credits))
  shell.puts(format('  %-15s %d', 'Experience', profile.experience))
  shell.puts(format('  %-15s %d', 'Rank', profile.rank))
  shell.puts(format('  %-15s %s', 'Builders', "\e[37m" + "\u25b0" * profile.builders + "\e[0m"))
  shell.puts(format('  %-15s %d', 'X', profile.x))
  shell.puts(format('  %-15s %d', 'Y', profile.y))
  shell.puts(format('  %-15s %s (%d)', 'Country', GAME.countries_list.name(profile.country), profile.country))
  shell.puts(format('  %-15s %d', 'Skin', profile.skin))
  shell.puts(format('  %-15s %d', 'Level', GAME.experience_list.level(profile.experience)))
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

  shell.puts("\e[1;35m\u2022 Detailed player network\e[0m")
  shell.puts(format('  %-15s %d', 'ID', details.profile.id))
  shell.puts(format('  %-15s %s', 'Name', details.profile.name))
  shell.puts(format("  %-15s \e[33m$ %d\e[0m", 'Money', details.profile.money))
  shell.puts(format("  %-15s \e[31m\u20bf %d\e[0m", 'Bitcoins', details.profile.bitcoins))
  shell.puts(format('  %-15s %d', 'Credits', details.profile.credits))
  shell.puts(format('  %-15s %d', 'Experience', details.profile.experience))
  shell.puts(format('  %-15s %d', 'Rank', details.profile.rank))
  shell.puts(format('  %-15s %s', 'Builders', "\e[37m" + "\u25b0" * details.profile.builders + "\e[0m"))
  shell.puts(format('  %-15s %d', 'X', details.profile.x))
  shell.puts(format('  %-15s %d', 'Y', details.profile.y))
  shell.puts(format('  %-15s %s (%d)', 'Country', GAME.countries_list.name(details.profile.country), details.profile.country))
  shell.puts(format('  %-15s %d', 'Skin', details.profile.skin))
  shell.puts(format('  %-15s %d', 'Level', GAME.experience_list.level(details.profile.experience)))

  shell.puts
  shell.puts(
    format(
      "  \e[35m%-12s %-4s %-5s %-12s %-12s\e[0m",
      'ID',
      'Type',
      'Level',
      'Timer',
      'Name'
    )
  )
  details.network.each do |node|
    shell.puts(
      format(
        '  %-12d %-4d %-5d %-12d %-12s',
        node.id,
        node.type,
        node.level,
        node.timer,
        GAME.node_types.get(node.type).name
      )
    )
  end
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

# top
SHELL.add_command(
  :top,
  description: 'Show top ranking'
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

  msg = 'Ranking get all'
  GAME.ranking_list.load
  LOGGER.log(msg)

  ranking_list = GAME.ranking_list

  types = {
    ranking_list.nearby => 'Players nearby',
    ranking_list.country => 'Top country players',
    ranking_list.world => 'Top world players'
  }

  types.each do |list, title|
    shell.puts("\e[1;35m\u2022 #{title}\e[0m")
    shell.puts(
      format(
        "  \e[35m%-12s %-25s %-12s %-7s %-12s\e[0m",
        'ID',
        'Name',
        'Experience',
        'Country',
        'Rank'
      )
    )

    list.each do |player|
      shell.puts(
        format(
          '  %-12s %-25s %-12s %-7s %-12s',
          player.id,
          player.name,
          player.experience,
          player.country,
          player.rank
        )
      )
    end
    shell.puts
  end

  shell.puts("\e[1;35m\u2022 Top countries\e[0m")
  shell.puts(
    format(
      "  \e[35m%-3s %-25s %-12s\e[0m",
      'ID',
      'Country',
      'Rank'
    )
  )

  ranking_list.countries.each do |country|
    shell.puts(
      format(
        '  %-3d %-25s %-12s',
        country.id,
        GAME.countries_list.name(country.id),
        country.rank
      )
    )
  end
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

  shell.puts("\e[1;35m\u2022 Player statistics\e[0m")
  shell.puts("  Rank: #{stats.rank}")
  shell.puts("  Experience: #{stats.experience}")
  shell.puts("  Level: #{GAME.experience_list.level(stats.experience)}")
  shell.puts('  Hacks:')
  shell.puts("   Successful: #{stats.hacks_success}")
  shell.puts("   Failed: #{stats.hacks_fail}")

  win_rate = 0
  hacks_total = stats.hacks_success + stats.hacks_fail
  unless hacks_total.zero?
    win_rate = (stats.hacks_success.to_f / hacks_total * 100).to_i
  end
  shell.puts("   Win rate: #{win_rate}%")

  shell.puts('  Defense:')
  shell.puts("   Successful: #{stats.defense_success}")
  shell.puts("   Failed: #{stats.defense_fail}")

  win_rate = 0
  defense_total = stats.defense_success + stats.defense_fail
  unless defense_total.zero?
    win_rate = (stats.defense_success.to_f / defense_total * 100).to_i
  end
  shell.puts("   Win rate: #{win_rate}%")

  shell.puts('  Looted:')
  shell.puts("   Money: #{stats.loot_money}")
  shell.puts("   Bitcoins: #{stats.loot_bitcoins}")
  shell.puts('  Collected:')
  shell.puts("   Money: #{stats.collect_money}")
  shell.puts("   Bitcoins: #{stats.collect_bitcoins}")
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
