require 'yaml'
require_relative './host'
require_relative './tailscale'

class HostsFile
  attr_reader :path
  attr_reader :defaults
  attr_reader :hosts

  def initialize(path: nil)
    root_path = File.expand_path(File.join(__FILE__, '../..'))
    @path = path || File.join(root_path, 'hosts.yml')
    @raw = YAML.safe_load_file(@path, symbolize_names: true)
  end

  def root_path
    File.dirname(@path)
  end

  def defaults
    @raw[:defaults]
  end

  def hosts
    @hosts ||= @raw[:hosts].map do |hostname, config| 
      values = defaults.merge(config) do |key, old, new|
        if old.is_a?(Array)
          old + new
        else
          new
        end
      end

      values[:hostname] = hostname
      values[:tailnet_ip] = Tailscale.addresses[hostname.to_s]      

      [hostname.to_s, Host.new(**values)] 
    end.to_h
  end
end
