# frozen_string_literal: true

require 'yaml'

require 'hackers/client'

CONFIG = 'spec/data/config.yml'
HASH_URI = 'spec/data/hash_uri.yml'

config = YAML.safe_load(File.read(CONFIG))
hash_uri = YAML.safe_load(File.read(HASH_URI))

RSpec.describe Hackers::Client do
  it 'Hashes the URI' do
    client = described_class.new(
      config['host'],
      config['port'],
      config['ssl'],
      config['uri'],
      config['salt']
    )

    hash_uri.each do |hash|
      expect(client.send(:hash_uri, hash[0])).to eq(hash[1])
    end
  end
end
