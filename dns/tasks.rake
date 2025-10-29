require 'json'

task :preview => :ci do
  sh "cd dns && op run --env-file=.env -- dnscontrol preview"
end

task :apply => :ci do
  sh "cd dns && op run --env-file=.env -- dnscontrol push"
end
