module Trickster
  module Hackers
    ##
    # Data serializer
    class Serializer
      ##
      # Default delimeter for sections
      DELIM_SECTION       = "@"
      DELIM_NORM_SECTION  = "\x03"

      ##
      # Default delimeter for records
      DELIM_RECORD        = ";"
      DELIM_NORM_RECORD   = "\x02"

      ##
      # Default delimeter for fields
      DELIM_FIELD         = ","
      DELIM_NORM_FIELD    = "\x01"

      ##
      # Delimiter for readme messages
      DELIM_README  = "\x04"

      ##
      # Raw data parsed into fields
      attr_reader :fields

      ##
      # Creates new serializer:
      #   data = Raw data
      def initialize(data, delim1 = DELIM_SECTION, delim2 = DELIM_RECORD, delim3 = DELIM_FIELD)
        @fields = self.class.parseData(data, delim1, delim2, delim3)
      end

      ##
      # Normalizes data - special characters substitution:
      #   data  = Raw data
      #   dir   = Direction
      #
      # Returns a normalized string
      def self.normalizeData(data, dir = true)
        if dir
          data.gsub!(DELIM_NORM_FIELD, DELIM_FIELD)
          data.gsub!(DELIM_NORM_RECORD, DELIM_RECORD)
          data.gsub!(DELIM_NORM_SECTION, DELIM_SECTION)
        else
          data.gsub!(DELIM_FIELD, DELIM_NORM_FIELD)
          data.gsub!(DELIM_RECORD, DELIM_NORM_RECORD)
          data.gsub!(DELIM_SECTION, DELIM_NORM_SECTION)
        end
        return data
      end

      ##
      # Parses data:
      #   data    = Raw data
      #   delim1  = Delimiter1
      #   delim2  = Delimiter2
      #   delim3  = Delimiter3
      #
      # Returns a 3-dimensional array:
      #   [
      #     [
      #       [field1, field2, field3]
      #     ]
      #   ]
      def self.parseData(data, delim1 = DELIM_SECTION, delim2 = DELIM_RECORD, delim3 = DELIM_FIELD)
        array = Array.new
        begin
          data.split(delim1).each.with_index do |section, i|
            array[i] = Array.new if array[i].nil?
            section.split(delim2).each.with_index do |record, j|
              array[i][j] = Array.new if array[i][j].nil?
              record.split(delim3).each.with_index do |field, k|
                array[i][j][k] = field
              end
            end
          end
        rescue
          return array
        end
        return array
      end

      ##
      # Parses translations:
      #   section = Section index
      #
      # Returns hash:
      #   {
      #     Name1 => Text1,
      #     Name2 => Text2,
      #     Name3 => Text3,
      #   }
      def parseTransLang(section)
        data = Hash.new
        @fields[section].each do |record|
          data[record[0]] = record[1]
        end
        return data
      end

      ##
      # Parses application settings:
      #   section = Section index
      #
      # Returns hash:
      #   {
      #     Option1       => Value1,
      #     Option2       => Value3,
      #     Option3       => Value3,
      #     ...
      #     "datetime"    => Datetime,
      #     "langeuages"  => {
      #       Language1 => Value1,
      #       Language2 => Value2,
      #       Language3 => Value3,
      #       ...
      #     },
      #     ...
      #   }
      def parseAppSettings(section)
        data = Hash.new
        for i in (0..10) do
          data[@fields[section][i][1]] = @fields[section][i][2]
        end
        
        data["datetime"] = @fields[section][11][0]

        data["languages"] = Hash.new
        @fields[section][12].each do |field|
          language = field.split(":")
          data["languages"][language[0]] = language[1]
        end

        for i in (13..17) do
          data[@fields[section][i][0]] = @fields[section][i][1]
        end
        
        return data
      end

      ##
      # Parses node types, levels and limits
      #
      # Returns hash:
      #   {
      #     Type => {
      #       "name"    => Name,
      #       "levels"  => {
      #         Level => {
      #           "cost"        => Upgrade cost,
      #           "core"        => Core level requirements,
      #           "experience"  => Experience gained,
      #           "upgrade"     => Upgrade time,
      #           "connections" => Amount of connections,
      #           "slots"       => Amount of slots,
      #           "firewall"    => Firewall,
      #           "data"        => [Extra data],
      #         }
      #       },
      #       "limits"  => {
      #         Level => Node amount limit,
      #       },
      #       "titles"  => [Extra data titles],
      #     }
      #   }
      def parseNodeTypes
        data = Hash.new

        @fields[0].each do |f|
          data[f[0].to_i] = {
            "name"    => f[1],
            "levels"  => Hash.new,
            "limits"  => Hash.new,
            "titles"  => [
              f[2], f[3], f[4],
              f[5], f[6], f[7],
            ],
          }
        end

        @fields[1].each do |f|
          next unless data.key?(f[1].to_i)
          data[f[1].to_i]["levels"][f[2].to_i] = {
            "cost"        => f[3].to_i,
            "core"        => f[5].to_i,
            "experience"  => f[6].to_i,
            "upgrade"     => f[7].to_i,
            "connections" => f[8].to_i,
            "slots"       => f[9].to_i,
            "firewall"    => f[10].to_i,
            "data"        => [
              f[13].to_i, f[14].to_i, f[15].to_i,
              f[16].to_i, f[17].to_i, f[18].to_i,
            ],
          }
        end

        @fields[2].each do |f|
          next unless data.key?(f[1].to_i)
          data[f[1].to_i]["limits"][f[2].to_i] = f[3].to_i
        end

        return data
      end

      ##
      # Parses program types and levels
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "type"  => Type,
      #       "name"  => Name,
      #       "Levels"  => {
      #         ID => {
      #           "cost"        => Upgrade cost,
      #           "experience"  => Experience gained,
      #           "price"       => Price,
      #           "compile"     => Compilation time,
      #           "disk"        => Disk space usage,
      #           "install"     => Installation time,
      #           "upgrade"     => Upgrade time,
      #           "rate"        => Rate,
      #           "strength"    => Strength,
      #           "data"        => [Extra data],
      #           "evolver"     => Evolver level requirements,
      #         }
      #       },
      #       "titles"  => [Extra data titles],
      #     }
      #   }
      def parseProgramTypes
        data = Hash.new

        @fields[0].each do |f|
          data[f[0].to_i] = {
            "type"    => f[1].to_i,
            "name"    => f[2],
            "levels"  => Hash.new,
            "titles"  => [
              f[3], f[4], f[5],
              f[6], f[7],
            ],
          }
        end

        @fields[1].each do |f|
          data[f[1].to_i]["levels"][f[2].to_i] = {
            "cost"        => f[3].to_i,
            "experience"  => f[4].to_i,
            "price"       => f[5].to_i,
            "compile"     => f[6].to_i,
            "disk"        => f[7].to_i,
            "install"     => f[8].to_i,
            "upgrade"     => f[9].to_i,
            "rate"        => f[10].to_i,
            "strength"    => f[11].to_i,
            "data"        => [
              f[12], f[13], f[14],
              f[15], f[16],
            ],
            "evolver"     => f[17].to_i,
          }
        end

        return data
      end

      ##
      # Parses missions list
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "name"          => Name,
      #       "target"        => Target,
      #       "messages"      => {
      #         "begin" => Begin,
      #         "end"   => End,
      #         "news"  => News,
      #       },
      #       "goals"         => Goals,
      #       "x"             => X,
      #       "y"             => Y,
      #       "country"       => Country,
      #       "requirements"  => {
      #         "mission" => Mission,
      #         "core"     => Core level,
      #       },
      #       "reward"  => {
      #         "money"     => Money,
      #         "bitcoins"  => Bitcoins,
      #       },
      #       "network"       => Serializer#parseNetwork,
      #       "nodes"         => Serializer#parseNodes,
      #       "money"         => Money,
      #       "bitcoins"      => Bitcoins,
      #       "group"         => Group,
      #     }
      #   }
      def parseMissionsList
        data = Hash.new
        @fields[0].each_with_index do |field, i|
          data[field[0].to_i] = {
            "name"          => field[1],
            "target"        => field[2],
            "messages"      => {
              "begin" => self.class.normalizeData(field[3]),
              "end"   => self.class.normalizeData(field[17]),
              "news"  => self.class.normalizeData(field[19]),
            },
            "goals"         => self.class.normalizeData(field[4]).split(","),
            "x"             => field[5].to_i,
            "y"             => field[6].to_i,
            "country"       => field[7].to_i,
            "requirements"  => {
              # TODO: parse mission data
              "mission"     => self.class.normalizeData(field[9]),
              "core"        => field[12].to_i,
            },
            "reward"        => {
              "money"     => field[13].to_i,
              "bitcoins"  => field[14].to_i,
            },
            "network"       => parseNetwork(0, i, 21),
            "nodes"         => Serializer.new(self.class.normalizeData(field[22])).parseNodes(0),
            "money"         => field[24].to_i,
            "bitcoins"      => field[25].to_i,
            "group"         => field[28],
          }
        end
        return data
      end

      ##
      # Parses network structure:
      #   section = Section index
      #   record  = Record index
      #   field   = Field index
      #
      #   Fields in format:
      #     X1*Y1*Z1_X2*Y2*Z2_X3*Y3*Z3_|I1*R1_I2*R2_I3*R3_|ID1_ID2_ID3_
      #
      # Returns array:
      #   [
      #     {
      #       "id"    => Node ID,
      #       "x"     => X,
      #       "y"     => Y,
      #       "z"     => Z,
      #       "rels"  => [
      #         Relation1,
      #         Relation2,
      #         Relation3,
      #       ],
      #     }
      #   ]
      def parseNetwork(section, record, field)
        net = Array.new
        begin
          records = @fields[section][record][field].split("|")
          coords = records[0].split("_")
          rels = records[1].split("_")
          nodes = records[2].split("_")
        rescue
          return net
        end
        nodes.each_index do |i|
          coord = coords[i].split("*")
          net[i] = {
            "id"  => nodes[i].to_i,
            "x"   => coord[0].to_i,
            "y"   => coord[1].to_i,
            "z"   => coord[2].to_i,
          }
        end
        rels.each_index do |i|
          rel = rels[i].split("*")
          index = rel[0].to_i
          net[index]["rels"] = Array.new if net[index]["rels"].nil?
          net[index]["rels"].append(rel[1].to_i)
        end
        return net
      end

      ##
      # Generates network structure:
      #   data = Serialize#parseNetwork
      #
      # Returns the string in format:
      #   X1*Y1*Z1_X2*Y2*Z2_X3*Y3*Z3_|I1*R1_I2*R2_I3*R3_|ID1_ID2_ID3_
      def self.generateNetwork(data)
        nodes = String.new
        coords = String.new
        rels = String.new
        data.each_index do |i|
          nodes += "#{data[i]["id"]}_"
          coords += "#{data[i]["x"]}*#{data[i]["y"]}*#{data[i]["z"]}_"
          unless data[i]["rels"].nil?
            data[i]["rels"].each do |rel|
              rels += "#{i}*#{rel}_"
            end
          end
        end
        net = "#{coords}|#{rels}|#{nodes}"
        return net
      end

      ##
      # Parses profile:
      #   section = Section index
      #   record  = Record index
      #
      #   Fields in format:
      #     ID,Name,Money,Bitcoins,Credits,Experience,Unknown,Unknown,Unknown,Rank,Builders,X,Y,Country,Skin;
      #
      # Returns *Profile*
      def parseProfile(section, record)
        profile = Profile.new(
          @fields[section][record][0].to_i,
          @fields[section][record][1],
          @fields[section][record][2].to_i,
          @fields[section][record][3].to_i,
          @fields[section][record][4].to_i,
          @fields[section][record][5].to_i,
          @fields[section][record][9].to_i,
          @fields[section][record][10].to_i,
          @fields[section][record][11].to_i,
          @fields[section][record][12].to_i,
          @fields[section][record][13].to_i,
          @fields[section][record][14].to_i,
        )
        return profile
      end
      
      ##
      # Parses nodes:
      #   section = Section index
      #
      #   Fields in format:
      #     ID,PlayerID,Type,Level,Timer,Builders;
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "type"       => Type,
      #       "level"     => Level,
      #       "Timer"     => Timer,
      #       "Builders"  => Builders,
      #     }
      #   }
      def parseNodes(section)
        nodes = Hash.new
        return nodes if @fields[section].nil?
        @fields[section].each do |node|
          nodes[node[0].to_i] = {
            "type"      => node[2].to_i,
            "level"     => node[3].to_i,
            "timer"     => node[4].to_i,
            "builders"  => node[5]&.to_i,
          }
        end
        return nodes
      end

      ##
      # Parses readme:
      #   section = Section index
      #   record  = Record index
      #   field   = Field index
      #
      #   Fields in format:
      #     Message1\x04Message2\x04Message3
      #
      # Returns *Readme*
      def parseReadme(section, record, field)
        readme = Array.new
        readme = @fields[section][record][field].split(DELIM_README) unless @fields.dig(section, record, field).nil?
        readme.map! {|line| self.class.normalizeData(line)}
        return Readme.new(readme)
      end

      ##
      # Generates readme raw data:
      #   readme = *Readme*
      #
      # Returns raw data as a string in format:
      #   Message1\x04Message2\x04Message3
      def self.generateReadme(readme)
        Serializer.normalizeData(readme.messages.join(DELIM_README), false)
      end

      ##
      # Parses attack logs:
      #   section = Section index
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "date"      => Datetime,
      #       "attacker"  => {
      #         "id"        => ID,
      #         "name"      => Name,
      #         "country"   => Country,
      #         "level"     => Level,
      #       },
      #       "target"  => {
      #         "id"        => ID,
      #         "name"      => Name,
      #         "country"   => Country,
      #         "level"     => Level,
      #       },
      #       "programs"  => Programs,
      #       "money"     => Money,
      #       "bitcoins"  => Bitcoins,
      #       "success"   => Success,
      #       "rank"      => Rank,
      #       "test"      => Test fight,
      #     }
      #   }
      def parseLogs(section)
        logs = Hash.new
        @fields[section].each_with_index do |log, i|
          logs[log[0].to_i] = {
            "date"      => log[1],
            "attacker"  => {
              "id"       => log[2].to_i,
              "name"     => log[9],
              "country"  => log[11].to_i,
              "level"    => log[16].to_i,
            },
            "target"    => {
              "id"        => log[3].to_i,
              "name"      => log[10],
              "country"   => log[12].to_i,
              "level"     => log[17].to_i,
            },
            "programs"  => parseUsedPrograms(section, i, 7),
            "money"     => log[4].to_i,
            "bitcoins"  => log[5].to_i,
            "success"   => log[6].to_i,
            "rank"      => log[13].to_i,
            "test"      => log[18].to_i == 1,
          }
        end
        return logs
      end

      ##
      # Parses used programs:
      #   section = Section index
      #   record  = Record index
      #   field   = Field index
      #
      #   Fields in format:
      #     Type1:Amount1:Type2:Amount2:Type3:Amount3
      #
      # Returns hash:
      #   {
      #     Type1   => Amount1,
      #     Type2   => Amount2,
      #     Type3   => Amount3,
      #     ...
      #   }
      def parseUsedPrograms(section, record, field)
        programs = Hash.new
        fields = @fields[section][record][field].split(":")
        0.step(fields.length - 1, 2) do |i|
          programs[fields[i].to_i] = fields[i + 1].to_i
        end
        return programs
      end

      ##
      # Parses replay programs:
      #   section = Section index
      #
      # Returns array:
      #   [
      #     {
      #       "id"      => ID,
      #       "type"    => Type,
      #       "level"   => Level,
      #       "amount"  => Amount,
      #     }
      #     ...
      #   ]
      def parseReplayPrograms(section)
        programs = Array.new
        @fields[section].each do |program|
          programs.push(
            {
              "id"      => program[0].to_i,
              "type"    => program[2].to_i,
              "level"   => program[3].to_i,
              "amount"  => program[4].to_i,
            }
          )
        end
        return programs
      end

      ##
      # Parses replay trace:
      #   section = Section index
      #
      # Returns array:
      #   [
      #     {
      #       "type"      => Type,
      #       "time"      => Time,
      #       "node"      => Node,
      #       "program"   => Program,
      #       "index"     => Index,
      #     }
      #     ...
      #   ]
      def parseReplayTrace(section)
        trace = Array.new
        @fields[section].each do |t|
          type = t[0][0]
          time = t[0][1..-1]
          i = {
            "type" => type,
            "time" => time.to_i,
          }
          i["node"] = t[1].to_i if type == "s" || type == "i" || type == "u"
          i["program"] = t[2].to_i if type == "i"
          i["index"] = t[2].to_i if type == "u"
          trace.push(i)
        end
        trace.sort! {|i| -i["time"]}
        return trace
      end

      ##
      # Parses targets:
      #   section = Section index
      #
      #   Fields in format:
      #       ID,Name,Experience,X,Y,Country,Skin;
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "name"        => Name,
      #       "experience"  => Experience,
      #       "x"           => X,
      #       "y"           => Y,
      #       "country"     => Country,
      #       "skin"        => Skin,
      #     }
      #   }
      def parseTargets(section)
        targets = Hash.new
        @fields[section].each do |target|
          targets[target[0].to_i] = {
            "name"        => target[1],
            "experience"  => target[2].to_i,
            "x"           => target[3].to_i,
            "y"           => target[4].to_i,
            "country"     => target[5].to_i,
            "skin"        => target[6].to_i,
          }
        end
        return targets
      end

      ##
      # Parses bonuses:
      #   section = Section index
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "amount"  => Credits amount,
      #       "x"       => X,
      #       "y"       => Y,
      #     }
      #   }
      def parseBonuses(section)
        bonuses = Hash.new
        @fields[section].each do |bonus|
          bonuses[bonus[0].to_i] = {
            "amount" => bonus[2].to_i,
            "x" => bonus[3].to_i,
            "y" => bonus[4].to_i,
          }
        end
        return bonuses
      end

      ##
      # Parses goals:
      #   section = Section index
      #
      #   Fields in format:
      #     ID1,Type1,Credits1,Finished1;ID1,Type2,Credits2,Finished2;ID3,Type3,Credits3,Finished3;
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "type"      => Type,
      #       "credits"   => Credits,
      #       "finished"  => Finished,
      #     }
      #   }
      def parseGoals(section)
        goals = Hash.new
        @fields[section].each do |goal|
          goals[goal[0].to_i] = {
            "type"      => goal[1],
            "credits"   => goal[2].to_i,
            "finished"  => goal[3].to_i,
          }
        end
        return goals
      end

      ##
      # Parses programs list:
      #   section = Section index
      #
      #   Fields in format:
      #     ID,PlayerID,Type,Level,Amount,Timer;
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "type"   => Type,
      #       "level"  => Level,
      #       "amount" => Amount,
      #       "Timer"  => Timer,
      #     }
      #   }
      def parsePrograms(section)
        programs = Hash.new
        @fields[section].each do |program|
          programs[program[0].to_i] = {
            "type"    => program[2].to_i,
            "level"   => program[3].to_i,
            "amount"  => program[4].to_i,
            "timer"   => program[5].to_i,
          }
        end
        return programs
      end

      ##
      # Returns programs as a string in the format:
      #
      #   type1,amount1;type2,amount2;type3,amount3;
      def self.generatePrograms(programs)
        data = String.new
        programs.each do |type, amount|
          data += "#{type},#{amount};"
        end
        return data
      end

      ##
      # Parses programs queue:
      #   section = Section index
      #
      #   Fields in format:
      #     Type1,Amount1,Timer1;Type2,Amount2,Timer2;Type3,Amount3,Timer3;
      #
      # Returns array:
      #   [
      #     {
      #       "type"    => Type,
      #       "amount"  => Amount,
      #       "timer"   => Timer,
      #     }
      #   ]
      def parseQueue(section)
        queue = Array.new
        @fields[section].each do |q|
          queue.push(
            {
              "type" => q[0].to_i,
              "amount" => q[1].to_i,
              "timer" => q[2].to_i,
            }
          )
        end
        return queue
      end

      ##
      # Parses missions log:
      #   section = Section index
      #
      #   Fields in format:
      #     PlayerID,MissionID,Money,Bitcoins,Finished,Datetime,Unknown,NodesCurrencies;
      #
      # Returns hash:
      #   {
      #     MissionID => {
      #       "money"       => Money,
      #       "bitcoins"    => Bitcoins,
      #       "finished"    => Finished,
      #       "datetime"    => Datetime,
      #       "currencies"  => NodesCurrencies,
      #     }
      #   }
      def parseMissionsLog(section)
        log = Hash.new
        return log if @fields[section].nil?
        @fields[section].each_with_index do |field, i|
          log[field[1].to_i] = {
            "money"       => field[2].to_i,
            "bitcoins"    => field[3].to_i,
            "finished"    => field[4].to_i,
            "datetime"    => field[5],
            "currencies"  => parseMissionCurrencies(section, i, 7),
          }
        end
        return log
      end

      ##
      # Parses mission nodes currencies:
      #   section = Section index
      #   record  = Record index
      #   field   = Field index
      #
      #   Fields in format:
      #     nodeid1Xamount1Ynodeid2Xamount2Ynodeid3Xamount3
      #
      # Returns hash:
      #   {
      #     nodeid => amount,
      #   }
      def parseMissionCurrencies(section, record, field)
        currencies = Hash.new
        return currencies if @fields[section][record][field].nil?
        @fields[section][record][field].split("Y").each do |node|
          id, amount = node.split("X")
          currencies[id.to_i] = amount.to_i
        end
        return currencies
      end

      def self.generateMissionCurrencies(currencies)
        currencies.map {|k, v| "#{k}X#{v}"}.join("Y")
      end

      def self.generateMissionPrograms(programs)
        programs.map {|k, v| "#{v["type"]},#{v["amount"]};"}.join
      end

      ##
      # Parses fight map:
      #   section = Section index
      #
      #   Fields in format:
      #     ID,X1,Y1,X2,Y2;
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "x1" => X1,
      #       "y1" => Y1,
      #       "x2" => X2,
      #       "y2" => Y2,
      #     }
      #   }
      def parseFightMap(section)
        map = Hash.new
        @fields[section].each do |field|
          map[field[0].to_i] = {
            "x1" => field[1].to_i,
            "y1" => field[2].to_i,
            "x2" => field[3].to_i,
            "y2" => field[4].to_i,
          }
        end
        return map
      end

      ##
      # Parses authentication by ID and password
      #
      # Returns a hash:
      #   {
      #     "id"          => ID,
      #     "password"    => Password,
      #     "sid"         => Session ID,
      #     "experience"  => Experience,
      #     "goals"       => Goals,
      #     "missions"    => Missions log,
      #   }
      def parseAuthIdPassword
        data = {
          "id"          => @fields[0][0][0].to_i,
          "password"    => @fields[0][0][1],
          "sid"         => @fields[0][0][3],
          "experience"  => @fields[0][0][5].to_i,
          "goals"       => parseGoals(1),
          "missions"    => parseMissionsLog(2),
        }
        return data
      end

      ##
      # Parses new created account
      #
      # Returns hash:
      #   {
      #     "id"        => ID,
      #     "password"  => Password,
      #     "sid"       => Session ID,
      #   }
      def parsePlayerCreate
        data = Hash.new
        data["id"] = @fields[0][0][0].to_i
        data["password"] = @fields[0][0][1]
        data["sid"] = @fields[0][0][2]
        return data
      end

      ##
      # Parses player network
      #
      # Returns hash:
      #   {
      #     "nodes"     => Serializer#parseNodes,
      #     "net"       => Serializer#parseNetwork,
      #     "profile"   => *Profile*,
      #     "programs"  => Serializer#parsePrograms,
      #     "queue"     => Serializer#parseQueue,
      #     "rank"      => Rank,
      #     "logs"      => Serializer#parseLogs,
      #     "time"      => Time,
      #     "readme"    => *Readme*,
      #   }
      def parseNetGetForMaint
        data = Hash.new
        data["nodes"] = parseNodes(0)
        data["net"] = parseNetwork(1, 0, 1)
        data["profile"] = parseProfile(2, 0)
        data["programs"] = parsePrograms(3)
        data["queue"] = parseQueue(4)
        data["rank"] = @fields.dig(7, 0, 0).to_i
        data["logs"] = parseLogs(9)
        data["time"] = @fields.dig(10, 0, 0)
        data["readme"] = parseReadme(11, 0, 0)
        return data
      end

      ##
      # Parses collected node resources
      #
      # Returns a hash containing currency data:
      #   {
      #     "currency"  => Currency ID,
      #     "amount"    => Amount,
      #   }
      def parseCollectNode
        data = {
          "currency"  => @fields[0][0][0],
          "amount"    => @fields[0][0][1],
        }
        return data
      end

      ##
      # Parses edited programs
      #
      # Returns hash:
      #   {
      #     Type1 => Amount1,
      #     Type2 => Amount2,
      #     Type3 => Amount3,
      #     ...
      #   }
      def parseDeleteProgram
        data = Hash.new
        @fields[0].each do |f|
          data[f[0].to_i] = {
            "amount" => f[1].to_i,
          }
        end
        return data
      end

      ##
      # Parses programs queue synchronization
      #
      # Returns hash:
      #   {
      #     "programs"  => Serializer#parsePrograms,
      #     "queue"     => Serializer#parseQueue,
      #     "bitcoins"  => Bitcoins,
      #   }
      def parseQueueSync
        data = Hash.new
        data["programs"] = parsePrograms(0)
        data["queue"] = parseQueue(1)
        data["bitcoins"] = @fields[2][0][0].to_i
        return data
      end

      ##
      # Parses player world
      #
      # Returns hash:
      #   {
      #     "targets"   => Targets,
      #     "bonuses"   => Bonuses,
      #     "money"     => Money,
      #     "goals"     => Goals,
      #     "best"      => [
      #       "id"          => ID,
      #       "name"        => Name,
      #       "experience"  => Experience,
      #       "country"     => Country,
      #       "rank"        => Rank,
      #     ],
      #     "map"       => Fight map,
      #     "players"   => [
      #       "profile"   => *Profile*,
      #       "nodes"     => Nodes,
      #     ]
      #   }
      def parsePlayerWorld
        data = Hash.new

        data["targets"] = parseTargets(0)
        data["bonuses"] = parseBonuses(1)
        data["money"] = @fields.dig(2, 0, 0).to_i
        data["goals"] = parseGoals(4)

        data["best"] = {
          "id"          => @fields[6][0][0].to_i,
          "name"        => @fields[6][0][1],
          "experience"  => @fields[6][0][2].to_i,
          "country"     => @fields[6][0][3].to_i,
          "rank"        => @fields[6][0][4].to_i,
        }

        data["map"] = parseFightMap(9)

        data["players"] = Array.new
        data["targets"].length.times do |i|
          data["players"] << {
            "profile"   => parseProfile(10 + i, 0),
            "nodes"     => parseNodes(10 + i + 1),
          }
        end
        
        return data
      end

      ##
      # Parses new targets
      #
      # Returns hash:
      #   {
      #     "targets"   => Targets,
      #     "bonuses"   => Bonuses,
      #     "money"     => Money,
      #     "goals"     => Goals,
      #   }
      def parseGetNewTargets
        data = Hash.new
        data["targets"] = parseTargets(0)
        data["bonuses"] = parseBonuses(1)
        data["money"] = @fields.dig(2, 0, 0)
        data["goals"] = parseGoals(4)
        return data
      end

      ##
      # Parses goal update
      #
      # Returns hash:
      #   {
      #     "status"   => Status,
      #     "credits"  => Credits,
      #   }
      def parseGoalUpdate
        data = {
          "status"   => @fields[0][0][0],
          "credits"  => @fields[0][0][1],
        }
        return data
      end

      ##
      # Parses chat messages
      #
      # Returns array:
      #   [
      #     *ChatMessage*,
      #     *ChatMessage*,
      #     *ChatMessage*,
      #     ...
      #   ]
      def parseChat
        messages = Array.new
        unless @fields.empty?
          @fields[0].each do |message|
            messages << ChatMessage.new(
              message[0],
              message[1],
              self.class.normalizeData(message[2]),
              message[3].to_i,
              message[4].to_i,
              message[5].to_i,
              message[6].to_i,
            )
          end
        end
        return messages.reverse
      end

      ##
      # Parses target network
      #
      # Returns hash:
      #   {
      #     "nodes"    => Serializer#parseNodes,
      #     "net"      => Serializer#parseNetwork,
      #     "profile"  => *Profile*,
      #     "readme"   => *Readme*,
      #   }
      def parseNetGetForAttack
        data = {
          "nodes"    => parseNodes(0),
          "net"      => parseNetwork(1, 0, 1),
          "profile"  => parseProfile(2, 0),
          "readme"   => parseReadme(4, 0, 0),
        }
        return data
      end

      ##
      # Parses replay
      #   section = Section index
      #   record  = Record index
      #   field   = Field index
      #
      # Returns hash:
      #   {
      #     "nodes"     => Serializer#parseNodes,
      #     "net"       => Serializer#parseNetwork,
      #     "profiles"  => {
      #       "target"    => *Profile*,
      #       "attacker"  => *Profile*,
      #     },
      #     "programs"  => Serializer#parseReplayPrograms,
      #     "trace"  => Serializer#parseReplayTrace,
      #   }
      def parseReplay(section, record, field)
        serializer = Serializer.new(@fields[section][record][field], DELIM_NORM_SECTION, DELIM_NORM_RECORD, DELIM_NORM_FIELD)
        replay = {
          "nodes"     => serializer.parseNodes(0),
          "net"       => serializer.parseNetwork(1, 0, 1),
          "profiles"  => {
            "target"    => serializer.parseProfile(2, 0),
            "attacker"  => serializer.parseProfile(4, 0),
          },
          "programs"  => serializer.parseReplayPrograms(3),
          "trace"     => serializer.parseReplayTrace(5),
        }
        return replay
      end

      ##
      # Parses mission fight
      #
      # Returns hash:
      #   {
      #     "nodes"     => Nodes,
      #     "net"       => Network,
      #     "programs"  => Programs,
      #     "profile"   => Profile,
      #   }
      def parseGetMissionFight
        data = {
          "nodes"     => Serializer.new(Serializer.normalizeData(@fields[0][0][0])).parseNodes(0),
          "net"       => parseNetwork(1, 0, 0),
          "programs"  => parsePrograms(3),
          "profile"   => parseProfile(4, 0),
        }
        return data
      end

      ##
      # Parses skin types
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "name"   => Name,
      #       "price"  => Price,
      #       "rank"   => Rank,
      #     }
      #   }
      def parseSkinTypes
        data = Hash.new
        @fields[0].each do |field|
          data[field[0]] = {
            "name"  => field[1],
            "price" => field[2].to_i,
            "rank"  => field[3].to_i,
          }
        end
        return data
      end

      ##
      # Parses ranking
      #
      # Returns hash:
      #   {
      #     "nearby"    => [
      #       "id"          => ID,
      #       "name"        => Name,
      #       "experience"  => Experience,
      #       "country"     => Country,
      #       "rank"        => Rank,
      #     ],
      #     "country"   => [
      #       ...
      #     ],
      #     "world"     => [
      #       ...
      #     ],
      #     "countries" => {
      #       "country"   => Country ID,
      #       "rank"      => Rank,
      #     },
      #   }
      def parseRankingGetAll
        data = {
          "nearby"    => [],
          "country"   => [],
          "world"     => [],
          "countries" => [],
        }

        for i in 0..2 do
          case i
          when 0
            type = "nearby"
          when 1
            type = "country"
          when 2
            type = "world"
          end
          
          @fields[i].each do |field|
            data[type].push({
              "id"          => field[0],
              "name"        => field[1],
              "experience"  => field[2],
              "country"     => field[3],
              "rank"        => field[4],
            })
          end
        end

        @fields[3].each do |field|
            data["countries"].push({
              "country" => field[0],
              "rank"    => field[1],
            })
          end
                
        return data
      end

      ##
      # Parses news list
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "date"   => Date,
      #       "title"  => Title,
      #       "body"   => Body,
      #     }
      #   }
      def parseNewsList
        data = Hash.new
        @fields[0].each do |field|
          data[field[0]] = {
            "date"  => field[1],
            "title" => self.class.normalizeData(field[2]),
            "body"  => self.class.normalizeData(field[3]),
          }
        end
        return data
      end

      ##
      # Parses hints list
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "description" => Description,
      #     }
      #   }
      def parseHintsList
        data = Hash.new
        @fields[0].each do |field|
          data[field[0].to_i] = {
              "description" => field[1],
            }
        end
        return data
      end

      ##
      # Parses experience list
      #
      # Return hash:
      #   {
      #     ID => {
      #       "level"       => Level,
      #       "experience"  => Experience,
      #     }
      #   }
      def parseExperienceList
        data = Hash.new
        @fields[0].each do |field|
          data[field[0].to_i] = {
            "level"       => field[1].to_i,
            "experience"  => field[2].to_i,
          }
        end
        return data
      end

      ##
      # Parses buidlers list
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "amount"  => Amount,
      #       "price"   => Price,
      #     }
      #   }
      def parseBuildersList
        data = Hash.new
        @fields[0].each do |field|
          data[field[0].to_i] = {
              "amount"  => field[0].to_i,
              "price"   => field[1].to_i,
            }
        end
        return data
      end

      ##
      # Parses goals types list
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "amount"       => Amount,
      #       "name"         => Name,
      #       "description"  => Description,
      #     }
      #   }
      def parseGoalsTypes
        data = Hash.new
        @fields[0].each do |field|
          data[field[1]] = {
            "amount"       => field[2].to_i,
            "name"         => field[7],
            "description"  => field[8],
          }
        end
        return data
      end

      ##
      # Parses shield types list
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "price"        => Price,
      #       "name"         => Name,
      #       "description"  => Description,
      #     }
      #   }
      def parseShieldTypes
        data = Hash.new
        @fields[0].each do |field|
          data[field[0].to_i] = {
              "price"       => field[3].to_i,
              "name"        => field[4],
              "description" => field[5],
            }
        end
        return data
      end

      ##
      # Parses rank list
      #
      # Returns hash:
      #   {
      #     ID => {
      #       "rank" => Rank,
      #     }
      #   }
      def parseRankList
        data = Hash.new
        @fields[0].each do |field|
          data[field[0].to_i] = {
            "rank" => field[1].to_i,
          }
        end
        return data
      end

      ##
      # Parses CP (change platform) code
      #
      # Return hash:
      #   {
      #     "id"        => ID,
      #     "password"  => Password,
      #   }
      def parseCpUseCode
        data = {
          "id"        => @fields[0][0][0],
          "password"  => @fields[0][0][1],
        }
        return data
      end

      ##
      # Parses generated CP (change platform) code
      #
      # Return code as a string
      def parseCpGenerateCode
        return @fields[0][0][0]
      end

      ##
      # Parses player statistics
      #
      # Returns hash:
      #   {
      #     "rank"          => Rank,
      #     "experience"    => Experience,
      #     "hacks"         => {
      #       "success" => Successful,
      #       "fail"    => Failed,
      #     },
      #     "defense"       => {
      #       "success" => Successful,
      #       "fail"    => Failed,
      #     },
      #     "loot"          => {
      #       "money"     => Money,
      #       "bitcoins"  => Bitcoins,
      #     },
      #     "collect"       => {
      #       "money"     => Money,
      #       "bitcoins"  => Bitcoins,
      #     },
      #   }
      def parsePlayerGetStats
        stats = {
          "rank"          => @fields[0][0][0].to_i,
          "experience"    => @fields[0][0][1].to_i,
          "hacks"         => {
            "success"  => @fields[0][0][2].to_i,
            "fail"     => @fields[0][0][3].to_i,
          },
          "defense"       => {
            "success"  => @fields[0][0][4].to_i,
            "fail"     => @fields[0][0][5].to_i,
          },
          "loot"          => {
            "money"     => @fields[0][0][7].to_i,
            "bitcoins"  => @fields[0][0][9].to_i,
          },
          "collect"       => {
            "money"     => @fields[0][0][6].to_i,
            "bitcoins"  => @fields[0][0][8].to_i,
          },
        }
        return stats
      end
    end
  end
end

