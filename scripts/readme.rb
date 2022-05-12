class Readme < Sandbox::Script
  def main
    if @args[0].nil?
      @logger.log("Specify player ID")
      return
    end

    begin
      readme = @game.cmdPlayerGetReadme(@args[0])
    rescue Hackers::RequestError => e
      @logger.error(e)
    end
    if readme.empty?
      @logger.log("Readme is empty")
      return
    end

    readme.each do |message|
      @logger.log(message)
    end
  end
end

