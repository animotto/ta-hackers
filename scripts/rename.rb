class Rename < Sandbox::Script
  def main
    if @args[0].nil?
      @shell.log("Specify ID", :script)
      return
    end

    id = @args[0].to_i
    name = @args[1]
    name = "" if name.nil?

    msg = String.new
    if @game.cmdPlayerSetName(id, name)
      if name.empty?
        msg = "Name for #{id} cleared"
      else
        msg = "Name for #{id} setted to #{name}"
      end
    else
      msg = "Error renaming"
    end
    @shell.log(msg, :script)
  end
end
