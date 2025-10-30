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

      stack.services.each do |service|
        service.config.fetch(:"x-op-items", []).each do |item|
          if item.is_a?(String)
            secret = context.secrets.get(item)
            env = env.merge(secret.obfuscated_refs)
            env["OP_ITEM_#{item}_MTIME"] = secret.updated_at.to_time.to_i
          else
            ref = item[:ref].split("/").first
            env["OP_ITEM_#{ref}_MTIME"] = context.secrets.get(ref).updated_at.to_time.to_i
          end
        end
      end

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
      stack.services.each do |service|
        next if ["host", "none"].include?(service.config[:network_mode])

        overrides["services"][service.name.to_s] = {
          "networks" => {
            "default" => {
              "aliases" => [
                "#{service.name}.svc.docker.internal"
              ]
            },
          }
        }
      end

      overrides.deep_merge!(context.hooks.build_overrides_for_stack(stack))
    end

    File.open(File.join(host_root, OVERRIDE_FILE_NAME), "w+") do |f|
      f.write(overrides.to_yaml)
    end
  end

  def apply_compose!
    interpolated = compose_stage_one
    injected = op_inject(interpolated)

    rsync_files!
    upload_secrets_files!

    compose_stage_two(injected)
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

  def upload_secrets_files!
    context.this_host.services.each do |service|
      service.config.fetch(:"x-op-items", []).each do |item|
        next if item.is_a?(String)

        ref = "op://fmycvdzmeyvbndk7s7pjyrebtq/" + item.fetch(:ref)
        path = item.fetch(:remote_path)
        contents = Subprocess.check_output(["op", "read", ref])

        args = ["ssh", "root@#{context.this_host.hostname}", "cat > #{path}"]

        Subprocess.check_call(args, stdin: Subprocess::PIPE) do |p|
          p.communicate contents
        end
      end
    end
  end

  def op_inject(input)
    args = ["op", "inject"]
    output = nil
    Subprocess.check_call(args, stdout: Subprocess::PIPE, stdin: Subprocess::PIPE) do |p|
      output, _ = p.communicate input
    end
    output
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
