class Rename < Sandbox::Script
  def main
    if @args[0].nil?
      @shell.log("Specify ID", :script)
      return
    end

    id = @args[0].to_i
    name = @args[1]
    name = "" if name.nil?

    begin
      @game.cmdPlayerSetName(id, name)
    rescue Trickster::Hackers::RequestError => e
      @shell.log("#{e.type}: #{e.description}", :script)
      return
    end

    msg = String.new
    if name.empty?
      msg = "Name for #{id} cleared"
    else
      msg = "Name for #{id} setted to #{name}"
    end
    @shell.log(msg, :script)
  end
end
