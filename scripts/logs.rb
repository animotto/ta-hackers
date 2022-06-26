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

    table_security = Printer::LogsSecurity.new(logs.security)
    @shell.puts(table_security)
    @shell.puts
    table_hacks = Printer::LogsHacks.new(logs.hacks)
    @shell.puts(table_hacks)
  end
end
