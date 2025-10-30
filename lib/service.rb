class Service
  attr_reader :config
  attr_reader :name
  attr_reader :stack

  def initialize(name:, config:, stack:)
    @name = name
    @config = config
    @stack = stack
  end

end
