# frozen_string_literal: true

require 'net/http'
require 'digest'
require 'base64'

module Hackers
  ##
  # A client to communicate with the HTTP server
  class Client
    ##
    # HTTP headers
    HEADERS = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Accept-Charset' => 'utf-8',
      'Accept-Encoding' => 'gzip, identity',
      'User-Agent' => 'BestHTTP/2 v2.2.0'
    }.freeze

    ##
    # Creates a new client
    def initialize(host, port, ssl, uri, salt, amount = 5)
      @uri = uri
      @salt = salt
      @clients = {}
      amount.times do
        client = Net::HTTP.new(host, port.to_i)
        client.use_ssl = ssl
        @clients[client] = Mutex.new
      end
    end

    ##
    # Generates a raw URI
    def generate_uri_raw(params)
      "#{@uri}?#{URI.encode_www_form(params)}"
    end

    ##
    # Generates a hashed URI
    def generate_uri_cmd(params)
      params['cmd_id'] = hash_uri(generate_uri_raw(params))
      generate_uri_raw(params)
    end

    ##
    # Generates a sessioned URI
    def generate_uri_session(params, sid)
      params['session_id'] = sid
      generate_uri_cmd(params)
    end

    ##
    # Does the raw request
    def request_raw(params, data: {})
      client, mutex = @clients.detect { |_, v| !v.locked? }
      client, mutex = @clients.to_a.first if client.nil?

      uri = generate_uri_raw(params)
      response = nil
      mutex.synchronize do
        response = data.empty? ? client.get(uri, HEADERS) : client.post(uri, URI.encode_www_form(data), HEADERS)
      rescue StandardError => e
        raise RequestError.new(e.class.to_s, e.message)
      end

      body = response.body.force_encoding('UTF-8')
      unless response.instance_of?(Net::HTTPOK)
        fields = Serializer.parseData(body)
        raise RequestError.new(
          Serializer.normalizeData(fields.dig(0, 0, 0)),
          Serializer.normalizeData(fields.dig(0, 0, 1))
        )
      end

      body
    end

    ##
    # Does the hashed request
    def request_cmd(params, data: {})
      uri = generate_uri_raw(params)
      params['cmd_id'] = hash_uri(uri)
      request_raw(params, data: data)
    end

    ##
    # Does the sessioned request
    def request_session(params, sid, data: {})
      params['session_id'] = sid
      request_cmd(params, data: data)
    end

    private

    ##
    # Computes a hash of the URI
    def hash_uri(uri)
      data = String.new
      data << uri
      offset = data.length < 10 ? data.length : 10
      data.insert(offset, @salt)
      hash = Digest::MD5.digest(data)
      hash = Base64.strict_encode64(hash[2..7])
      hash.gsub('=', '.').gsub('+', '-').gsub('/', '_')
    end
  end

  ##
  # An exception raises when the request fails
  class RequestError < StandardError
    attr_reader :type, :description

    ##
    # Creates a new exception
    def initialize(type = nil, description = nil)
      super
      @type = type&.strip
      @description = description&.strip
    end

    ##
    # Returns the description of the exception as a string
    def to_s
      msg = String.new
      msg += @type.nil? ? 'Unknown' : @type
      msg += ": #{@description}" unless @description.nil?
      msg
    end
  end
end
