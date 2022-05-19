# frozen_string_literal: true

require 'resolv'

class Myip < Sandbox::Script
  HOST = 'ident.me'
  PORT = 443

  def main
    http = Net::HTTP.new(HOST, PORT)
    http.use_ssl = PORT == 443
    ip = String.new
    begin
      response = http.get('/')
      raise StandardError, response.message unless response.instance_of?(Net::HTTPOK)
      ip = response.body
    rescue StandardError => e
      @logger.error(e)
      return
    end

    line = ip
    begin
      line << ' / ' + Resolv.getname(ip)
    rescue StandardError
    end

    @logger.log(line)
  end
end

