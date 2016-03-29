require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/gpx"
require "logstash/timestamp"


describe Guppy::GpxParser do

  let(:data) { File.read(File.join(File.dirname(__FILE__), "fixtures", "dump.gpx")) }
  subject    { Guppy::GpxParser.load(data) }


  it "parse without errors" do
    expect { described_class.load(data) }.not_to raise_error
  end

  context "#parse" do

    it "fetch the #activities" do
      expect(subject.activities.count).to eq(1)
    end

    context "foreach activity" do

      let(:activity) { subject.activities.first }

      it "fetch distance information" do
        expect(activity.distance).to eq(10527.0)
      end

      it "fetches the list of laps" do
        expect(activity.laps.count).to eq(1)
      end

      context "foreach lap" do

        let(:lap) { activity.laps.first }

        it "fetch distance information" do
          expect(lap.distance).to eq(10527.0)
        end

        it "fetch time information" do
          expect(lap.time).to eq(2953.55)
        end

        it "fetch trackpoints data" do
          expect(lap.track_points.count).to eq(2638)
        end

      end

    end

  end
end

describe LogStash::Filters::Gpx do

  let(:message) { File.read(File.join(File.dirname(__FILE__), "fixtures", "dump.gpx")) }
  let(:event)   { LogStash::Event.new("message" => message) }

  let(:config) { {"source" => "message"} }

  subject do
    described_class.new(config)
  end

  it "parses data without errors" do
    expect { subject.filter(event) }.not_to raise_error
  end

  it "extract the expected schema" do
    subject.filter(event)
    expect(event.to_hash).to include("activities")
    expect(event.to_hash["activities"][0]).to include("distance", "laps")
    expect(event.to_hash["activities"][0]["laps"][0]).to include("distance", "time_in_sec", "start_time", "finish_time", "speed", "points")
  end

  describe "using target" do

    let(:config) { {"source" => "message", "target" => "dest" } }

    it "adds the parsed element to target" do
      subject.filter(event)
      expect(event.to_hash.keys).to include("dest")
      expect(event.to_hash["dest"]).to include("activities")
    end

  end
end
