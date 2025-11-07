require 'json'

task :preview do
  sh "cd dns && op run --env-file=.env -- dnscontrol preview"
end

task :apply do
  sh "cd dns && op run --env-file=.env -- dnscontrol push"
end
