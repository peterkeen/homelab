require_relative './hosts_file'

class Context
  GLOBAL_CONTEXT_HOSTNAME = "__global__"

  class SymbolToStringYamlTreeVisitor < Psych::Visitors::YAMLTree
    def visit_Symbol(sym)
      visit_String(sym.to_s)
    end
  end

  attr_reader :hosts_file
  attr_reader :hostname

  def initialize(hosts_file:, hostname:)
    @hosts_file = hosts_file
    @hostname = hostname
  end

  def this_host
    raise "Cannot access this_host when in global context" if hostname == GLOBAL_CONTEXT_HOSTNAME
    hosts_file.hosts[hostname.to_s]
  end

  def hosts
    hosts_file.hosts.values
  end

  def hostnames
    hosts_file.hosts.keys
  end

  def root_path
    hosts_file.root_path
  end

  def get_binding
    binding
  end

  def secrets
    Secrets.instance
  end

  def all_web_configs(&block)
    seen_fqdns = Set.new
    all_host_services do |host, stack, service|
      web_conf = service.web_config
      next unless web_conf

      seen_fqdns.add?(web_conf[:fqdn]) or raise "Duplicate fqdn for service #{service.name}: #{web_conf[:fqdn]}"

      yield host, stack, service, web_conf
    end
  end

  def all_host_services
    hosts.each do |host|
      host.services.each do |service|
        yield host, service.stack, service
      end
    end
  end

  def this_host_web_configs
    all_web_configs do |host, stack, service, web_conf|
      next unless host == this_host
      yield stack, service, web_conf
    end
  end

  def dump_yaml_without_symbols(obj, io = nil, **options)
    visitor = SymbolToStringYamlTreeVisitor.create(**options)
    visitor << obj
    visitor.tree.yaml(io, **options)
  end
end
