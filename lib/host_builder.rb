require 'fileutils'
require_relative './template_renderer'

class HostBuilder
  attr_reader :context
  attr_reader :build_root

  def initialize(context:, build_root:)
    @context = context
    @build_root = build_root
  end

  def perform
    make_build_path
    copy_stacks
    render_templates
  end

  private
  
  def make_build_path
    FileUtils.mkdir_p(File.join(host_build_path, "stacks"))
  end

  def copy_stacks
    context.this_host.stacks.each do |stack|
      src = File.join(context.root_path, stack.path)
      dst = File.join(host_build_path, stack.path)

      FileUtils.copy_entry(src, dst)
    end

    Dir.glob(File.join(host_build_path, "**", ".#*")).each { |f| File.delete(f) }
  end

  def render_templates
    renderer = TemplateRenderer.new(context: context)
    templates = Dir.glob(File.join(host_build_path, "**", "*.erb"), File::FNM_DOTMATCH).to_a

    templates.each do |template_path|
      output_path = template_path.gsub(/\.erb$/, '')
      renderer.render_to_file(template_path, output_path)
    end
  end

  def host_build_path
    File.join(build_root, context.this_host.hostname.to_s)
  end
end
