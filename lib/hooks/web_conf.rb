module WebConfHook
  def build_overrides_for_stack(stack)
    return {} unless stack.services.any? do |service|
      service.config.key?(:"x-web")
    end

    overrides = {
      "services" => {
        "local-proxy" => {
          "networks" => {}
        }
      },
      "networks" => {},
    }

    stack.services.each do |service|
      next if ["host", "none"].include?(service.config[:network_mode])
      next unless service.config[:"x-web"]

      overrides["networks"]["local-web-#{service.name}"] = {}

      overrides["services"][service.name.to_s] = {
        "networks" => {
          "local-web-#{service.name}" => {
            "aliases" => [
              "#{service.name}.#{stack.name}.local-web.internal"
            ]
          }
        }
      }

      overrides["services"]["local-proxy"]["networks"]["local-web-#{service.name}"] = {}
    end

    overrides
  end

  module ContextHelpers
    def web_config_for_service(service)
      return unless service.config.key?(:"x-web")

      conf = service.config.fetch(:"x-web").dup

      conf[:hostname] ||= service.config[:hostname]
      conf[:fqdn] ||= "#{conf[:hostname]}.keen.land"

      if conf[:routes].nil?
        conf[:routes] = [{port: conf[:port], upstream: conf[:upstream], path: "/"}]
      end

      conf[:routes] = conf[:routes].map { |r| route_with_defaults(r, service) }

      @web_conf = conf
    end

    def route_with_defaults(src_route, service)
      route = src_route.dup

      route[:path] ||= "/"

      if route[:port].nil? && route[:upstream].nil?
        raise "Need port for route #{route[:path]} in service #{service.name} in #{service.stack.name}, can't determine defaults"
      end

      if route[:websockets].nil?
        route[:websockets] = true
      end

      if route[:cache].nil?
        route[:cache] = true
      end

      route[:upstream] ||= "http://#{service.name}.#{service.stack.name}.local-web.internal:#{route[:port]}"
      route
    end

    def cert_domain_for_fqdn(fqdn:)
      parts = fqdn.split(/\./)
      parts.shift if parts[0] == "www" || fqdn =~ /\.keen.land\z/

      parts.join('.')
    end

    def all_web_configs(&block)
      seen_fqdns = Set.new
      all_host_services do |host, stack, service|
        web_conf = web_config_for_service(service)

        next unless web_conf

        seen_fqdns.add?(web_conf[:fqdn]) or raise "Duplicate fqdn for service #{service.name}: #{web_conf[:fqdn]}"

        yield host, stack, service, web_conf
      end
    end

    def this_host_certs
      certs = {}

      this_host_web_configs do |stack, service, web_conf|
        ([web_conf[:fqdn]] + web_conf.fetch(:alternate_hostnames, [])).each do |hostname|
          certname = cert_domain_for_fqdn(fqdn: hostname)
          certs[certname] ||= Set.new
          certs[certname].add hostname
        end
      end

      certs
    end

    def this_host_web_configs
      all_web_configs do |host, stack, service, web_conf|
        next unless host == this_host
        yield stack, service, web_conf
      end
    end
  end
end
