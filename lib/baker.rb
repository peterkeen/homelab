require 'subprocess'

require_relative './hosts_file'
require_relative './hooks'
require_relative './ds_logger'

class Baker
  attr_reader :hosts_file
  attr_reader :hooks

  def initialize
    @hosts_file = HostsFile.new
    @hooks = Hooks.new
  end

  def run
    context = Context.new(
      hosts_file: hosts_file,
      hostname: Context::GLOBAL_CONTEXT_HOSTNAME,
      hooks: hooks,
    )

    stacks = context.hosts.flat_map do |host|
      host.stacks
    end.uniq(&:name)

    targets = {}

    stacks.each do |stack|
      next unless File.exist?(File.join(stack.path, "Dockerfile"))

      config = {
        dockerfile: "Dockerfile",
        context: stack.path,
        tags: [
          "ghcr.io/keenfamily-us/infra/stacks/#{stack.name}:latest",
        ],
        platforms: [
          "linux/amd64",
        ]
      }.deep_merge(stack.config.fetch(:"x-bake-target", {}))

      targets[stack.name] = config
    end

    bake_config = {
      group: {
        default: {
          targets: targets.keys
        },
      },
      target: targets
    }

    bakefile_path = File.join(context.root_path, "build", "docker-bake.json")

    File.open(bakefile_path, "w+") do |f|
      f.write(JSON.pretty_generate(bake_config))
    end

    Dir.chdir(context.root_path) do
      args = [
        "docker",
        "buildx",
        "bake",
        "--file", bakefile_path,
        "--push"
      ]

      Subprocess.check_call(args)
    end
  end
end
