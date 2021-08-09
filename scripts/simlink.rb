class Simlink < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify player ID")
      return
    end

    id = @args[0].to_i

    simlink = Trickster::Hackers::SimLink.new(id)
    @logger.log(simlink.generate)
  end
end

