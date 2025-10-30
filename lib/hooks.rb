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

  def build_overrides_for_stack(stack)
    overrides = {}
    for_each_hook do |hook|
      if hook.method_defined?(:build_overrides_for_stack)
        overrides.deep_merge! Class.new.extend(hook).build_overrides_for_stack(stack)
      end
    end

    overrides
  end

  def for_each_hook(&block)
    @hooks.values.each do |hook_mod|
      hook_mod.constants.each do |constant|
        yield hook_mod.const_get(constant)
      end
    end
  end
end
