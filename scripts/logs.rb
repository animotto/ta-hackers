# frozen_string_literal: true

class Logs < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log('Specify player ID')
      return
    end

    id = @args[0].to_i

    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    friend = @game.friend(id)

    begin
      friend.load_logs
    rescue Hackers::RequestError => e
      @logger.error(e)
      return
    end

    logs = friend.logs

    @shell.puts("\e[1;35m\u2022 Security\e[0m")
    if logs.security.empty?
      @shell.puts('  Empty')
    else
      @shell.puts(
        format(
          "  \e[35m%-7s %-10s %-19s %-10s %-5s %s\e[0m",
          '',
          'ID',
          'Datetime',
          'Attacker',
          'Level',
          'Name'
        )
      )
    end

    logs.security.each do |record|
      @shell.puts(
        format(
          "  %s%s%s %+-3d %-10s %-19s %-10s %-5d %s",
          record.success & Hackers::Network::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
          record.success & Hackers::Network::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
          record.success & Hackers::Network::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
          record.rank,
          record.id,
          record.datetime,
          record.attacker_id,
          record.attacker_level,
          record.attacker_name,
        )
      )
    end

    @shell.puts
    @shell.puts("\e[1;35m\u2022 Hacks\e[0m")
    if logs.hacks.empty?
      @shell.puts('  Empty')
    else
      @shell.puts(
        format(
          "  \e[35m%-7s %-10s %-19s %-10s %-5s %s\e[0m",
          '',
          'ID',
          'Datetime',
          'Target',
          'Level',
          'Name'
        )
      )
    end

    logs.hacks.each do |record|
      @shell.puts(
        format(
          "  %s%s%s %+-3d %-10s %-19s %-10s %-5d %s",
          record.success & Hackers::Network::SUCCESS_CORE == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
          record.success & Hackers::Network::SUCCESS_RESOURCES == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
          record.success & Hackers::Network::SUCCESS_CONTROL == 0 ? "\u25b3" : "\e[32m\u25b2\e[0m",
          record.rank,
          record.id,
          record.datetime,
          record.target_id,
          record.target_level,
          record.target_name,
        )
      )
    end
  end
end
