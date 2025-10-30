require_relative '../secrets'

module OnePassword
  def build_stack_env(context, stack)
    {}.tap do |env|
      stack.services.each do |service|
        service.config.fetch(:"x-op-items", []).each do |item|
          if item.is_a?(String)
            secret = Secrets.instance.get(item)
            env.merge!(secret.obfuscated_refs)
            env["OP_ITEM_#{item}_MTIME"] = secret.updated_at.to_time.to_i
          else
            ref = item[:ref].split("/").first
            env["OP_ITEM_#{ref}_MTIME"] = Secrets.instance.get(ref).updated_at.to_time.to_i
          end
        end
      end
    end
  end

  def pre_deploy(context)
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

  def process_interpolated_compose(_context, interpolated)
    args = ["op", "inject"]
    output = nil
    Subprocess.check_call(args, stdout: Subprocess::PIPE, stdin: Subprocess::PIPE) do |p|
      output, _ = p.communicate interpolated
    end
    output
  end
end
