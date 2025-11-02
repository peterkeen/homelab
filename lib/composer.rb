require 'subprocess'
require_relative './ds_logger'

class Composer
  OVERRIDE_FILE_NAME = "compose.override.yaml"
  attr_reader :context
  attr_reader :build_root

  def initialize(context:, build_root:)
    @context = context
    @build_root = build_root
  end

  def perform
    LOGGER.info("Deploying #{context.this_host.hostname}")
    build_host_env_file
    build_stack_env_files
    build_override_file

    apply_compose!
  end

  def build_host_env_file
    File.open(File.join(host_root, ".env"), "w+") do |f|
      f.puts(context.this_host.environment.join("\n"))
    end
  end

  def build_stack_env_files
    context.this_host.stacks.each do |stack|
      env_path = File.join(stack_path(stack), ".env")
      env = {}

      if File.exist?(env_path)
        File.read(env_path).lines(chomp: true).each do |line|
          k,v = line.split("=", 2)
          env[k] = v
        end
      end

      env.merge!(context.hooks.build_stack_env(context, stack))

      File.open(env_path, "w+") do |f|
        env.each do |key, val|
          f.puts("#{key}=#{val}")
        end
      end

      stack_configs_sha = compute_configs_sha(stack)
      File.open(env_path, "a+") do |f|
        f.puts("CONFIGS_SHA=#{stack_configs_sha}")
      end
    end
  end

  def build_override_file
    overrides = {
      "services" => {},
      "networks" => {},
    }

    context.this_host.stacks.each do |stack|
      overrides["networks"][stack.name.to_s] ||= {}

      stack.services.each do |service|
        next if ["host", "none"].include?(service.config[:network_mode])

        overrides["services"][service.name.to_s] ||= {}

        overrides["services"][service.name.to_s].deep_merge({
          "networks" => {
            stack.name.to_s => {
              "aliases" => [
                "#{service.name}.#{stack.name}.docker.internal"
              ]
            },
          }
        })
      end

      stack_overrides = context.hooks.build_overrides_for_stack(stack)
      overrides = overrides.deep_merge(stack_overrides)
    end

    File.open(File.join(host_root, OVERRIDE_FILE_NAME), "w+") do |f|
      f.write(overrides.to_yaml)
    end
  end

  def apply_compose!
    interpolated = context.hooks.process_interpolated_compose(context, compose_stage_one)

    if ENV['SKIP_APPLY']
      puts interpolated
      return
    end

    rsync_files!
    context.hooks.pre_deploy(context)

    compose_stage_two(interpolated)
  end

  def compose_stage_zero
    stack_paths = context.this_host.stacks.map do |stack|
      File.join(stack_path(stack), "docker-compose.yml")
    end

    {"name" => "app", "include" => stack_paths}.to_yaml
  end

  def compose_stage_one
    args = [
      "docker",
      "compose",
      "--project-name=app",
      "-f", "-",
      "-f", "#{host_root}/#{OVERRIDE_FILE_NAME}",
      "config",
      "--no-path-resolution",
    ].flatten

    Dir.chdir(host_root) do
      output = nil
      Subprocess.check_call(args, stdout: Subprocess::PIPE, stdin: Subprocess::PIPE) do |p|
        output, _ = p.communicate compose_stage_zero
      end
      output
    end
  end

  def rsync_files!
    args = [
      "rsync",
      "--recursive",
      "--archive",
      "--delete",
      "--exclude", ".env",
      "--exclude", "*.erb",
      "--exclude", "docker-compose.yml",
      "--delete-excluded",
      File.join(host_root, "stacks"),
      "root@#{context.this_host.hostname}:/root/app/"
    ]

    Subprocess.check_call(args)
  end

  def compose_stage_two(interpolated)
    ENV['DOCKER_HOST'] = "ssh://root@#{context.this_host.hostname}"

    args = [
      "docker",
      "compose",
      "--project-name=app",
      "-f", "-",
      "up",
      "--detach",
      "--quiet-pull",
      "--quiet-build",
      "--no-color",
      "--build",
      "--timestamps",
      "--remove-orphans",
    ]

    Dir.chdir(host_root) do
      Subprocess.check_call(args, stdin: Subprocess::PIPE) do |p|
        p.communicate interpolated
      end
    end
  end

  def host_root
    File.join(build_root, context.this_host.hostname.to_s)
  end

  def stack_path(stack)
    File.join(host_root, "stacks", stack.name)
  end

  def compute_configs_sha(stack)
    `gtar --sort=name --owner=root:0 --group=root:0 --mtime='UTC 2022-01-01' -C / -cf - #{host_root}/stacks/#{stack.name} #{host_root}/.env 2>/dev/null | sha256sum | cut -d' ' -f1`
  end

end
