def build_docker(prereqs: [], repo_base: "ghcr.io/keenfamily-us/infra", task_dir: nil, platform: "linux/amd64")
  task_dir ||= File.dirname(caller_locations.first.path)

  build_tag = "#{repo_base}/#{task_dir}:latest"

  namespace :docker do

    task :build => prereqs do
      Dir.chdir(task_dir) do
        sh "docker build --platform #{platform} -t #{build_tag} ."
      end
    end

    task :push do
      Dir.chdir(task_dir) do
        sh "docker push #{build_tag}"
      end
    end

  end

  task :docker => ["docker:build", "docker:push"]
end

def k8s_apply(prereqs: [], context: "admin@omicron", task_dir: nil, file: "app.yaml")
  task_dir ||= File.dirname(caller_locations.first.path)

  context_name = context.split(/@/, 2).last

  namespace :k8s do
    namespace context_name do
      task :apply => prereqs do
        Dir.chdir(task_dir) do
          if File.exist?("kustomization.yaml")
            sh "kubectl --context #{context} apply -k ."
          else
            sh "kubectl --context #{context} apply -f #{file}"
          end
        end
      end
    end
  end
end
