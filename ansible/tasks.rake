namespace :ansible do
  task :clean do
    sh "rm -rf ansible/files/build"
  end


  task :build => :clean do
    Dir.chdir(File.dirname(__FILE__)) do
      sh "./generate_host_compose.rb"
    end
  end
  
  task :apply, [:playbook] => :build do |task, args|
    playbooks = (args[:playbook].nil? ? ['main'] : [args[:playbook]] + args.extras).map { |pb| "./#{pb}.yaml" }.join(' ')

    Dir.chdir(File.dirname(__FILE__)) do
      sh "ansible-playbook -i ./inventory.rb #{playbooks}"
    end
  end
end
