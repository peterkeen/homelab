require 'faraday'

module AdsbBubble
  class Notify
    def self.notify(subject:, message:)
      Faraday.post(
        "https://hass.keen.land/api/services/notify/pete_email",
        {
          message: message,
          title: subject,
        }.to_json,
        {
          "Content-type": "application/json",
          "Authorization": "Bearer #{ENV['HASS_API_KEY']}",
        }
      )
    end
  end
end
