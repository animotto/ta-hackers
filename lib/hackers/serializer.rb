module Hackers
  module Serializer
    ##
    # Default delimeter for sections
    DELIM_SECTION       = '@'
    DELIM_SPEC_SECTION  = "\x03"

    ##
    # Default delimeter for records
    DELIM_RECORD        = ';'
    DELIM_SPEC_RECORD   = "\x02"

    ##
    # Default delimeter for fields
    DELIM_FIELD         = ','
    DELIM_SPEC_FIELD    = "\x01"

    ##
    # Normalizes data - special characters substitution
    def self.normalizeData(data, dir = true)
      if dir
        data&.gsub!(DELIM_SPEC_FIELD, DELIM_FIELD)
        data&.gsub!(DELIM_SPEC_RECORD, DELIM_RECORD)
        data&.gsub!(DELIM_SPEC_SECTION, DELIM_SECTION)
      else
        data&.gsub!(DELIM_FIELD, DELIM_SPEC_FIELD)
        data&.gsub!(DELIM_RECORD, DELIM_SPEC_RECORD)
        data&.gsub!(DELIM_SECTION, DELIM_SPEC_SECTION)
      end

      data
    end

    ##
    # Parses data
    def self.parseData(data, delim1 = DELIM_SECTION, delim2 = DELIM_RECORD, delim3 = DELIM_FIELD)
      array = []
      begin
        data.split(delim1).each.with_index do |section, i|
          array[i] = [] if array[i].nil?
          section.split(delim2).each.with_index do |record, j|
            array[i][j] = [] if array[i][j].nil?
            record.split(delim3).each.with_index do |field, k|
              array[i][j][k] = field
            end
          end
        end
      rescue StandardError
        return array
      end

      array
    end

    ##
    # Base
    class Base
      DELIM_SECTION_NORM = '@'
      DELIM_SECTION_SPEC = "\x03"

      DELIM_RECORD_NORM = ';'
      DELIM_RECORD_SPEC = "\x02"

      DELIM_FIELD_NORM = ','
      DELIM_FIELD_SPEC = "\x01"

      attr_reader :fields

      def initialize(data = nil)
        @data = data.to_s

        @fields = []

        split
      end

      def section(a)
        raise ParserError, "No section #{a}" if a >= @fields.length

        @fields[a]
      end

      def record(a, b)
        s = section(a)
        raise ParserError, "No record #{a}.#{b}" if b >= s.length

        s[b]
      end

      def field(a, b, c)
        r = record(a, b)
        raise ParserError, "No field #{a}.#{b}.#{c}" if c >= r.length

        r[c]
      end

      def section?(a)
        a < @fields.length
      end

      def record?(a, b)
        section?(a) && section(a).length < b
      end

      def field?(a, b, c)
        record?(a, b) && record(a, b).length < c
      end

      def parse(a = nil, b = nil, c = nil); end

      def generate(data); end

      private

      def split
        @data.split(DELIM_SECTION_NORM).each_with_index do |section, i|
          @fields[i] ||= []
          section.split(DELIM_RECORD_NORM).each_with_index do |record, j|
            @fields[i][j] ||= []
            record.split(DELIM_FIELD_NORM).each_with_index do |field, k|
              @fields[i][j][k] = field
            end
          end
        end
      end

      def normalize(data)
        data.tr(
          [
            DELIM_SECTION_SPEC,
            DELIM_RECORD_SPEC,
            DELIM_FIELD_SPEC
          ].join,
          [
            DELIM_SECTION_NORM,
            DELIM_RECORD_NORM,
            DELIM_FIELD_NORM
          ].join
        )
      end

      def denormalize(data)
        data.tr(
          [
            DELIM_SECTION_NORM,
            DELIM_RECORD_NORM,
            DELIM_FIELD_NORM
          ].join,
          [
            DELIM_SECTION_SPEC,
            DELIM_RECORD_SPEC,
            DELIM_FIELD_SPEC
          ].join,
        )
      end
    end

    ##
    # Parser error
    class ParserError < StandardError; end

    ##
    # Exception
    class Exception < Base
      Data = Struct.new(:type, :data)

      def parse(a, b)
        Data.new(
          field(a, b, 0),
          field?(a, b, 1) ? normalize(field(a, b, 1)) : nil
        )
      end
    end

    ##
    # Readme
    class Readme < Base
      DELIM = "\x04"

      Data = Struct.new(:message)

      def parse(a, b, c)
        messages = []
        field(a, b, c).split(DELIM).each do |message|
          messages << Data.new(message)
        end

        messages
      end

      def generate(messages)
        messages.map { |m| m.message }.join(DELIM)
      end
    end

    ##
    # Profile
    class Profile < Base
      Data = Struct.new(
        :id,
        :name,
        :money,
        :bitcoins,
        :credits,
        :experience,
        :rank,
        :builders,
        :x,
        :y,
        :country,
        :skin
      )

      def parse(a, b)
        Data.new(
          field(a, b, 0).to_i,
          field(a, b, 1),
          field(a, b, 2).to_i,
          field(a, b, 3).to_i,
          field(a, b, 4).to_i,
          field(a, b, 5).to_i,
          field(a, b, 9).to_i,
          field(a, b, 10).to_i,
          field(a, b, 11).to_i,
          field(a, b, 12).to_i,
          field(a, b, 13).to_i,
          field(a, b, 14).to_i
        )
      end
    end

    ##
    # Chat
    class Chat < Base
      Data = Struct.new(
        :datetime,
        :name,
        :message,
        :id,
        :experience,
        :rank,
        :country
      )

      def parse(a)
        section(a).reverse_each.map do |record|
          Data.new(
            record[0],
            record[1],
            normalize(record[2]),
            record[3].to_i,
            record[4].to_i,
            record[5].to_i,
            record[6].to_i
          )
        end
      rescue ParserError
        return []
      end
    end

    ##
    # Chat message
    class ChatMessage < Base
      def generate(message)
        denormalize(message)
      end
    end

    ##
    # Shield type
    class ShieldType < Base
      Data = Struct.new(
        :id,
        :hours,
        :price,
        :title,
        :description
      )

      def parse(a)
        section(a).each.map do |record|
          Data.new(
            record[0].to_i,
            record[1].to_i,
            record[3].to_i,
            record[4],
            record[5]
          )
        end
      end
    end

    ##
    # Builder
    class Builder < Base
      Data = Struct.new(:amount, :price)

      def parse(a)
        section(a).map do |record|
          Data.new(
            record[0].to_i,
            record[1].to_i
          )
        end
      end
    end

    ##
    # News
    class News < Base
      Data = Struct.new(:datetime, :title, :body)

      def parse(a)
        section(a).map do |record|
          Data.new(
            record[1],
            record[2],
            record[3]
          )
        end
      end
    end
  end
end
