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

      if conf[:port].nil? && conf[:upstream].nil?
        raise "Need port for service #{name} in #{stack.name}, can't determine default"
      end
      conf[:upstream] ||= "http://#{service.name}.#{service.stack.name}.local-web.internal:#{conf[:port]}"

      @web_conf = conf
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

    def this_host_web_configs
      all_web_configs do |host, stack, service, web_conf|
        next unless host == this_host
        yield stack, service, web_conf
      end
    end
  end
end
