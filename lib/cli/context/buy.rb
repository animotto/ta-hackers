# frozen_string_literal: true

## Commands

# skin
CONTEXT_BUY.add_command(
  :skin,
  description: 'Buy skin',
  params: ['<type>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  skin = tokens[1].to_i

  msg = 'Buy skin'
  GAME.cmdPlayerBuySkin(skin)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# skin
CONTEXT_BUY.add_command(
  :shield,
  description: 'Buy shield',
  params: ['<type>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  shield = tokens[1].to_i

  msg = 'Buy shield'
  GAME.cmdShieldBuy(shield)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# builder
CONTEXT_BUY.add_command(
  :builder,
  description: 'Buy builder'
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  msg = 'Buy builder'
  GAME.cmdPlayerBuyBuilder
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# money
CONTEXT_BUY.add_command(
  :money,
  description: 'Buy money',
  params: ['<perc>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  perc = tokens[1].to_i

  msg = 'Buy currency'
  GAME.cmdPlayerBuyCurrencyPerc(Trickster::Hackers::Game::CURRENCY_MONEY, perc)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# bitcoins
CONTEXT_BUY.add_command(
  :bitcoins,
  description: 'Buy bitcoins',
  params: ['<perc>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  perc = tokens[1].to_i

  msg = 'Buy currency'
  GAME.cmdPlayerBuyCurrencyPerc(Trickster::Hackers::Game::CURRENCY_BITCOINS, perc)
  LOGGER.log(msg)
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end
