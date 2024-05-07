require 'json'
require_relative './ds_logger'
require_relative './secrets'

class Tailscale
  def self.load_all!
    return @addresses if defined? @addresses

    LOGGER.info('Tailscale.load_all!')

    status_json = `tailscale status --json`

    @addresses = JSON.parse(status_json)["Peer"]
                   .map { |_, peer| [peer["HostName"], peer["TailscaleIPs"][0]] }
                   .to_h
  end

  def self.auth_key!
    return @auth_key if defined? @auth_key

    LOGGER.info('Tailscale.auth_key!')    

    secrets = Secrets.load_all!
    
    ENV['TS_API_CLIENT_ID'] = oauth_client_id = secrets.values.first['TS_API_CLIENT_ID']
    ENV['TS_API_CLIENT_SECRET'] = secrets.values.first['TS_API_CLIENT_SECRET']

    @auth_key = `get-authkey -reusable -tags tag:server`
  end
end
