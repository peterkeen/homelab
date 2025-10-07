require 'sinatra/base'

module AdsbBubble
  class Web < ::Sinatra::Base

    set :host_authorization, { permitted_hosts: [] }

    before do
      content_type 'application/json'
    end
    
    get '/' do
      "hello"
    end

    get '/aircraft.json' do
      aircraft = settings.tracker.aircraft.map(&:serialize)

      {
        aircraft: aircraft
      }.to_json
    end

    get '/in_bubble.json' do
      aircraft = settings.tracker.in_bubble.map(&:serialize)

      {
        aircraft: aircraft
      }.to_json      
    end

  end
end
