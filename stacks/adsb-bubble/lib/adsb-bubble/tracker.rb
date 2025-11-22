require 'fast_jsonparser'
require 'faraday'

module AdsbBubble
  class Tracker
    attr_reader :aircraft

    def initialize
      @aircraft = []
      @recently_in_bubble = {}
      @arrival_hooks = []
      @mutex = Mutex.new
      @thread = nil
      @should_stop = false
    end

    def in_bubble
      @mutex.synchronize do
        unsafe_in_bubble
      end
    end

    def start!
      @thread = Thread.new do
        loop do
          break if @should_stop
          refresh!
          sleep(1)
        end
      end
      nil
    end

    def join!
      @thread&.join
    end

    def stop!
      @should_stop = true
    end

    def on_arrival(&block)
      @mutex.synchronize do
        @arrival_hooks << block
      end
    end

    private

    attr_reader :recently_in_bubble

    def refresh!
      @mutex.synchronize do
        resp = begin
          connection.get('/data/aircraft.json')
        rescue => e
          warn "connection error! skipping refresh: #{e}"
          nil
        end

        return if resp.nil?

        @aircraft = FastJsonparser.parse(resp.body, symbolize_keys: false)["aircraft"].map { |a| Aircraft.from_hash(a) }

        unsafe_in_bubble.each do |ac|
          unless recently_in_bubble[ac.hex]
            run_arrival_hooks(ac)
          end

          recently_in_bubble[ac.hex] = Time.now.to_i
        end

        clean_up_recent!
      end
    end

    def connection
      Faraday.new(url: "https://ultrafeeder.keen.land") do |conn|
        conn.options.open_timeout = 1
        conn.options.timeout = 1
      end
    end

    def unsafe_in_bubble
      @aircraft.select(&:in_bubble?)
    end

    def clean_up_recent!
      @recently_in_bubble = recently_in_bubble.filter_map do |hex, timestamp|
        if timestamp + (10 * 60) > Time.now.to_i
          [hex, timestamp]
        else
          nil
        end
      end.to_h
    end

    def run_arrival_hooks(ac)
      @arrival_hooks.each do |hook|
        hook.call(ac)
      end
    end
  end
end
