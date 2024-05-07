task :ci do
  sh "scripts/run_ci.rb"
end

task :clean do
  sh "rm -rf playbooks/files/build"
end

task :build => :clean do
  sh "scripts/generate_host_compose.rb"
end

task :ansible, [:playbook] => :build do |task, args|
  playbooks = (args[:playbook].nil? ? ['main'] : [args[:playbook]] + args.extras).map { |pb| "./playbooks/#{pb}.yaml" }.join(' ')
  sh "ansible-playbook -i ./scripts/inventory.rb #{playbooks}"
end

task :default => :ci

