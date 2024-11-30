namespace :dns do
  task :preview => :ci do
    sh "cd dns && dnscontrol preview"
  end

  task :apply => :ci do
    sh "cd dns && dnscontrol push"
  end
end

