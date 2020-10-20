class Myip < Sandbox::Script
  HOST = "ident.me"
  PORT = 443

  def main
    http = Net::HTTP.new(HOST, PORT)
    http.use_ssl = PORT == 443
    begin
      response = http.get("/")
      raise response.message unless response.instance_of?(Net::HTTPOK)
    rescue => e
      @logger.error(e)
    else
      @logger.log(response.body)
    end
  end
end

