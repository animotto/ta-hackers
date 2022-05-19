# frozen_string_literal: true

class Network < Sandbox::Script
  def main
    unless @game.connected?
      @logger.log(NOT_CONNECTED)
      return
    end

    if @args[0].nil?
      @logger.log('Specify player ID')
      return
    end

    id = @args[0].to_i

    begin
      target = @game.attack_test(id)
    rescue Hackers::RequestError => e
      @logger.error(e)
      return
    end

    @shell.puts("\u2022 Network structure for #{target.profile.name}")
    @shell.puts(
      format(
        '  %-10s %-12s %-5s %-6s %-4s %-4s %-4s %s',
        'ID',
        'Name',
        'Type',
        'Level',
        'X',
        'Y',
        'Z',
        'Relations'
      )
    )

    target.net.each do |node|
      relations = node.relations.map { |r| r.id }
      @shell.puts(
        format(
          '  %-10d %-12s %-5d %-6d %-+4d %-+4d %-+4d %s',
          node.id,
          @game.node_types.get(node.type).name,
          node.type,
          node.level,
          node.x,
          node.y,
          node.z,
          relations
        )
      )
    end
  end
end
