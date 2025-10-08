#!/usr/bin/env bash

if ! command -v kubectl &>/dev/null; then
	echo "kubectl not be found"
	exit 1
fi
if ! command -v fzf &>/dev/null; then
	echo "fzf not be found"
	exit 1
fi

function _kube_list_nodes() {
	# select a node with fzf
	kubectl get nodes |
		fzf --bind 'enter:execute(echo {1})+abort' --header-lines=1
}

function kube-node-admin() {
	NODE=$1
	[[ -n "${NODE}" ]] && read -r -d '' SPEC_AFFINITY <<-EOM
		    "affinity": {
		      "nodeAffinity": {
		        "requiredDuringSchedulingIgnoredDuringExecution": {
		          "nodeSelectorTerms": [
		            {
		              "matchExpressions": [
		                {
		                  "key": "kubernetes.io/hostname",
		                  "operator": "In",
		                  "values": [ "${NODE}" ]
		                }
		              ]
		            }
		          ]
		        }
		      }
		    },
	EOM

	read -r -d '' SPEC_JSON <<EOF
{
  "apiVersion": "v1",
  "spec": {
    ${SPEC_AFFINITY}
    "hostNetwork": true,
    "hostPID": true,
    "containers": [{
      "name": "node-admin",
      "image": "alpine:3",
      "stdin": true,
      "stdinOnce": true,
      "tty": true,
      "volumeMounts": [{
        "name": "hostfs",
        "mountPath": "/hostfs"
      }]
    }],
    "volumes": [{
      "name": "hostfs",
      "hostPath": {
        "path": "/",
        "type": "Directory"
      }
    }]
  }
}
EOF
	kubectl run node-admin --namespace kube-system --privileged -i -t --rm --restart=Never --image=debian:latest --overrides="${SPEC_JSON}"
}

NODE=$(_kube_list_nodes)

kube-node-admin ${NODE}
