class Network < Sandbox::Script
  def main
    if @game.sid.empty?
      @logger.log("No session ID")
      return
    end

    if @args[0].nil?
      @logger.log("Specify player ID")
      return
    end
    target = @args[0].to_i

    begin
      net = @game.cmdTestFightPrepare(target)
    rescue Hackers::RequestError => e
      @logger.error(e)
      return
    end

    @shell.puts("\u2022 Network structure for #{net["profile"].name}")
    @shell.puts(
      "  %-5s %-12s %-12s %-5s %-4s %-4s %-4s %s" % [
        "Index",
        "ID",
        "Name",
        "Type",
        "X",
        "Y",
        "Z",
        "Relations",
      ]
    )
    net["net"].each_index do |i|
      id = net["net"][i]["id"]
      type = net["nodes"][id]["type"]
      @shell.puts(
        "  %-5d %-12d %-12s %-5d %-+4d %-+4d %-+4d %s" % [
          i,
          id,
          @game.node_types.get(type).name,
          type,
          net["net"][i]["x"],
          net["net"][i]["y"],
          net["net"][i]["z"],
          net["net"][i]["rels"],
        ]
      )
    end
  end
end

