module Trickster
  module Hackers
    ##
    # Profile object
    class Profile
      ##
      # Profile attributes
      attr_reader :id, :name, :money,
                  :bitcoins, :credits,
                  :experience, :rank,
                  :builders, :x, :y,
                  :country, :skin
      ##
      # Creates new Profile:
      #   ID,
      #   Name,
      #   Money,
      #   Bitcoins,
      #   Credits,
      #   Experience,
      #   Rank,
      #   Builders,
      #   X,
      #   Y,
      #   Country,
      #   Skin,
      def initialize(*args)
        @id, @name, @money,
        @bitcoins, @credits,
        @experience, @rank,
        @builders, @x, @y,
        @country, @skin = args
      end
    end

    ##
    # Readme object
    class Readme
      include Enumerable

      ##
      # Array of messages
      attr_reader :messages

      ##
      # Creates new Readme:
      #   messages = [
      #     Message1,
      #     Message2,
      #     Message3,
      #     ...
      #   ]
      def initialize(messages = [])
        @messages = messages
      end

      ##
      # Enumerates messages
      def each(&block)
        @messages.each(&block)
      end

      ##
      # Writes new message:
      #   message = Message
      def write(message)
        @messages.unshift(message)
      end

      ##
      # Removes message:
      #   index = Index
      def remove(index)
        @messages.delete_at(index)
      end

      ##
      # Removes all messages
      def clear
        @messages.clear
      end

      ##
      # Checks for emptiness
      #
      # Returns true of false
      def empty?
        @messages.empty?
      end

      ##
      # Checks message index:
      #   index = Index
      #
      # Returns true or false
      def id?(index)
        @messages[index].nil?
      end
    end
  end
end

