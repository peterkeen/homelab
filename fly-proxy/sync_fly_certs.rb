#!/usr/bin/env ruby

require_relative "../lib/config.rb"
require 'json'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.on('--dry-run', "Dry run, do not actually add certs") do |d|
    options[:dry_run] = d
  end
end.parse!

stack_domains = Config.instance.all_stacks.filter_map do |stackname, stack|
  services = stack.config.fetch("services", []) || []
  services.map do |service_name, service|
    next if service["x-public-ingress"].nil?
    ingress = service["x-public-ingress"]

    [ingress['hostname']] + ingress.fetch('alternate_hostnames', [])
  end
end.flatten.compact

Dir.chdir(File.join(Config.instance.root_path, 'fly-proxy')) do
  existing_certs = JSON.parse(`flyctl certs list --json`).map { |c| c['Hostname'] }
  needed_certs = stack_domains - existing_certs
  if options[:dry_run]
    warn "Would have generated certs for: " + needed_certs.join(', ')
  else
    needed_certs.each do |domain|
      system("flyctl certs add #{domain}")
    end
  end
end
