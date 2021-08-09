class Replaylink < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify replay ID")
      return
    end

    id = @args[0].to_i

    replaylink = Trickster::Hackers::ReplayLink.new(id)
    @logger.log(replaylink.generate)
  end
end

