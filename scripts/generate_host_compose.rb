#!/usr/bin/env ruby

require_relative "../lib/config.rb"
require 'fileutils'

Config.instance.hosts.each do |hostname, host|
  next if hostname == "__default"
  LOGGER.info(hostname)

  ENV['HOSTNAME'] = hostname

  output_path = File.join(Config.instance.root_path, "playbooks/files/build", "#{hostname}.tailnet-a578.ts.net")
  FileUtils.mkdir_p(output_path)

  Config.instance.generate_templated_files!
  Config.reload!

  host = Config.instance.hosts[hostname]

  conf = Hash.new { |h,k| h[k] = {} }

  host.stacks.each do |stack|
    stack.config.each do |k,v|
      conf[k].merge!(v)
    end
  end

  host.serials.each do |item|
    name, _serial = item

    Config.instance.all_stacks[name].config.each do |k,v|
      conf[k].merge!(v)
    end
  end

  compose_filename = File.join(output_path, "docker-compose.yml")
  File.open(compose_filename, "w+") do |f|
    f.write(conf.to_yaml)
  end

  env_filename = File.join(output_path, ".env")
  File.open(env_filename, "w+") do |f|
    host.environment.each do |e|
      f.puts(e)
    end
  end

  FileUtils.mkdir_p(File.join(output_path, "configs"))
  host.configs.each do |conf|
    FileUtils.copy_entry(
      File.join(Config.instance.root_path, "configs", conf),
      File.join(output_path, "configs", conf)
    )
  end

  configs_sha = `gtar --sort=name --owner=root:0 --group=root:0 --mtime='UTC 2022-01-01' -C / -cf - #{output_path}/configs #{output_path}/.env | sha256sum | cut -d' ' -f1`

  File.open(env_filename, 'a+') do |f|
    f.puts("CONFIGS_SHA=#{configs_sha}")
  end
end
