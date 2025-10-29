require 'fileutils'

require_relative './hosts_file'
require_relative './host_builder'
require_relative './composer'
require_relative './context'

class Runner
  attr_reader :hosts_file
  attr_reader :build_root
  attr_reader :hostname

  def initialize(hostname: nil)
    @hostname = hostname
    @hosts_file = HostsFile.new
    @build_root = File.join(hosts_file.root_path, "build")
  end

  def run
    FileUtils.rm_rf(build_root)

    hostnames = if hostname
      [hostname]
    else
      hosts_file.hosts.keys
    end

    hostnames.each do |hostname|
      run_one(hostname)
    end
  end

  def run_one(hostname)
    context = Context.new(hosts_file: hosts_file, hostname: hostname)
    HostBuilder.new(context: context, build_root: build_root).perform
    Composer.new(context: context, build_root: build_root).perform
  end
end
