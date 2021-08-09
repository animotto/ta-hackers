module Trickster
  module Hackers
    ##
    # Base class link generator
    class BaseLink
      HOST = 'link.hackersthegame.com'
      PORT = 443

      def initialize(id)
        @id = id
        @uri = ''
      end

      def to_s
        @uri
      end

      private

      ##
      # Encodes data
      def encode(value, time)
        random = rand(100..999)
        data = ((value + random) ^ time).to_s
        time = time.to_s

        i = 0
        while data[i] == time[i] do
          i += 1
        end

        {
          value:      data[i..-1],
          timestamp:  time[i..-1].reverse,
          common:     data[0..(i - 1)],
          random:     random.to_s,
          checksum:   checksum(data.to_i).to_s,
          data:       data
        }
      end

      ##
      # Calculates checksum
      def checksum(data)
        return 700 if data < 1

        acc = 0
        while data > 9
          acc += data % 10
          data /= 10
        end

        sum = -acc * 7 + 700 - 7
      end
    end

    ##
    # Simulation link generator
    class SimLink < BaseLink
      URI_SIMLINK           = '/simlink.php'
      URI_PARAM_PLAYER      = 'p'
      URI_PARAM_TIMESTAMP   = 't'
      URI_PARAM_COMMON      = 'c'
      URI_PARAM_RANDOM      = 'q'
      URI_PARAM_CHECKSUM    = 's'

      ##
      # Generates simulation link
      def generate
        time = Time.now.strftime('%s%L').to_i
        data = encode(@id, time)
        query = URI.encode_www_form(
          URI_PARAM_PLAYER    => data[:value],
          URI_PARAM_TIMESTAMP => data[:timestamp],
          URI_PARAM_COMMON    => data[:common],
          URI_PARAM_RANDOM    => data[:random],
          URI_PARAM_CHECKSUM  => data[:checksum]
        )
        @uri = URI::HTTPS.build(
          host: BaseLink::HOST,
          port: BaseLink::PORT,
          path: URI_SIMLINK,
          query: query
        )
      end
    end

    ##
    # Replay link generator
    class ReplayLink < BaseLink
      URI_REPLAYLINK        = '/view_replay.php'
      URI_PARAM_REPLAY      = 'r'
      URI_PARAM_TIMESTAMP   = 't'
      URI_PARAM_COMMON      = 'c'
      URI_PARAM_RANDOM      = 'q'
      URI_PARAM_CHECKSUM    = 's'

      ##
      # Generates replay link
      def generate
        time = Time.now.strftime('%s%L').to_i
        data = encode(@id, time)
        query = URI.encode_www_form(
          URI_PARAM_REPLAY    => data[:value],
          URI_PARAM_TIMESTAMP => data[:timestamp],
          URI_PARAM_COMMON    => data[:common],
          URI_PARAM_RANDOM    => data[:random],
          URI_PARAM_CHECKSUM  => data[:checksum]
        )
        @uri = URI::HTTPS.build(
          host: BaseLink::HOST,
          port: BaseLink::PORT,
          path: URI_REPLAYLINK,
          query: query
        )
      end
    end
  end
end
