require_relative './stack'

class Host
  attr_reader :stack_list
  attr_reader :local_ip
  attr_reader :tailnet_ip

  def initialize(hostname:, stacks:, environment:, local_ip:, tailnet_ip: nil)
    @hostname = hostname
    @stack_list = stacks
    @environment = environment
    @local_ip = local_ip
    @tailnet_ip = tailnet_ip
  end

  def stacks
    @stacks ||= stack_list.map do |stack|
      Stack.new(name: stack)
    end
  end

  def services
    @services ||= stacks.flat_map do |stack|
      stack.services.map do |service|
        service
      end
    end
  end

  def normalized_hostname
    hostname.tr("-", "_")
  end

  def hostname
    @hostname.to_s
  end

  def environment
    extra_vars = {
      'HOSTNAME' => hostname.to_s,
      'LOCAL_IP' => local_ip,
      'TAILNET_IP' => tailnet_ip,
      'GATUS_API_TOKEN' => "op://fmycvdzmeyvbndk7s7pjyrebtq/g6tkyx7ryhhdig3vgspawa6c2m/GATUS_API_TOKEN_#{normalized_hostname}",
    }

    Array(@environment) + extra_vars.map { |k,v| "#{k}=#{v}" }
  end
end
