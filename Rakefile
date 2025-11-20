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
