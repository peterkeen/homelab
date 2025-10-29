#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
Bundler.require(:default)

$LOAD_PATH.unshift File.expand_path(".", "lib")

require "./lib/adsb-bubble"

tracker = AdsbBubble::Tracker.new

tracker.on_arrival do |aircraft|
  warn "new aircraft: #{aircraft.serialize.to_json}"
end

tracker.on_arrival do |aircraft|
  message = <<~HERE
    #{aircraft.r} #{aircraft.desc} #{aircraft.flight}

    Altitude: #{aircraft.alt_baro}

    Owner: #{aircraft.ownOp}

    https://ultrafeeder.keen.land/?icao=#{aircraft.hex}
  HERE

  AdsbBubble::Notify.notify(
    message: message,
    subject: "ADSB Alert"
  )
end

tracker.start!

web_thread = Thread.new do
  AdsbBubble::Web.run!(tracker: tracker, bind: '0.0.0.0')
end

web_thread.join
tracker.stop!
tracker.join!
