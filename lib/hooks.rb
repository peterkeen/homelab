class Hooks
  attr_reader :hooks

  def initialize
    @hooks = {}
    load
  end

  def load
    Dir.glob(File.join(File.dirname(__FILE__), "hooks", "*.rb")).each do |filename|
      @hooks[filename] = Module.new
      Kernel.load(filename, @hooks[filename])
    end
  end

  def build_overrides_for_stack(context, stack)
    overrides = {}

    for_each_hook do |hook|
      if hook.method_defined?(:build_overrides_for_stack)
        hook_overrides = Class.new.extend(hook).build_overrides_for_stack(context, stack)
        overrides = overrides.deep_merge hook_overrides
      end
    end

    overrides
  end

  def build_stack_env(context, stack)
    {}.tap do |env|
      for_each_hook do |hook|
        if hook.method_defined?(:build_stack_env)
          env.merge! Class.new.extend(hook).build_stack_env(context, stack)
        end
      end
    end
  end

  def pre_deploy(context)
    for_each_hook do |hook|
      if hook.method_defined?(:pre_deploy)
        Class.new.extend(hook).pre_deploy(context)
      end
    end
  end

  def process_interpolated_compose(context, interpolated)
    interpolated = interpolated.dup

    for_each_hook do |hook|
      if hook.method_defined?(:process_interpolated_compose)
        interpolated = Class.new.extend(hook).process_interpolated_compose(context, interpolated)
      end
    end

    interpolated
  end

  def for_each_hook(&block)
    @hooks.values.each do |hook_mod|
      hook_mod.constants.each do |constant|
        yield hook_mod.const_get(constant)
      end
    end
  end
end
