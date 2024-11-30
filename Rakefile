require './lib/config.rb'

Dir.glob('*/**/*.rake') { |f| load(f) }

task :ci do
  sh "scripts/run_ci.rb"
end

task :clean => 'ansible:clean' do
  files = Config.instance.config_files.map { |f| f.gsub('.erb', '') }
  sh "rm #{files.join(' ')}"
end

task :apply => ['ansible:apply', 'dns:apply', 'fly_proxy:apply']

task :default => :ci

