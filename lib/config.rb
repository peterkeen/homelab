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
    "stacks/#{name}"
  end
end

class Host < T::Struct
  const :hostname, String
  const :stacks, T::Array[Stack], default: []
  const :groups, T::Array[String], default: []
  const :environment, T::Array[String], default: []
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

  LOCAL_ADDRESS_REGEXP = /(10\.73\.95\.\d+)/

  def local_address
    return @local_address if @local_address

    resp = Subprocess.check_output(Shellwords.split("ssh root@#{hostname} ip addr"))
    @local_address = resp.lines.filter_map { |l| LOCAL_ADDRESS_REGEXP.match(l)&.to_a&.last }.first
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

  def self.hostnames
    root_path = File.expand_path(File.join(__FILE__, '../..'))
    hosts_path = File.join(root_path, 'hosts.yml')
    config = YAML.load_file(hosts_path)
    config["hosts"].keys
  end

  def self.load!
    LOGGER.info("Config.load!")
    root_path = File.expand_path(File.join(__FILE__, '../..'))
    hosts_path = File.join(root_path, 'hosts.yml')
    config = YAML.load_file(hosts_path)

    raw_hosts = config["hosts"]
    defaults = config["defaults"]

    raw_hosts["__default"] = {}

    secrets = Secrets.instance
    tailnet_ips = Tailscale.addresses

    stacks = Dir.glob(File.expand_path(File.join(hosts_path, "../stacks/*"))).map do |stack_path|
      next unless Dir.exist?(stack_path)

      stack_name = File.basename(stack_path)
      stack_file = File.join(stack_path, "docker-compose.yml")
      next unless File.exist?(stack_file)

      stack_config = YAML.load_file(stack_file, aliases: true)

      next if stack_config.nil?

      [stack_name, {"name" => stack_name, "config" => stack_config}]
    end.compact.to_h

    hosts = raw_hosts.map do |hostname, host|
      host_conf = defaults.merge(host) { |k, x, y| x + y }

      host_conf["hostname"] = hostname

      host_stacks = host_conf.delete("stacks").sort.uniq

      host_conf["stacks"] = host_stacks.map { |name| stacks[name] }.compact

      host_conf["tailnet_ip"] = tailnet_ips[hostname]

      host_secrets = {}
      secrets.items_for_server(hostname).each do |item|
        host_secrets = host_secrets.merge(item.vars)
      end

      env = host_conf["environment"] + host_secrets.map { |k,v| %Q[#{k}="#{v}"] } + ["TAILNET_IP=#{tailnet_ips[hostname]}", "HOSTNAME=#{hostname}"]

      host_conf["environment"] = env

      [
        hostname,
        host_conf
      ]
    end.to_h

    config_files = Dir.glob(File.join(root_path, '**', '*.erb'), File::FNM_DOTMATCH).to_a
    config_files = config_files.reject { |f| f =~ /ansible\/files\/build/ }

    config_hash = {
      "hosts" => hosts,
      "config_files" => config_files,
      "root_path" => root_path,
      "all_stacks" => stacks,
    }

    from_hash(config_hash)
  end

  def all_hosts
    hostnames = hosts.map(&:first).reject { |h| h == "__default" }
    hosts.slice(*hostnames)
  end

  def this_host
    raise "No HOSTNAME set, can't access this_host" unless ENV['HOSTNAME']
    hosts[ENV['HOSTNAME']] || hosts["__default"]
  end

  def hostnames
    hosts.keys
  end

  def all_web_configs(defaults={}, &block)
    all_host_services do |host, stack, service_name, service|
      next unless service["x-web"]
      web_conf = web_config_from_service(service, defaults)
      yield host, stack, service_name, web_conf
    end
  end

  def all_host_services(&block)
    all_hosts.each do |hostname, host|
      host.stacks.each do |stack|
        stack.config.fetch("services", []).each do |service_name, service|
          yield host, stack, service_name, service.dup
        end
      end
    end
  end

  def web_config_from_service(service, defaults={})
    return unless service["x-web"]

    conf = defaults.dup.merge(service.fetch("x-web", {}))

    conf["hostname"] ||= service["hostname"]
    conf["fqdn"] ||= "#{conf['hostname']}.keen.land"

    if conf["port"].nil? && conf["upstream"].nil?
      raise "Need port for service #{service_name} in #{stack.name}, can't determine default"
    end
    conf["upstream"] ||= "http://#{service["container_name"]}:#{conf['port']}"

    conf
  end

  def this_host_web_configs(defaults={}, &block)
    all_web_configs(defaults) do |host, stack, service_name, web_conf|
      next unless host == this_host
      yield stack, service_name, web_conf
    end
  end

  def this_host_services(&block)
    all_host_services do |host, stack, service_name, service|
      next unless host == this_host
      yield stack, service_name, service
    end
  end

  def secrets
    Secrets.instance
  end

  def generate_templated_files!
    LOGGER.info('generate_templated_files!')
    config_files.each do |filename|
      output_filename = filename.gsub(/\.erb$/, '')
      generate_templated_file(filename, output_filename)
    end

    generate_env_files!
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

  def generate_env_files!
    all_stacks.each do |name, stack|
      stack_vars = {}

      stack.config.fetch("services", []).each do |service_name, service_conf|
        next unless service_conf["x-op-items"]
        service_conf["x-op-items"].each do |item_id|
          stack_vars.merge!(Secrets.instance.get(item_id).vars)
        end
      end

      next if stack_vars.length == 0

      env_path = File.join(root_path, stack.path, ".env")

      File.open(env_path, "w+") do |f|
        stack_vars.each do |key, val|
          f.puts("#{key}=#{val}")
        end
      end
    end
  end
end
