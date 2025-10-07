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

task :build_all_docker do
  builds = Rake.application.tasks.filter_map do |task|
    task.name if task.name =~ /build_and_push_docker/
  end.to_a

  builds.each do |build|
    Rake::Task[build].invoke
  end
end

task :apply => ['ansible:apply', 'dns:apply', 'fly_proxy:apply']

task :default do
  ns_default_taskname = Rake.application.original_dir.gsub(Dir.pwd + "/", "").gsub("/", ":") + ":default"
  if Rake::Task.task_defined?(ns_default_taskname)
    Rake.application[ns_default_taskname].invoke
  else
    Rake.application[:ci].invoke
  end
end
