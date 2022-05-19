# frozen_string_literal: true

class Simlink < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify player ID or URI")
      return
    end

    if @args[0] =~ /^\d+$/
      simlink = Hackers::SimLink.new(@args[0].to_i)
      @logger.log(simlink.generate)
    else
      simlink = Hackers::SimLink.new(0)
      begin
        data = simlink.parse(@args[0])
      rescue Hackers::LinkError => e
        @logger.error(e)
        return
      end

      @logger.log("Timestamp: #{Time.at(data[:timestamp] / 1000)}")
      @logger.log("Player ID: #{data[:value]}")
    end
  end
end

