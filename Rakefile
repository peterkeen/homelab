require './lib/runner.rb'
require './lib/baker.rb'

Dir.glob('*/**/*.rake') do |f|
  ns = File.dirname(f.to_s).gsub('/', ':')
 
  namespace ns do
    load(f)
  end
end

task :clean => 'ansible:clean' do
  sh "git clean -xf"
end

task :bake do
  Baker.new.run
end

task :apply, [:groups] => :bake do |task, args|
  groups = Array(args[:groups]) + args.extras
  Runner.new(groups: groups).run
end

task :apply_one, [:hostname] do |task, args|
  Runner.new(hostname: args[:hostname]).run
end
