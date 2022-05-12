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
# buy
CONTEXT_BUY = SHELL.add_context(:buy, description: 'The buys')

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
  GAME.transLang = GAME.cmdTransLang
  LOGGER.log(msg)

  msg = 'Application settings'
  GAME.appSettings = GAME.cmdAppSettings
  LOGGER.log(msg)

  msg = 'Node types and levels'
  GAME.nodeTypes = GAME.cmdGetNodeTypes
  LOGGER.log(msg)

  msg = 'Program types and levels'
  GAME.programTypes = GAME.cmdGetProgramTypes
  LOGGER.log(msg)

  msg = 'Missions list'
  GAME.missionsList = GAME.cmdGetMissionsList
  LOGGER.log(msg)

  msg = 'Skin types'
  GAME.skinTypes = GAME.cmdSkinTypesGetList
  LOGGER.log(msg)

  msg = 'Hints list'
  GAME.hintsList = GAME.cmdHintsGetList
  LOGGER.log(msg)

  msg = 'Experience list'
  GAME.experienceList = GAME.cmdGetExperienceList
  LOGGER.log(msg)

  msg = 'Builders list'
  GAME.buildersList = GAME.cmdBuildersCountGetList
  LOGGER.log(msg)

  msg = 'Goals types'
  GAME.goalsTypes = GAME.cmdGoalTypesGetList
  LOGGER.log(msg)

  msg = 'Shield types'
  GAME.shieldTypes = GAME.cmdShieldTypesGetList
  LOGGER.log(msg)

  msg = 'Rank list'
  GAME.rankList = GAME.cmdRankGetList
  LOGGER.log(msg)

  msg = 'Authenticate'
  auth = GAME.cmdAuthIdPassword
  LOGGER.log(msg)
  GAME.sid = auth['sid']
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# sid
SHELL.add_command(
  :sid,
  description: 'Show session ID'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  shell.puts("SID: #{GAME.sid}")
end

# trans
SHELL.add_command(
  :trans,
  description: 'Language translations'
) do |tokens, shell|
  if GAME.transLang.empty?
    shell.puts('No language translations')
    next
  end

  shell.puts('Language translations:')
  GAME.transLang.each do |k, v|
    shell.puts(
      format(
        ' %-32s .. %s',
        k,
        v
      )
    )
  end
end

# settings
SHELL.add_command(
  :settings,
  description: 'Application settings'
) do |tokens, shell|
  if GAME.appSettings.empty?
    shell.puts('No application settings')
    next
  end

  shell.puts('Application settings:')
  GAME.appSettings.each do |k, v|
    shell.puts(
      format(
        ' %-32s .. %s',
        k,
        v
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
  if GAME.nodeTypes.empty?
    shell.puts('No node types')
    next
  end

  unless tokens[1].nil?
    id = tokens[1].to_i
    unless GAME.nodeTypes.key?(id)
      shell.puts('No such node type')
      next
    end

    shell.puts("#{GAME.nodeTypes[id]['name']}:")
    shell.puts(
      format(
        ' %-5s %-10s %-4s %-5s %-7s %-5s %-5s %-5s %-5s',
        'Level',
        'Cost',
        'Core',
        'Exp',
        'Upgrade',
        'Conns',
        'Slots',
        'Firewall',
        'Limit'
      )
    )
    GAME.nodeTypes[id]['levels'].each do |k, v|
      limit = GAME.nodeTypes[id]['limits'].dig(k)
      if limit.nil?
        limits = GAME.nodeTypes[id]['limits'].sort_by {|k, v| v}
        limit = limits.dig(-1, 1) || '-'
      end
      shell.puts(
        format(
          ' %-5d %-10d %-4d %-5d %-7d %-5d %-5d %-8d %-5s',
          k,
          v['cost'],
          v['core'],
          v['experience'],
          v['upgrade'],
          v['connections'],
          v['slots'],
          v['firewall'],
          limit
        )
      )
    end
    next
  end

  shell.puts('Node types:')
  GAME.nodeTypes.each do |k, v|
    shell.puts(
      format(
        ' %-2s .. %s',
        k,
        v["name"]
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
  if GAME.programTypes.empty?
    shell.puts('No program types')
    next
  end

  unless tokens[1].nil?
    id = tokens[1].to_i
    unless GAME.programTypes.key?(id)
      shell.puts('No such program type')
      next
    end

    shell.puts("#{GAME.programTypes[id]["name"]}:")
    shell.puts(
      format(
        ' %-5s %-6s %-4s %-5s %-7s %-4s %-7s %-7s %-4s %-8s %-7s',
        'Level',
        'Cost',
        'Exp',
        'Price',
        'Compile',
        'Disk',
        'Install',
        'Upgrade',
        'Rate',
        'Strength',
        'Evolver'
      )
    )
    GAME.programTypes[id]['levels'].each do |k, v|
      shell.puts(
        format(
          ' %-5d %-6d %-4d %-5d %-7d %-4d %-7d %-7d %-4d %-8d %-7d',
          k,
          v['cost'],
          v['experience'],
          v['price'],
          v['compile'],
          v['disk'],
          v['install'],
          v['upgrade'],
          v['rate'],
          v['strength'],
          v['evolver']
        )
      )
    end
    next
  end

  shell.puts('Program types:')
  GAME.programTypes.each do |k, v|
    shell.puts(
      format(
        ' %-2s .. %s',
        k,
        v["name"]
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
  if GAME.missionsList.empty?
    shell.puts('No missions list')
    next
  end

  unless tokens[1].nil?
    id = tokens[1].to_i
    unless GAME.missionsList.key?(id)
      shell.puts('No such mission')
      next
    end

    shell.puts(format('%-20s %d', 'ID', id))
    shell.puts(format('%-20s %s', 'Group', GAME.missionsList[id]['group']))
    shell.puts(format('%-20s %s', 'Name', GAME.missionsList[id]['name']))
    shell.puts(format('%-20s %s', 'Target', GAME.missionsList[id]['target']))
    shell.puts(format('%-20s %d, %d', 'Coordinates', GAME.missionsList[id]['x'], GAME.missionsList[id]['y']))
    shell.puts(format('%-20s %d (%s)', 'Country', GAME.missionsList[id]['country'], GAME.getCountryNameByID(GAME.missionsList[id]['country'])))
    shell.puts(format('%-20s %d', 'Money', GAME.missionsList[id]['money']))
    shell.puts(format('%-20s %d', 'Bitcoins', GAME.missionsList[id]['bitcoins']))
    shell.puts(format('Requirements'))
    shell.puts(format(' %-20s %s', 'Mission', GAME.missionsList[id]['requirements']['mission']))
    shell.puts(format(' %-20s %d', 'Core', GAME.missionsList[id]['requirements']['core']))
    shell.puts(format('%-20s %s', 'Goals', GAME.missionsList[id]['goals'].join(', ')))
    shell.puts(format('Reward'))
    shell.puts(format(' %-20s %d', 'Money', GAME.missionsList[id]['reward']['money']))
    shell.puts(format(' %-20s %d', 'Bitcoins', GAME.missionsList[id]['reward']['bitcoins']))
    shell.puts(format('Messages'))
    shell.puts(format(' %-20s %s', 'Begin', GAME.missionsList[id]['messages']['begin']))
    shell.puts(format(' %-20s %s', 'End', GAME.missionsList[id]['messages']['end']))
    shell.puts(format(' %-20s %s', 'News', GAME.missionsList[id]['messages']['news']))
    next
  end

  shell.puts('Missions list:')
  GAME.missionsList.each do |k, v|
    shell.puts(
      format(
        ' %-4d .. %-15s %-15s %s',
        k,
        v['group'],
        v['name'],
        v['target']
      )
    )
  end
end

# skins
SHELL.add_command(
  :skins,
  description: 'Skin types'
) do |tokens, shell|
  if GAME.skinTypes.empty?
    shell.puts('No skin types')
    next
  end

  shell.puts('Skin types:')
  GAME.skinTypes.each do |k, v|
    shell.puts(
      format(
        ' %-7d .. %s, %d, %d',
        k,
        v['name'],
        v['price'],
        v['rank']
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
  news = GAME.cmdNewsGetList
  LOGGER.log(msg)

  news.each do |k, v|
    shell.puts(
      format(
        "\e[34m%s \e[33m%s\e[0m",
        v['date'],
        v['title']
      )
    )
    shell.puts(
      format(
        "\e[35m%s\e[0m",
        v['body']
      )
    )
    shell.puts
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# hints
SHELL.add_command(
  :hints,
  description: 'Hints list'
) do |tokens, shell|
  if GAME.hintsList.empty?
    shell.puts('No hints list')
    next
  end

  GAME.hintsList.each do |k, v|
    shell.puts(
      format(
        ' %-7d .. %s',
        k,
        v['description']
      )
    )
  end
end

# experience
SHELL.add_command(
  :experience,
  description: 'Experience list'
) do |tokens, shell|
  if GAME.experienceList.empty?
    shell.puts('No experience list')
    next
  end

  GAME.experienceList.each do |k, v|
    shell.puts(
      format(
        ' %-7d .. %s',
        k,
        v['experience']
      )
    )
  end
end

# builders
SHELL.add_command(
  :builders,
  description: 'Builders list'
) do |tokens, shell|
  if GAME.buildersList.empty?
    shell.puts('No builders list')
    next
  end

  GAME.buildersList.each do |k, v|
    shell.puts(
      format(
        '%-7d .. %s',
        k,
        v['price']
      )
    )
  end
end

# goals
SHELL.add_command(
  :goals,
  description: 'Goals types'
) do |tokens, shell|
  if GAME.goalsTypes.empty?
    shell.puts('No goals types')
    next
  end

  shell.puts(
    format(
      ' %-4s %-20s %-6s %-7s %s',
      'Type',
      'Name',
      'Amount',
      'Credits',
      'Title'
    )
  )
  GAME.goalsTypes.each do |type, goal|
    shell.puts(
      format(
        ' %-4d %-20s %-6d %-7d %s',
        type,
        goal['name'],
        goal['amount'],
        goal['credits'],
        goal['title']
      )
    )
  end
end

# shields
SHELL.add_command(
  :shields,
  description: 'Shield types'
) do |tokens, shell|
  if GAME.shieldTypes.empty?
    shell.puts('No shield types')
    next
  end

  GAME.shieldTypes.each do |k, v|
    shell.puts(
      format(
        ' %-7d .. %d, %s, %s',
        k,
        v['price'],
        v['name'],
        v['description']
      )
    )
  end
end

# ranks
SHELL.add_command(
  :ranks,
  description: 'Rank list'
) do |tokens, shell|
  if GAME.rankList.empty?
    shell.puts('No rank list')
    next
  end

  GAME.rankList.each do |k, v|
    shell.puts(
      format(
        ' %-7d .. %d',
        k,
        v['rank']
      )
    )
  end
end

# countries
SHELL.add_command(
  :countries,
  description: 'Contries list'
) do |tokens, shell|
  if GAME.countriesList.empty?
    shell.puts('No countries list')
    next
  end

  GAME.countriesList.each do |k, v|
    shell.puts(
      format(
        ' %-3d .. %s',
        k,
        v
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
  player = GAME.cmdPlayerCreate
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 New account\e[0m")
  shell.puts("  ID: #{player['id']}")
  shell.puts("  Password: #{player['password']}")
  shell.puts("  Session ID: #{player['sid']}")
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# rename
SHELL.add_command(
  :rename,
  description: 'Set new name',
  params: ['<name>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Player set name'
  GAME.cmdPlayerSetName(GAME.config['id'], tokens[1])
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# info
SHELL.add_command(
  :info,
  description:'Get player info',
  params: ['<id>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Player get info'
  profile = GAME.cmdPlayerGetInfo(tokens[1].to_i)
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
  shell.puts(format('  %-15s %d', 'Country', profile.country))
  shell.puts(format('  %-15s %d', 'Skin', profile.skin))
  shell.puts(format('  %-15s %d', 'Level', GAME.getLevelByExp(profile.experience)))
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# detail
SHELL.add_command(
  :detail,
  description: "Get detailed info about player's network",
  params: ['<id>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Get net details world'
  detail = GAME.cmdGetNetDetailsWorld(tokens[1].to_i)
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Detailed player network\e[0m")
  shell.puts(format('  %-15s %d', 'ID', detail['profile'].id))
  shell.puts(format('  %-15s %s', 'Name', detail['profile'].name))
  shell.puts(format("  %-15s \e[33m$ %d\e[0m", 'Money', detail['profile'].money))
  shell.puts(format("  %-15s \e[31m\u20bf %d\e[0m", 'Bitcoins', detail['profile'].bitcoins))
  shell.puts(format('  %-15s %d', 'Credits', detail['profile'].credits))
  shell.puts(format('  %-15s %d', 'Experience', detail['profile'].experience))
  shell.puts(format('  %-15s %d', 'Rank', detail['profile'].rank))
  shell.puts(format('  %-15s %s', 'Builders', "\e[37m" + "\u25b0" * detail['profile'].builders + "\e[0m"))
  shell.puts(format('  %-15s %d', 'X', detail['profile'].x))
  shell.puts(format('  %-15s %d', 'Y', detail['profile'].y))
  shell.puts(format('  %-15s %d', 'Country', detail['profile'].country))
  shell.puts(format('  %-15s %d', 'Skin', detail['profile'].skin))
  shell.puts(format('  %-15s %d', 'Level', GAME.getLevelByExp(detail['profile'].experience)))

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
  detail['nodes'].each do |k, v|
    shell.puts(
      format(
        '  %-12d %-4d %-5d %-12d %-12s',
        k,
        v['type'],
        v['level'],
        v['timer'],
        GAME.nodeTypes[v['type']]['name']
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
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

  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Set player HQ'
  GAME.cmdSetPlayerHqCountry(GAME.config['id'], x, y, country)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# skin
SHELL.add_command(
  :skin,
  description: 'Set player skin',
  params: ['<skin>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Player set skin'
  GAME.cmdPlayerSetSkin(tokens[1].to_i)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# tutorial
SHELL.add_command(
  :tutorial,
  description: 'Set tutorial',
  params: ['<id>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Player set tutorial'
  GAME.cmdPlayerSetTutorial(tokens[1].to_i)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# email
SHELL.add_command(
  :email,
  description: 'Email subscribe',
  params: ['<email>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Email subscribe'
  GAME.cmdEmailSubscribe(tokens[1])
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# top
SHELL.add_command(
  :top,
  description: 'Show top ranking',
  params: ['<id>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Ranking get all'
  top = GAME.cmdRankingGetAll(tokens[1].to_i)
  LOGGER.log(msg)

  types = {
    'nearby' => 'Players nearby',
    'country' => 'Top country players',
    'world' => 'Top world players'
  }

  types.each do |type, title|
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
    top[type].each do |player|
      shell.puts(
        format(
          '  %-12s %-25s %-12s %-7s %-12s',
          player['id'],
          player['name'],
          player['experience'],
          player['country'],
          player['rank']
        )
      )
    end
    shell.puts
  end

  shell.puts("\e[1;35m\u2022 Top countries\e[0m")
  shell.puts(
    format(
      "  \e[35m%-7s %-12s\e[0m",
      'Country',
      'Rank'
    )
  )
  top['countries'].each do |player|
    shell.puts(
      format(
        '  %-7s %-12s',
        player['country'],
        player['rank']
      )
    )
  end
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# cpgen
SHELL.add_command(
  :cpgen,
  description: 'Cp generate code'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Cp generate code'
  code = GAME.cmdCpGenerateCode(GAME.config['id'], GAME.config['platform'])
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Generated code\e[0m")
  shell.puts("  Code: #{code}")
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# cpuse
SHELL.add_command(
  :cpuse,
  description: 'Cp use code',
  params: ['<code>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Cp use code'
  data = GAME.cmdCpUseCode(GAME.config['id'], tokens[1], GAME.config['platform'])
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Account credentials\e[0m")
  shell.puts("  ID: #{data["id"]}")
  shell.puts("  Password: #{data["password"]}")
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# stats
SHELL.add_command(
  :stats,
  description: 'Show player statistics'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Player stats'
  stats = GAME.cmdPlayerGetStats
  LOGGER.log(msg)

  shell.puts("\e[1;35m\u2022 Player statistics\e[0m")
  shell.puts("  Rank: #{stats['rank']}")
  shell.puts("  Experience: #{stats['experience']}")
  shell.puts("  Level: #{GAME.getLevelByExp(stats['experience'])}")
  shell.puts('  Hacks:')
  shell.puts("   Successful: #{stats['hacks']['success']}")
  shell.puts("   Failed: #{stats['hacks']['fail']}")

  if stats['hacks']['success'].zero? && stats['hacks']['fail'].zero?
    win_rate = 0
  else
    win_rate = (stats['hacks']['success'].to_f / (stats['hacks']['success'] + stats['hacks']['fail']) * 100).to_i
  end
  shell.puts("   Win rate: #{win_rate}%")

  shell.puts('  Defenses:')
  shell.puts("   Successful: #{stats['defense']['success']}")
  shell.puts("   Failed: #{stats['defense']['fail']}")

  if stats['defense']['success'].zero? && stats['defense']['fail'].zero?
    win_rate = 0
  else
    win_rate = (stats['defense']['success'].to_f / (stats['defense']['success'] + stats['defense']['fail']) * 100).to_i
  end
  shell.puts("   Win rate: #{win_rate}%")

  shell.puts('  Looted:')
  shell.puts("   Money: #{stats['loot']['money']}")
  shell.puts("   Bitcoins: #{stats['loot']['bitcoins']}")
  shell.puts('  Collected:')
  shell.puts("   Money: #{stats['collect']['money']}")
  shell.puts("   Bitcoins: #{stats['collect']['bitcoins']}")
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
