require 'erb'

class TemplateRenderer
  def initialize(context:)
    @context = context
  end

  def render(template_path)
    template = ERB.new(File.read(template_path), trim_mode: '-')
    template.filename = template_path

    template.result(@context.get_binding)
  end

  def render_to_file(template_path, output_path)
    File.open(output_path, 'w+') do |f|
      f.write(render(template_path))
    end
  end
end
