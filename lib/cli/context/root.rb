# frozen_string_literal: true

## Contexts

# query
CONTEXT_QUERY = SHELL.root.add_context(:query, description: 'Analyze queries and data dumps')
# net
CONTEXT_NET = SHELL.root.add_context(:net, description: 'Network')
# prog
CONTEXT_PROG = SHELL.root.add_context(:prog, description: 'Programs')
# mission
CONTEXT_MISSION = SHELL.root.add_context(:mission, description: 'Mission')
# world
CONTEXT_WORLD = SHELL.root.add_context(:world, description: 'World')
# script
CONTEXT_SCRIPT = SHELL.root.add_context(:script, description: 'Scripts')
# chat
CONTEXT_CHAT = SHELL.root.add_context(:chat, description: 'Internal chat')
# buy
CONTEXT_BUY = SHELL.root.add_context(:buy, description: 'The buys')

## Commands

# connect
SHELL.root.add_command(:connect, description: 'Connect to the server') do |shell, context, tokens|
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
SHELL.root.add_command(:sid, description: 'Show session ID') do |shell, context, tokens|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  shell.puts("SID: #{GAME.sid}")
end

# trans
SHELL.root.add_command(:trans, description: 'Language translations') do |shell, context, tokens|
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
SHELL.root.add_command(:settings, description: 'Application settings') do |shell, context, tokens|
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
SHELL.root.add_command(:nodes, description: 'Node types') do |shell, context, tokens|
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
SHELL.root.add_command(:progs, description: 'Program types') do |shell, context, tokens|
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
SHELL.root.add_command(:missions, description: 'Missions list') do |shell, context, tokens|
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
SHELL.root.add_command(:skins, description: 'Skin types') do |shell, context, tokens|
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
SHELL.root.add_command(:news, description: 'News') do |shell, context, tokens|
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
SHELL.root.add_command(:hints, description: 'Hints list') do |shell, context, tokens|
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
SHELL.root.add_command(:experience, description: 'Experience list') do |shell, context, tokens|
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
SHELL.root.add_command(:builders, description: 'Builders list') do |shell, context, tokens|
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
SHELL.root.add_command(:goals, description: 'Goals types') do |shell, context, tokens|
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
SHELL.root.add_command(:shields, description: 'Shield types') do |shell, context, tokens|
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
SHELL.root.add_command(:ranks, description: 'Rank list') do |shell, context, tokens|
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
SHELL.root.add_command(:countries, description: 'Contries list') do |shell, context, tokens|
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
SHELL.root.add_command(:new, description: 'Create new account') do |shell, context, tokens|
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
SHELL.root.add_command(:rename, description: 'Set new name') do |shell, context, tokens|
  if tokens[1].nil?
    shell.puts('Specify name')
    next
  end

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
SHELL.root.add_command(:info, description: 'Get player info') do |shell, context, tokens|
  if tokens[1].nil?
    shell.puts('Specify ID')
    next
  end

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
SHELL.root.add_command(:detail, description: "Get detailed info about player's network") do |shell, context, tokens|
  if tokens[1].nil?
    shell.puts('Specify ID')
    next
  end

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
SHELL.root.add_command(:hq, description: 'Set player HQ') do |shell, context, tokens|
  x = tokens[1]
  y = tokens[2]
  country = tokens[3]
  if x.nil? || y.nil? || country.nil?
    shell.puts('Specify x, y, country')
    next
  end

  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Set player HQ'
  GAME.cmdSetPlayerHqCountry(GAME.config['id'], x.to_i, y.to_i, country.to_i)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# skin
SHELL.root.add_command(:skin, description: 'Set player skin') do |shell, context, tokens|
  if tokens[1].nil?
    shell.puts('Specify skin')
    next
  end

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
SHELL.root.add_command(:tutorial, description: 'Set tutorial') do |shell, context, tokens|
  if tokens[1].nil?
    shell.puts('Specify tutorial')
    next
  end

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
SHELL.root.add_command(:email, description: 'Email subscribe') do |shell, context, tokens|
  if tokens[1].nil?
    shell.puts('Specify email')
    next
  end

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
SHELL.root.add_command(:top, description: 'Show top ranking') do |shell, context, tokens|
  if tokens[1].nil?
    shell.puts('Specify country')
    next
  end

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
SHELL.root.add_command(:cpgen, description: 'Cp generate code') do |shell, context, tokens|
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
SHELL.root.add_command(:cpuse, description: 'Cp use code') do |shell, context, tokens|
  if tokens[1].nil?
    shell.puts('Specify code')
    next
  end

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
SHELL.root.add_command(:stats, description: 'Show player statistics') do |shell, context, tokens|
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
