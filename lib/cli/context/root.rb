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
  begin
    GAME.transLang = GAME.cmdTransLang
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Application settings'
  begin
    GAME.appSettings = GAME.cmdAppSettings
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Node types and levels'
  begin
    GAME.nodeTypes = GAME.cmdGetNodeTypes
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Program types and levels'
  begin
    GAME.programTypes = GAME.cmdGetProgramTypes
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Missions list'
  begin
    GAME.missionsList = GAME.cmdGetMissionsList
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Skin types'
  begin
    GAME.skinTypes = GAME.cmdSkinTypesGetList
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Hints list'
  begin
    GAME.hintsList = GAME.cmdHintsGetList
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Experience list'
  begin
    GAME.experienceList = GAME.cmdGetExperienceList
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Builders list'
  begin
    GAME.buildersList = GAME.cmdBuildersCountGetList
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Goals types'
  begin
    GAME.goalsTypes = GAME.cmdGoalTypesGetList
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Shield types'
  begin
    GAME.shieldTypes = GAME.cmdShieldTypesGetList
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Rank list'
  begin
    GAME.rankList = GAME.cmdRankGetList
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  msg = 'Authenticate'
  begin
    auth = GAME.cmdAuthIdPassword
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
  LOGGER.log(msg)

  GAME.sid = auth['sid']
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
    shell.puts(format('%-20s %d (%s)', 'Country', GAME.missionsList[id]['country'], GAME.countriesList.fetch(GAME.missionsList[id]['country'].to_s, 'Unknown')))
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
  begin
    news = GAME.cmdNewsGetList
  rescue Trickster::Hackers::RequestError => e
    LOGGER.error("#{msg} (#{e})")
    next
  end
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
