#!/usr/bin/env ruby

require 'json'

require_relative '../lib/config.rb'

ENV["HOSTNAME"] ||= "ci"
ENV["TAILNET_IP"] = "1.2.3.4"

Config.instance.generate_templated_files!

groups = {}

Config.instance.hosts.map do |_, host|
  next if host.hostname == "__default"

  host_groups = host.groups

  if host.stacks.length > 1
    host_groups << "stacked"
  end

  host_groups.each do |group|
    groups[group] ||= []
    groups[group] << host
  end
end

inventory = {
  "_meta" => {
    "hostvars" => {}
  }
}

groups.each do |group, hosts|
  inventory[group] = {
    "hosts" => hosts.map(&:hostname).map { |h| "#{h}.tailnet-a578.ts.net"},
    "vars" => {
      "ansible_ssh_user" => "root",
      "ansible_python_interpreter" => "/usr/bin/python3",
    },
    "children" => []
  }
end

puts inventory.to_json
