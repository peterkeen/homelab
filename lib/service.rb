class Service
  attr_reader :config
  attr_reader :name
  attr_reader :stack

  def initialize(name:, config:, stack:)
    @name = name
    @config = config
    @stack = stack
  end

  def web_config
    return unless config.key?(:"x-web")
    return @web_conf if @web_conf

    conf = config.fetch(:"x-web").dup

    conf[:hostname] ||= config[:hostname]
    conf[:fqdn] ||= "#{conf[:hostname]}.keen.land"

    if conf[:port].nil? && conf[:upstream].nil?
      raise "Need port for service #{name} in #{stack.name}, can't determine default"
    end
    conf[:upstream] ||= "http://#{config[:container_name]}:#{conf[:port]}"

    @web_conf = conf
  end
end
