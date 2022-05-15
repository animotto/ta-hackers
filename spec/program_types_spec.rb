require 'yaml'
require 'base64'

require 'hackers'

PROGRAM_TYPES_DATA = 'spec/data/program_types.yml'

data = YAML.safe_load(File.read(PROGRAM_TYPES_DATA))
raw_data = Base64.decode64(data['raw_data'])

RSpec.describe Hackers::ProgramTypes do
  api = Hackers::API.new
  program_types = described_class::List.new(api)
  program_types.raw_data = raw_data
  program_types.send(:parse)

  data['programs'].each do |k, v|
    it "Type #{k}" do
      expect(program_types.send(k.to_sym).type).to eq(v['type'])
    end

    it "Name #{k}" do
      expect(program_types.send(k.to_sym).name).to eq(v['name'])
    end

    it "Levels #{k}" do
      expect(program_types.send(k.to_sym).levels.length).to eq(v['levels'])
    end

    it "Upgrade cost #{k}" do
      next unless v.key?('upgrade_cost')

      v['upgrade_cost'].each do |level, cost|
        expect(program_types.send(k.to_sym).upgrade_cost(level)).to eq(cost)
      end
    end

    it "Experience gained #{k}" do
      next unless v.key?('experience_gained')

      v['experience_gained'].each do |level, exp|
        expect(program_types.send(k.to_sym).experience_gained(level)).to eq(exp)
      end
    end

    it "Compilation price #{k}" do
      next unless v.key?('compilation_price')

      v['compilation_price'].each do |level, price|
        expect(program_types.send(k.to_sym).compilation_price(level)).to eq(price)
      end
    end

    it "Compilation time #{k}" do
      next unless v.key?('compilation_time')

      v['compilation_time'].each do |level, time|
        expect(program_types.send(k.to_sym).compilation_time(level)).to eq(time)
      end
    end

    it "Disk space #{k}" do
      next unless v.key?('disk_space')

      v['disk_space'].each do |level, value|
        expect(program_types.send(k.to_sym).disk_space(level)).to eq(value)
      end
    end

    it "Install time #{k}" do
      next unless v.key?('install_time')

      v['install_time'].each do |level, time|
        expect(program_types.send(k.to_sym).install_time(level)).to eq(time)
      end
    end

    it "Research time #{k}" do
      next unless v.key?('research_time')

      v['research_time'].each do |level, time|
        expect(program_types.send(k.to_sym).research_time(level)).to eq(time)
      end
    end

    it "Required evolver level #{k}" do
      next unless v.key?('required_evolver_level')

      v['required_evolver_level'].each do |level, evolver_level|
        expect(program_types.send(k.to_sym).required_evolver_level(level)).to eq(evolver_level)
      end
    end

    it "Attack speed #{k}" do
      next unless v.key?('attack_speed')

      v['attack_speed'].each do |level, speed|
        expect(program_types.send(k.to_sym).attack_speed(level)).to eq(speed)
      end
    end

    it "Strength #{k}" do
      next unless v.key?('strength')

      v['strength'].each do |level, strength|
        expect(program_types.send(k.to_sym).strength(level)).to eq(strength)
      end
    end

    it "Buffer #{k}" do
      next unless v.key?('buffer')

      v['buffer'].each do |level, buffer|
        expect(program_types.send(k.to_sym).buffer(level)).to eq(buffer)
      end
    end

    it "Visibility #{k}" do
      next unless v.key?('visibility')

      v['visibility'].each do |level, value|
        expect(program_types.send(k.to_sym).visibility(level)).to eq(value)
      end
    end

    it "Download boost #{k}" do
      next unless v.key?('download_boost')

      v['download_boost'].each do |level, value|
        expect(program_types.send(k.to_sym).download_boost(level)).to eq(value)
      end
    end
  end
end
