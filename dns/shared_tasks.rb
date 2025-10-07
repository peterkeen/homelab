require 'json'

task :preview => :ci do
  sh "cd #{DNS_PATH} && dnscontrol preview"
end

task :apply => :ci do
  sh "cd #{DNS_PATH} && dnscontrol push"
end
