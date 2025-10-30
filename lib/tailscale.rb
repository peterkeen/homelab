require 'json'
require 'subprocess'
require 'shellwords'

require_relative './ds_logger'

class Tailscale
  @authkeys_by_tags = {}

  def self.addresses
    return @@addresses if defined? @@addresses

    status_json = Subprocess.check_output(Shellwords.split("tailscale status --json"))

    @@addresses = JSON.parse(status_json)["Peer"]
                   .map { |_, peer| [peer["HostName"], peer["TailscaleIPs"][0]] }
                   .to_h
  end

end
