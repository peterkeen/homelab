task :clean do
  sh "rm -rf ansible/files/build"
end

task :apply, [:playbook] => [:build, :build_inventory] do |task, args|
  playbooks = (args[:playbook].nil? ? ['main'] : [args[:playbook]] + args.extras).map { |pb| "./#{pb}.yaml" }.join(' ')

  Dir.chdir(File.dirname(__FILE__)) do
    sh "ansible-playbook -i ./files/build/inventory.json #{playbooks}"
  end
end

