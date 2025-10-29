#!/usr/bin/env ruby

require 'time'

raw_start = `/bin/ps -eo lstart -q1`.split("\n").last
start = DateTime.parse(raw_start).to_time

if (Time.now - start) > 60*60*12
  exit 1
else
  exit 0
end
