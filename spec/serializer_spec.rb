require "hackers-serializer"

include Trickster::Hackers

RSpec.describe Serializer do
  ##
  # Serializer#parseGoals
  describe "#parseGoals" do
    it "Raw data - nil" do
      serializer = Serializer.new(nil)
      expect(serializer.parseGoals(0)).to eq({})
      expect(serializer.parseGoals(1)).to eq({})
    end

    it "Raw data - empty" do
      serializer = Serializer.new("")
      expect(serializer.parseGoals(0)).to eq({})
      expect(serializer.parseGoals(1)).to eq({})
    end

    it "Raw data - empty sections and records" do
      serializer = Serializer.new(";@;;@@")
      expect(serializer.parseGoals(0)).to eq({})
      expect(serializer.parseGoals(1)).to eq({})
      expect(serializer.parseGoals(2)).to eq({})
    end

    it "Raw data - empty fields" do
      serializer = Serializer.new(",,,")
      expect(serializer.parseGoals(0)).to eq({
        0 => {
          "type"       => "",
          "credits"    => 0,
          "finished"   => 0,
        }
      })
    end

    it "Normal - 1 goal" do
      serializer = Serializer.new("353535,s_download_cores,5,0;")
      expect(serializer.parseGoals(0)).to eq({
        353535 => {
          "type"       => "s_download_cores",
          "credits"    => 5,
          "finished"   => 0,
        }
      })
    end

    it "Normal - 3 goals" do
      serializer = Serializer.new("4839489,write_readmes,3,1;41299391,earn_reputation,4,0;")
      expect(serializer.parseGoals(0)).to eq({
        4839489 => {
          "type"       => "write_readmes",
          "credits"    => 3,
          "finished"   => 1,
        },
        41299391 => {
          "type"       => "earn_reputation",
          "credits"    => 4,
          "finished"   => 0,
        }
      })
    end
  end

  ##
  # Serializer#parseQueue
  describe "#parseQueue" do
    it "Raw data - nil" do
      serializer = Serializer.new(nil)
      expect(serializer.parseQueue(0)).to eq([])
      expect(serializer.parseQueue(1)).to eq([])
    end

    it "Raw data - empty" do
      serializer = Serializer.new("")
      expect(serializer.parseQueue(0)).to eq([])
      expect(serializer.parseQueue(1)).to eq([])
    end

    it "Raw data - empty sections and records" do
      serializer = Serializer.new(";@;;@@")
      expect(serializer.parseQueue(0)).to eq([])
      expect(serializer.parseQueue(1)).to eq([])
      expect(serializer.parseQueue(2)).to eq([])
    end

    it "Raw data - empty fields" do
      serializer = Serializer.new(",,,")
      expect(serializer.parseQueue(0)).to eq([
        {
          "type"    => 0,
          "amount"  => 0,
          "timer"   => 0,
        }
      ])
    end

    it "Normal - 1 program" do
      serializer = Serializer.new("3,11,43;")
      expect(serializer.parseQueue(0)).to eq([
        {
          "type"    => 3,
          "amount"  => 11,
          "timer"   => 43,
        }
      ])
    end

    it "Normal - 3 programs" do
      serializer = Serializer.new("4,12,0;5,9,17;11,14,27;")
      expect(serializer.parseQueue(0)).to eq([
        {
          "type"    => 4,
          "amount"  => 12,
          "timer"   => 0,
        },
        {
          "type"    => 5,
          "amount"  => 9,
          "timer"   => 17,
        },
        {
          "type"    => 11,
          "amount"  => 14,
          "timer"   => 27,
        },
      ])
    end
  end
end

