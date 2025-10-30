require 'subprocess'
require_relative './ds_logger'

class Composer
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
            env = env.merge(context.secrets.get(item).obfuscated_refs)
          end
        end
      end

      File.open(env_path, "w+") do |f|
        env.each do |key, val|
          f.puts("#{key}=#{val}")
        end
      end
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
    ENV['CONFIGS_SHA'] = compute_configs_sha
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

        ref = "op://" + item.fetch(:ref)
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

  def compute_configs_sha
    `gtar --sort=name --owner=root:0 --group=root:0 --mtime='UTC 2022-01-01' -C / -cf - #{host_root}/stacks #{host_root}/.env | sha256sum | cut -d' ' -f1`
  end

end
