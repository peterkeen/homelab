require './lib/runner.rb'
require './lib/baker.rb'

Dir.glob('*/**/*.rake') do |f|
  ns = File.dirname(f.to_s).gsub('/', ':')
 
  namespace ns do
    load(f)
  end
end

task :clean do
  build_root = Runner.new.build_root
  FileUtils.rm_rf(build_root)
end

task :bake => :clean do
  Baker.new.run
end

task :apply, [:groups] => :bake do |task, args|
  groups = Array(args[:groups]) + args.extras
  Runner.new(groups: groups).run
end

task :apply_one, [:hostname] do |task, args|
  Runner.new(hostname: args[:hostname]).run
end

task :find_unused_stacks do
  hf = HostsFile.new
  used_stacks = hf.hosts.flat_map do |_, host|
    host.stack_list
  end

  Dir.glob(File.join(hf.root_path, "stacks/*")).each do |stack_dir|
    stack_name = File.basename(stack_dir)
    next if used_stacks.include?(stack_name)
    puts stack_name
  end
  
end

