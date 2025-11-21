class Service
  attr_reader :config
  attr_reader :name
  attr_reader :stack

  def initialize(name:, config:, stack:)
    @name = name
    @config = config
    @stack = stack
  end

  def extensions
    @config.filter_map do |key, value|
      if key.to_s.start_with?("x-")
        [key.to_s.gsub(/^x-/, ''), value]
      end
    end.to_h
  end
  
end
