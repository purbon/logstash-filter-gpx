# encoding: utf-8

module Guppy
  class TrackPoint
    attr_accessor :latitude
    attr_accessor :longitude
    attr_accessor :altitude
    attr_accessor :heart_rate
    attr_accessor :distance
    attr_accessor :time
    attr_accessor :speed
  end
end

module Guppy
  class Lap
    attr_accessor :distance
    attr_accessor :max_speed
    attr_accessor :time
    attr_accessor :calories
    attr_accessor :average_heart_rate
    attr_accessor :max_heart_rate
    attr_reader   :track_points

    def initialize
      @distance           = 0.0
      @max_speed          = 0.0
      @time               = 0.0
      @calories           = 0
      @average_heart_rate = 0
      @max_heart_rate     = 0
      @track_points       = []
    end

  end
end

module Guppy
  class Activity
    attr_accessor :sport
    attr_accessor :date
    attr_reader   :laps

    def initialize
      @laps = []
    end

    def distance
      laps.inject(0.0) { |sum, lap| sum + lap.distance }
    end
  end
end
