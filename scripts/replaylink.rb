# frozen_string_literal: true

class Replaylink < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify replay ID or URI")
      return
    end

    if @args[0] =~ /^\d+$/
      replaylink = Hackers::ReplayLink.new(@args[0].to_i)
      @logger.log(replaylink.generate)
    else
      replaylink = Hackers::ReplayLink.new(0)
      begin
        data = replaylink.parse(@args[0])
      rescue Hackers::LinkError => e
        @logger.error(e)
        return
      end

      @logger.log("Timestamp: #{Time.at(data[:timestamp] / 1000)}")
      @logger.log("Replay ID: #{data[:value]}")
    end

  end
end

