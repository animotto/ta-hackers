# frozen_string_literal: true

## Commands

# skin
CONTEXT_MARKET.add_command(
  :skin,
  description: 'Buy skin',
  params: ['<type>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  skin = tokens[1].to_i

  msg = 'Buy skin'
  GAME.buy_skin(skin)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# shield
CONTEXT_MARKET.add_command(
  :shield,
  description: 'Buy shield',
  params: ['<type>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  shield = tokens[1].to_i

  msg = 'Buy shield'
  GAME.buy_shield(shield)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# builder
CONTEXT_MARKET.add_command(
  :builder,
  description: 'Buy builder'
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  msg = 'Buy builder'
  GAME.buy_builder
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# money
CONTEXT_MARKET.add_command(
  :money,
  description: 'Buy money',
  params: ['<perc>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  perc = tokens[1].to_i

  msg = 'Buy currency'
  GAME.buy_money(perc)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# bitcoins
CONTEXT_MARKET.add_command(
  :bitcoins,
  description: 'Buy bitcoins',
  params: ['<perc>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  perc = tokens[1].to_i

  msg = 'Buy currency'
  GAME.buy_bitcoins(perc)
  LOGGER.log(msg)
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
