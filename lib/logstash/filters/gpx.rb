# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "logstash/json"
require "logstash/timestamp"

require_relative "gpx/gpx_parser"

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

  public
  def register
    # Nothing to do here
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running GPX filter", :event => event)

    return unless event.include?(@source)

    source = event[@source]

    begin
      gpx = Guppy::GpxParser.load(source)
      hash_dump = { "activities" => [] }
      gpx.activities.each do |_activity|
        activity = { "distance" => _activity.distance, "laps" => [] }
        _activity.laps.each do |_lap|
          lap = { "distance" => _lap.distance,
                  "time_in_sec" => _lap.time,
                  "start_time"  => _lap.track_points.first.time,
                  "finish_time" => _lap.track_points.last.time,
                  "speed"       => ((_lap.time.to_f/60)/(_lap.distance.to_f/1000))
          }
          lap["points"] = _lap.track_points.map do |track|
            [track.latitude, track.longitude]
          end
          activity["laps"] << lap
        end
        hash_dump["activities"] << activity
      end

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
