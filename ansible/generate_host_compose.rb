#!/usr/bin/env ruby

require_relative "../lib/config.rb"
require 'fileutils'

APPLY_HOSTS = Array(ENV.fetch('APPLY_HOSTS', "").split(",").freeze)

Config.instance.hosts.each do |hostname, host|
  next if hostname == "__default"
  if APPLY_HOSTS.length > 0 && !APPLY_HOSTS.include?(hostname)
    LOGGER.info("Skipping #{hostname}")
    next
  end
    
  LOGGER.info(hostname)

  ENV['HOSTNAME'] = hostname

  output_path = File.join(Config.instance.root_path, "ansible/files/build", "#{hostname}.tailnet-a578.ts.net")
  FileUtils.mkdir_p(output_path)

  Config.instance.generate_templated_files!
  Config.reload!

  host = Config.instance.hosts[hostname]

  compose_filename = File.join(output_path, "docker-compose.yml")
  File.open(compose_filename, "w+") do |f|
    include = host.stacks.map do |stack| 
      {"path" => ["stacks/#{stack.name}/docker-compose.yml"]}
    end
    f.write({"include" => include}.to_yaml)
  end

  env_filename = File.join(output_path, ".env")
  File.open(env_filename, "w+") do |f|
    host.environment.each do |e|
      f.puts(e)
    end
  end

  FileUtils.mkdir_p(File.join(output_path, "stacks"))

  host.stacks.each do |stack|
    FileUtils.copy_entry(
      File.join(Config.instance.root_path, "stacks", stack.name),
      File.join(output_path, "stacks", stack.name)
    )
  end

  configs_sha = `gtar --sort=name --owner=root:0 --group=root:0 --mtime='UTC 2022-01-01' -C / -cf - #{output_path}/stacks #{output_path}/.env | sha256sum | cut -d' ' -f1`

  File.open(env_filename, 'a+') do |f|
    f.puts("CONFIGS_SHA=#{configs_sha}")
  end
end
