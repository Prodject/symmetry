#!/usr/bin/env bash
set -e;

# https://jtway.co/kubernetes-auth-google-with-rbac-60a74787e6a5https://jtway.co/kubernetes-auth-google-with-rbac-60a74787e6a5
function _install_kubernetes() {

	local KADMIN_USER="admin";
	local KADMIN_PASSWD="TjIUVz7gAqZeLTaVmaau";


	case $(__symmetry_platform) in
		ubuntu|debian)
			source $HOME/.symmetry/functions/system.debian.bash;

			if ! command -v docker > /dev/null; then
				(>&2 echo "Docker should be installed before kubernetes");
				exit 1;
			fi
			sudo apt update;

			# if [ "$1" -eq "reset" ]; then
			sudo kubeadm reset;
			if [ -f "$HOME/.kube/config" ]; then
				rm $HOME/.kube/config;
			fi
			# fi
			local kubernetes_version=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt);
			echo "downloading kubectl version $kubernetes_version";
			curl -sLO https://storage.googleapis.com/kubernetes-release/release/$kubernetes_version/bin/linux/amd64/kubectl;
			chmod +x kubectl;
			sudo mv kubectl /usr/local/bin/;

			echo "installing kops $kubernetes_version";
			curl -sLO https://github.com/kubernetes/kops/releases/download/${kubernetes_version}/kops-linux-amd64;
			chmod +x kops-linux-amd64;
			sudo mv kops-linux-amd64 /usr/local/bin/kops;


			sudo apt install apt-transport-https -y;
			curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -;
			echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null;

			sudo apt update;
			echo "installing kubadm and kubelet";
			sudo apt install kubelet kubeadm -y;
			echo "initializing...";

			sudo kubeadm init --pod-network-cidr=192.168.0.0/16;


			# ktoken_data=$(sudo kubeadm init --pod-network-cidr=192.168.0.0/16);
			# kubeadm join --token cc7782.faf6b5e82250d4df 192.168.2.12:6443
			#ktoken=$(echo $ktoken_data | grep 'kubeadm join --token' | awk '{ print $4 }');
			#kmaster=$(echo $ktoken_data | grep 'kubeadm join --token' | awk '{ print $5 }');

			mkdir -p $HOME/.kube;
			if [ ! -f "$HOME/.kube/config" ]; then
			  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config;
			  sudo chown $(id -u):$(id -g) $HOME/.kube/config;
			fi

			kubectl apply -f "http://docs.projectcalico.org/v2.3/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml" --validate=false;

			kubectl taint nodes --all node-role.kubernetes.io/master-;

			# echo -e "To join nodes to this cluster run:\n\tkubeadm join --token $ktoken $kmaster";
			echo "installing kubernetes dashboard...";

			kubectl create -f https://git.io/kube-dashboard --validate=false;

			kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

			if [ ! -z "${KUBE_AUTH_GOOGLE_CLIENT_ID}" ]; then
				echo "applying the google authentication to the api server configuration.";
				sudo sed -i "/- kube-apiserver/a\    - --oidc-issuer-url=https://accounts.google.com\n    - --oidc-username-claim=email\n    - --oidc-client-id=$KUBE_AUTH_GOOGLE_CLIENT_ID" /etc/kubernetes/manifests/kube-apiserver.yaml;
			fi
			if [ ! -z $KUBE_BASIC_AUTH_FILE ]; then
				echo "applying the basic authentication file to the api server configuration.";
				sudo sed -i "/- kube-apiserver/a\    - --basic-auth-file=$KUBE_BASIC_AUTH_FILE" /etc/kubernetes/manifests/kube-apiserver.yaml;
			fi
		;;
		*)
			(>&2 echo "Unsupported platform: $(__symmetry_platform)");
			exit 1;
		;;
	esac

}

_install_kubernetes;
