class Rename < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify ID")
      return
    end

    id = @args[0].to_i
    name = @args[1]
    name = "" if name.nil?

    begin
      @game.cmdPlayerSetName(id, name)
    rescue Hackers::RequestError => e
      @logger.error("#{e}")
      return
    end

    msg = String.new
    if name.empty?
      msg = "Name for #{id} cleared"
    else
      msg = "Name for #{id} setted to #{name}"
    end
    @logger.log(msg)
  end
end
