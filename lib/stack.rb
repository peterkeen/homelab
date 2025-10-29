require 'yaml'
require_relative './service'

class Stack
  attr_reader :name
  attr_reader :path
  attr_reader :config

  def initialize(name:, root_path: ".")
    @name = name
    @path = File.join(root_path, "stacks", name)
    @config = YAML.safe_load_file(File.join(@path, "docker-compose.yml"), symbolize_names: true, aliases: true)
  end

  def services
    @config.fetch(:services, []).map do |service_name, conf|
      Service.new(name: service_name, config: conf, stack: self)
    end
  end
end
