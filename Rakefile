require './lib/runner.rb'

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
  sh "docker buildx bake --push"
end

task :apply => :bake do
  Runner.new.run
end

task :apply_one, [:hostname] do |task, args|
  Runner.new(hostname: args[:hostname]).run
end
