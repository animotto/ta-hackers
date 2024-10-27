# frozen_string_literal: true

MISSION_FLAGON_CHAR = "\u2691"
MISSION_FLAGOFF_CHAR = "\u2690"

## Commands

# list
CONTEXT_MISSION.add_command(
  :list,
  description: 'Show missions log'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Missions get log'
  GAME.missions.load
  LOGGER.log(msg)

  missions = GAME.missions

  items = []
  missions.each do |mission|
    mission_type = GAME.missions_list.get(mission.id)

    status = String.new
    case mission.status
    when Hackers::Missions::AWAITS
      status = ColorTerm.white(MISSION_FLAGOFF_CHAR)
    when Hackers::Missions::FINISHED
      status = ColorTerm.green(MISSION_FLAGON_CHAR)
    when Hackers::Missions::REJECTED
      status = ColorTerm.red(MISSION_FLAGON_CHAR)
    end

    items << [
      status,
      mission.id,
      mission.money,
      mission.bitcoins,
      mission.datetime,
      mission_type.name
    ]
  end

  table = Printer::Table.new(
    'Missions log',
    ['', 'ID', 'Money', 'Bitcoins', 'Datetime', 'Name'],
    items
  )
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# start
CONTEXT_MISSION.add_command(
  :start,
  description: 'Start mission',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i

  unless GAME.missions_list.exist?(id)
    shell.puts('No such mission')
    next
  end

  msg = 'Mission message delivered'
  GAME.missions.start(id)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# reject
CONTEXT_MISSION.add_command(
  :reject,
  description: 'Reject mission',
  params: ['<id>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  id = tokens[1].to_i

  unless GAME.missions_list.exist?(id)
    shell.puts('No such mission')
    next
  end

  unless GAME.missions.exist?(id)
    shell.puts('Mission is not started')
    next
  end

  mission = GAME.missions.get(id)

  msg = 'Mission reject'
  mission.reject
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
