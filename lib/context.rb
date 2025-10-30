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
  attr_reader :hooks

  def initialize(hosts_file:, hostname:, hooks:)
    @hosts_file = hosts_file
    @hostname = hostname
    @hooks = hooks

    hooks.for_each_hook do |hook|
      if hook.const_defined?(:ContextHelpers)
        self.extend(hook.const_get(:ContextHelpers))
      end
    end
  end

  def this_host
    raise "Cannot access this_host when in global context" if hostname == GLOBAL_CONTEXT_HOSTNAME
    hosts_file.hosts[hostname]
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

  def all_host_services
    hosts.each do |host|
      host.services.each do |service|
        yield host, service.stack, service
      end
    end
  end

  def dump_yaml_without_symbols(obj, io = nil, **options)
    visitor = SymbolToStringYamlTreeVisitor.create(**options)
    visitor << obj
    visitor.tree.yaml(io, **options)
  end

  def get_binding
    binding
  end
end
