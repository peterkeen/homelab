require_relative './stack'

class Host
  attr_reader :hostname
  attr_reader :stack_list
  attr_reader :environment
  attr_reader :local_ip

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
end
