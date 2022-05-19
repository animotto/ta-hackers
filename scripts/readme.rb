# frozen_string_literal: true

class Readme < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log('Specify player ID')
      return
    end

    id = @args[0].to_i

    begin
      friend = @game.friend(id)
      friend.load_readme
    rescue Hackers::RequestError => e
      @logger.error(e)
    end

    readme = friend.readme

    if readme.empty?
      @logger.log('Readme is empty')
      return
    end

    readme.each do |message|
      @logger.log(message)
    end
  end
end
