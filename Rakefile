require './lib/config.rb'
require './lib/task_common.rb'

Dir.glob('*/**/*.rake') do |f|
  ns = File.dirname(f.to_s).gsub('/', ':')
 
  namespace ns do
    load(f)
  end
end

task :ci do
  sh "scripts/run_ci.rb"
end

task :clean => 'ansible:clean' do
  sh "git clean -xf"
end

task :bake => :ci do
  exec "docker buildx bake --push"
end

task :apply => ['ansible:apply', 'dns:apply']

task :default do
  ns_default_taskname = Rake.application.original_dir.gsub(Dir.pwd + "/", "").gsub("/", ":") + ":default"
  if Rake::Task.task_defined?(ns_default_taskname)
    Rake.application[ns_default_taskname].invoke
  else
    Rake.application[:ci].invoke
  end
end
