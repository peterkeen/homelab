require 'fileutils'
require 'deep_merge'

require_relative './hosts_file'
require_relative './host_builder'
require_relative './composer'
require_relative './context'
require_relative './hooks'
require_relative './ds_logger'

class Runner
  attr_reader :hosts_file
  attr_reader :build_root
  attr_reader :hostname
  attr_reader :groups
  attr_reader :hooks

  def initialize(hostname: nil, groups: nil)
    @hostname = hostname
    groups = ["development"] if groups.length == 0
    @groups = groups
    @hosts_file = HostsFile.new
    @build_root = File.join(hosts_file.root_path, "build")
    @hooks = Hooks.new
  end

  def run
    FileUtils.rm_rf(build_root)

    hostnames = if hostname
      [hostname]
    else
      hosts_file.hosts.values.select { |h| (h.groups & groups).length > 0 }.map(&:hostname)
    end

    if hostnames.length == 0
      LOGGER.fatal("Can't find hosts for given parameters. hostname: #{hostname}, groups: #{groups}")
    end

    LOGGER.info("Deploying groups #{groups}: #{hostnames}")

    hostnames.each do |hostname|
      run_one(hostname)
    end
  end

  def run_one(hostname)
    raise "Unknown hostname: #{hostname} not in hosts file" unless hosts_file.hosts.key?(hostname)
    context = Context.new(hosts_file: hosts_file, hostname: hostname, hooks: hooks)
    HostBuilder.new(context: context, build_root: build_root).perform
    Composer.new(context: context, build_root: build_root).perform
  end
end
