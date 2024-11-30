namespace :fly_proxy do
  task :deploy => :ci do
    require_relative './lib/config.rb'

    Dir.chdir(File.join(Config.instance.root_path, "fly-proxy")) do
      sh "flyctl deploy --detach"
    end
  end

  namespace :certs do
    task :preview => :ci do
      sh "./sync_fly_certs.rb --dry-run"
    end

    task :apply => :ci do
      sh "./sync_fly_certs.rb"
    end
  end

  task :apply => ['fly_proxy:certs:apply', 'fly_proxy:deploy']
end


