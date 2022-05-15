require 'yaml'
require 'base64'

require 'hackers'

NODE_TYPES_DATA = 'spec/data/node_types.yml'

data = YAML.safe_load(File.read(NODE_TYPES_DATA))
raw_data = Base64.decode64(data['raw_data'])

RSpec.describe Hackers::NodeTypes do
  api = Hackers::API.new
  node_types = described_class::List.new(api)
  node_types.raw_data = raw_data
  node_types.send(:parse)

  data['nodes'].each do |k, v|
    it "Type #{k}" do
      expect(node_types.send(k.to_sym).type).to eq(v['type'])
    end

    it "Name #{k}" do
      expect(node_types.send(k.to_sym).name).to eq(v['name'])
    end

    it "Levels #{k}" do
      expect(node_types.send(k.to_sym).levels.length).to eq(v['levels'])
    end

    it "Upgrade currency #{k}" do
      node_types.send(k.to_sym).levels.each do |level|
        expect(node_types.send(k.to_sym).upgrade_currency(level)).to eq(v['upgrade_currency'])
      end
    end

    it "Required core level #{k}" do
      next unless v.key?('required_core_level')

      next if k == 'core'

      v['required_core_level'].each do |level, core_level|
        expect(node_types.send(k.to_sym).required_core_level(level)).to eq(core_level)
      end
    end

    it "Upgrade cost #{k}" do
      next unless v.key?('upgrade_cost')

      v['upgrade_cost'].each do |level, cost|
        expect(node_types.send(k.to_sym).upgrade_cost(level)).to eq(cost)
      end
    end

    it "Experience gained #{k}" do
      next unless v.key?('experience_gained')

      v['experience_gained'].each do |level, exp|
        expect(node_types.send(k.to_sym).experience_gained(level)).to eq(exp)
      end
    end

    it "Completion time #{k}" do
      next unless v.key?('completion_time')

      v['completion_time'].each do |level, time|
        expect(node_types.send(k.to_sym).completion_time(level)).to eq(time)
      end
    end

    it "Node connections #{k}" do
      next unless v.key?('node_connections')

      v['node_connections'].each do |level, amount|
        expect(node_types.send(k.to_sym).node_connections(level)).to eq(amount)
      end
    end

    it "Program slots #{k}" do
      next unless v.key?('program_slots')

      v['program_slots'].each do |level, amount|
        expect(node_types.send(k.to_sym).program_slots(level)).to eq(amount)
      end
    end

    it "Firewall #{k}" do
      next unless v.key?('firewall')

      v['firewall'].each do |level, value|
        expect(node_types.send(k.to_sym).firewall(level)).to eq(value)
      end
    end

    it "Limit #{k}" do
      next unless v.key?('limit')

      v['limit'].each do |core_level, amount|
        expect(node_types.send(k.to_sym).limit(core_level)).to eq(amount)
      end
    end

    it "Production currency #{k}" do
      next unless v.key?('production_currency')

      next unless node_types.send(k.to_sym).kind_of?(described_class::Production)

      v['production_currency'].each do |level, currency|
        expect(node_types.send(k.to_sym).production_currency(level)).to eq(currency)
      end
    end

    it "Production limit #{k}" do
      next unless v.key?('production_limit')

      next unless node_types.send(k.to_sym).kind_of?(described_class::Production)

      v['production_limit'].each do |level, limit|
        expect(node_types.send(k.to_sym).production_limit(level)).to eq(limit)
      end
    end

    it "Production speed #{k}" do
      next unless v.key?('production_speed')

      next unless node_types.send(k.to_sym).kind_of?(described_class::Production)

      v['production_speed'].each do |level, speed|
        expect(node_types.send(k.to_sym).production_speed(level)).to eq(speed)
      end
    end

    it "Exfiltration amount #{k}" do
      next unless v.key?('exfiltration_amount')

      next unless node_types.send(k.to_sym).kind_of?(described_class::Business)

      v['exfiltration_amount'].each do |level, amount|
        expect(node_types.send(k.to_sym).exfiltration_amount(level)).to eq(amount)
      end
    end
  end

  data['nodes']['core']['min_connections'].each do |k, v|
    it 'Minimum connections core' do
      expect(node_types.core.min_connections(k)).to eq(v)
    end
  end

  data['nodes']['core']['max_nodes'].each do |k, v|
    it 'Maximum nodes core' do
      expect(node_types.core.max_nodes(k)).to eq(v)
    end
  end
end
