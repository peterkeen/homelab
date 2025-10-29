require 'json'
require 'faraday'
require 'uri'
require 'subprocess'
require 'shellwords'

require_relative './ds_logger'
require_relative './secrets'

class Tailscale
  @authkeys_by_tags = {}

  def self.addresses
    return @@addresses if defined? @@addresses

    status_json = Subprocess.check_output(Shellwords.split("tailscale status --json"))

    @@addresses = JSON.parse(status_json)["Peer"]
                   .map { |_, peer| [peer["HostName"], peer["TailscaleIPs"][0]] }
                   .to_h
  end

  def self.authkey_for_tags(tags)
    tags = tags.dup.sort
    unless @authkeys_by_tags[tags].nil?
      return @authkeys_by_tags[tags]
    end

    LOGGER.info("Generating authkey for tags: #{tags}")

    resp = conn.post('/api/v2/tailnet/tailnet-a578.ts.net/keys') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{api_key}"
      req.body = {
        expirySeconds: 3600,
        capabilities: {
          devices: {
            create: {
              tags: tags,
              reusable: true,
              preauthorized: true
            }
          }
        }
      }.to_json
    end

    @authkeys_by_tags[tags] = resp.body['key']
  end

  private

  def self.api_key
    return @api_key if defined? @api_key

    secret = Secrets.instance.get("kndwf5beko2fibasfcrjahlvzi")

    resp = conn.post('/api/v2/oauth/token') do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        {
          "client_id" => secret['TS_API_CLIENT_ID'],
          "client_secret" => secret['TS_API_CLIENT_SECRET'],
        }
      )
    end

    @api_key = resp.body['access_token']
  end

  def self.conn
    @conn ||= Faraday.new('https://api.tailscale.com/') do |conn|
      conn.response :json, :content_type => /\bjson$/
      conn.response :raise_error
    end
  end
end
