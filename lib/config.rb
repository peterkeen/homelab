#!/usr/bin/env ruby

require 'yaml'
require 'erb'
require 'sorbet-runtime'
require 'logger'
require_relative './secrets'
require_relative './tailscale'
require_relative './ds_logger'

class Stack < T::Struct
  const :name, String
  const :config, Hash

  def path
    "stacks/#{name}.yml"
  end
end

class Cron < T::Struct
  const :schedule, String
  const :service, String
end

class SerialPort < T::Struct
  const :path, String
  const :port, Integer
  const :baud, String, default: "115200 NONE 1STOPBIT 8DATABITS LOCAL NOBREAK"
  const :remote_ui_port, T.nilable(Integer)
  const :remote_ws_port, T.nilable(Integer)
end

class Host < T::Struct
  const :hostname, String
  const :stacks, T::Array[Stack], default: []
  const :configs, T::Array[String], default: []
  const :groups, T::Array[String], default: []
  const :pre_start, T::Array[String], default: []
  const :environment, T::Array[String], default: []
  const :crons, T::Array[Cron], default: []
  const :serials, T::Hash[String, SerialPort], default: {}
  const :secrets, T::Hash[String, String], default: {}
  const :tailnet_ip, String, default: ""

  def base_docker_compose
    [
      "/usr/bin/docker-compose",
      "--ansi",
      "never",
      "-f",
      "docker-compose.yml",
    ] + stacks.flat_map { |s| ['-f', s.path] }
  end
end

class Config < T::Struct
  const :hosts, T::Hash[String, Host]
  const :config_files, T::Array[String]
  const :root_path, String
  const :all_stacks, T::Hash[String, Stack]

  def self.instance
    @instance ||= load!
  end

  def self.reload!
    @instance = load!
  end

  def self.load!
    LOGGER.info("Config.load!")
    root_path = File.expand_path(File.join(__FILE__, '../..'))
    hosts_path = File.join(root_path, 'hosts.yml')
    config = YAML.load_file(hosts_path)

    raw_hosts = config["hosts"]
    defaults = config["defaults"]

    raw_hosts["__default"] = {}

    secrets = Secrets.load_all!
    tailnet_ips = Tailscale.load_all!

    stacks = Dir.glob(File.expand_path(File.join(hosts_path, "../stacks/*.yml"))).map do |stack_file|
      stack_name = File.basename(stack_file, ".yml")
      stack_config = YAML.load_file(stack_file, aliases: true)

      next if stack_config.nil?

      [stack_name, {"name" => stack_name, "config" => stack_config}]
    end.compact.to_h

    hosts = raw_hosts.map do |hostname, host|
      host_conf = defaults.merge(host) { |k, x, y| x + y }

      host_conf["hostname"] = hostname

      host_stacks = host_conf.delete("stacks").sort.uniq

      host_conf["stacks"] = host_stacks.map { |name| stacks[name] }.compact

      host_conf["pre_start"] = host_conf.delete("pre-start")
      host_conf["tailnet_ip"] = tailnet_ips[hostname]

      auth_key = Tailscale.auth_key!

      env = host_conf["environment"] + secrets[hostname].map { |k,v| %Q[#{k}="#{v}"] } + ["TAILNET_IP=#{tailnet_ips[hostname]}", "TS_AUTHKEY=#{auth_key}"]

      host_conf["environment"] = env

      [
        hostname,
        host_conf
      ]
    end.to_h

    config_files = Dir.glob(File.join(root_path, '**', '*.erb'), File::FNM_DOTMATCH).to_a

    config_hash = {
      "hosts" => hosts,
      "config_files" => config_files,
      "root_path" => root_path,
      "all_stacks" => stacks,
    }

    from_hash(config_hash)
  end

  def docker_hosts
    hostnames = hosts.select do |hn, h|
      h.stacks.length > 1
    end.map(&:first).reject { |h| h == "__default" }

    hosts.slice(*hostnames)
  end

  def this_host
    raise "No HOSTNAME set, can't access this_host" unless ENV['HOSTNAME']
    hosts[ENV['HOSTNAME']] || hosts["__default"]
  end

  def hostnames
    hosts.keys
  end

  def generate_templated_files!
    LOGGER.info('generate_templated_files!')
    config_files.each do |filename|
      output_filename = filename.gsub(/\.erb$/, '')
      generate_templated_file(filename, output_filename)
    end
  end

  def generate_templated_file(template_filename, output_filename, host: nil)
    File.open(output_filename, 'w+') do |f|
      f.write(template_result(template_filename, host: host))
    end
  end

  def template_result(template_filename, host: nil)
    template = ERB.new(File.read(template_filename), trim_mode: '-')
    template.filename = template_filename

    template.result(binding)
  end
end
