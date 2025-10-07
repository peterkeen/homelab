DNS_PATH = "dns"
FLY_PATH = "flyctl"

load 'dns/shared_tasks.rb'

build_docker
k8s_apply
