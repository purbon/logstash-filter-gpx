# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "logstash/json"
require "logstash/timestamp"

require_relative "gpx/gpx_parser"
require_relative "gpx/tcx_parser"

class LogStash::Filters::Gpx < LogStash::Filters::Base

  config_name "gpx"

  # The configuration for the GPX filter:
  # [source,ruby]
  #     source => source_field
  #
  # For example, if you have GPX data in the @message field:
  # [source,ruby]
  #     filter {
  #       gpx {
  #         source => "message"
  #       }
  #     }
  #
  # The above would parse the gpx from the @message field
  config :source, :validate => :string, :required => true

  # Define the target field for placing the parsed data. If this setting is
  # omitted, the GPX data will be stored at the root (top level) of the event.
  #
  # For example, if you want the data to be put in the `doc` field:
  # [source,ruby]
  #     filter {
  #       gpx {
  #         target => "doc"
  #       }
  #     }
  #
  # NOTE: if the `target` field already exists, it will be overwritten!
  config :target, :validate => :string


  config :document_type, :validate => :string, :default => "gpx"

  def register
    # Nothing to do here
  end # def register


  def dump_gpx(source)
    gpx = Guppy::GpxParser.load(source)
    hash_dump = { "activities" => [] }
    gpx.activities.each do |_activity|
      total_time = 0
      activity   = { "distance" => _activity.distance, "laps" => [] }
      _activity.laps.each do |_lap|
        total_time += _lap.time.to_i
        lap = { "distance" => _lap.distance,
                "time_in_sec" => _lap.time.to_i,
                "start_time"  => _lap.track_points.first.time.to_s,
                "finish_time" => _lap.track_points.last.time.to_s,
                "speed"       => ((_lap.time.to_f/60)/(_lap.distance.to_f/1000))
        }
        lap["points"] = _lap.track_points.map do |track|
          [track.latitude, track.longitude]
        end
        activity["laps"] << lap
      end
      activity["time"] = total_time
      hash_dump["activities"] << activity
    end
    hash_dump["@timestamp"] = LogStash::Timestamp.at(gpx.activities.first.laps.first.track_points.first.time.to_i)
    hash_dump
  end

  def dump_tcx(source)
    tcx = Guppy::TcxParser.load(source)
    hash_dump = { "activities" => [] }
    total_time = 0
    location   = []
    tcx.activities.each do |_activity|
      activity = { "distance" => _activity.distance,
                   "sport"    => _activity.sport,
                   "date"     => _activity.date.to_i,
                   "laps"     => [] }
      i=0
      _activity.laps.each do |_lap|
        next if _lap.distance.to_f == 0
        total_time += _lap.time.to_i
        lap = { "distance"    => _lap.distance.to_f,
                "max_speed"   => _lap.max_speed.to_f,
                "calories"    => _lap.calories,
                "time_in_sec" => _lap.time.to_i,
                "pace"        => (((_lap.time.to_i)/60.0)/(_lap.distance.to_f/1000)).to_f,
                "speed"       => (_lap.distance.to_f/1000)/(_lap.time.to_f/3600),
                "id"          => i
        }
        if _lap.track_points.count > 0
          start_time         = _lap.track_points.first.time
          lap["start_time"]  = start_time.to_i
          lap["finish_time"] = _lap.track_points.last.time.to_i
        end
        last_altitude_point = 0.0
        lap["points"] = _lap.track_points.map do |track|
          m    = { "coordinates" => [track.longitude, track.latitude],
                   "altitude"    => track.altitude.to_f,
                   "time"        => track.time.to_i-start_time.to_i,
                   "increase"    => track.altitude.to_f-last_altitude_point }
          last_altitude_point = track.altitude.to_f
          m
        end
        location = lap["points"].first["coordinates"] if location.empty? && (_lap.track_points.count > 0)
        activity["laps"] << lap
        i+=1
      end
      activity["time"]  = total_time
      activity["pace"]  = (activity["time"].to_f/60)/(activity["distance"].to_f/1000)
      activity["speed"] = (activity["distance"].to_f/1000)/(activity["time"].to_f/3600)
      hash_dump["activities"] << activity
    end
    hash_dump["@timestamp"] = LogStash::Timestamp.at(tcx.activities.first.date.to_i)
    hash_dump["@location"]  = location
    hash_dump
  end

  def filter(event)
    return unless filter?(event)

    @logger.debug("Running GPX filter", :event => event)

    return unless event.include?(@source)

    source = event[@source]

    begin
      if @document_type.to_s == "tcx"
        hash_dump = dump_tcx(source)
      else
        hash_dump = dump_gpx(source)
      end
      event["@timestamp"] = hash_dump.delete("@timestamp")
      event["geoip"] = { "location" => hash_dump.delete("@location") }
      if @target
        event[@target] = hash_dump.clone
      else
        # we should iterate the message over the
        # original message
        hash_dump.each_pair do |k,v|
          event[k] = v
        end
      end

      filter_matched(event)
    rescue => e
      add_failure_tag(event)
      @logger.warn("Trouble parsing json", :source => @source,
                   :raw => event[@source], :exception => e)
      return
    end

    @logger.debug("Event after gpx filter", :event => event)

  end

  private

  def add_failure_tag(event)
    tag = "_gpxnparsefailure"
    event["tags"] ||= []
    event["tags"] << tag unless event["tags"].include?(tag)
  end
  def select_dest(event)
    if @target == @source
      dest = event[@target] = {}
    else
      dest = event[@target] ||= {}
    end
    return dest
  end
end # class LogStash::Filters::Json
