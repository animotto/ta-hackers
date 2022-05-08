# frozen_string_literal: true

require 'yaml'
require 'hackers-link'

SIMLINKS = 'spec/data/simlinks.yml'
REPLAYLINKS = 'spec/data/replaylinks.yml'
INVALID_LINKS = 'spec/data/invalid_links.yml'
INVALID_URI = 'spec/data/invalid_uri.yml'

invalid_links = YAML.safe_load(File.read(INVALID_LINKS))
invalid_uri = YAML.safe_load(File.read(INVALID_URI))

RSpec.describe Trickster::Hackers::SimLink do
  simlinks = YAML.safe_load(File.read(SIMLINKS))
  simlink = Trickster::Hackers::SimLink.new(0)

  it 'Parses URI of simulation link' do
    simlinks.each do |link|
      data = simlink.parse(link[0])
      expect(data[:value]).to eq(link[1])
    end

    invalid_links.each do |link|
      expect { simlink.parse(link) }.to raise_error(Trickster::Hackers::LinkParserError)
    end

    invalid_uri.each do |link|
      expect { simlink.parse(link) }.to raise_error(Trickster::Hackers::LinkParserError)
    end
  end
end

RSpec.describe Trickster::Hackers::ReplayLink do
  replaylinks = YAML.safe_load(File.read(REPLAYLINKS))
  replaylink = Trickster::Hackers::ReplayLink.new(0)

  it 'Parses URI of replay link' do
    replaylinks.each do |link|
      data = replaylink.parse(link[0])
      expect(data[:value]).to eq(link[1])
    end

    invalid_links.each do |link|
      expect { replaylink.parse(link) }.to raise_error(Trickster::Hackers::LinkParserError)
    end

    invalid_uri.each do |link|
      expect { replaylink.parse(link) }.to raise_error(Trickster::Hackers::LinkParserError)
    end
  end
end
