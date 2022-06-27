# frozen_string_literal: true

## Commands

# nearby
CONTEXT_TOP.add_command(
  :nearby,
  description: 'Nearby players'
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

  table = Printer::TopPlayers.new(GAME.ranking_list.nearby, GAME)
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# country
CONTEXT_TOP.add_command(
  :country,
  description: 'Country players'
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

  table = Printer::TopPlayers.new(GAME.ranking_list.country, GAME)
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# world
CONTEXT_TOP.add_command(
  :world,
  description: 'World players'
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

  table = Printer::TopPlayers.new(GAME.ranking_list.world, GAME)
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# countries
CONTEXT_TOP.add_command(
  :countries,
  description: 'Countries'
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

  table = Printer::TopCountries.new(GAME.ranking_list.countries, GAME)
  shell.puts(table)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
