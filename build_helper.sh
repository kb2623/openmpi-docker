#!/bin/zsh

if [ $# -lt 1 ]; then 
	echo Need 1 arguments
	exit 1
fi

OPERATION=$1

if [ $OPERATION -eq 0 ]; then
	rm -f NFS_OpenMPI/ssh_host_* NFS_OpenMPI/authorized_keys NFS_OpenMPI/known_hosts NFS_OpenMPI/hosts
	exit 0
fi

if [ $# -lt 5 ]; then 
	echo Need 5 arguments
	exit 1
fi

NODE_ID=$2
AUSER=$3
SSH_KEY=$4
HOSTS_FILE=$5

source helper.sh

$nname=$(fHCutFile $HOSTS_FILE $NODE_ID 2)
# Host SSH keys
cp -f sshkeys/$SSH_KEY.rsa.$nname NFS_OpenMPI/ssh_host_rsa_key
cp -f sshkeys/$SSH_KEY.rsa.$nname.pub NFS_OpenMPI/ssh_host_rsa_key.pub
cp -f sshkeys/$SSH_KEY.dsa.$nname NFS_OpenMPI/ssh_host_dsa_key
cp -f sshkeys/$SSH_KEY.dsa.$nname.pub NFS_OpenMPI/ssh_host_dsa_key.pub
cp -f sshkeys/$SSH_KEY.ecdsa.$nname NFS_OpenMPI/ssh_host_ecdsa_key
cp -f sshkeys/$SSH_KEY.ecdsa.$nname.pub NFS_OpenMPI/ssh_host_ecdsa_key.pub
cp -f sshkeys/$SSH_KEY.ed25519.$nname NFS_OpenMPI/ssh_host_ed25519_key
cp -f sshkeys/$SSH_KEY.ed25519.$nname.pub NFS_OpenMPI/ssh_host_ed25519_key.pub

# User SSH key
cp -f sshkeys/$SSH_KEY.$nname.$AUSER NFS_OpenMPI/id_key
cp -f sshkeys/$SSH_KEY.$nname.$AUSER.pub NFS_OpenMPI/id_key.pub

# Generate known_hosts and authorized_keys files
knownHosts=""
autorizedHosts=""
cat ${HOSTS_FILE} | while read temp; do
	tnname=$(fHCutLine $temp 2)
	autorizedHosts+=$(cut -d' ' -f1,2 sshkeys/$SSH_KEY.$tnname.$AUSER.pub)' '$AUSER'@'$tnname'\n'
	# FIXME known_host builder needs fixing
	knownHosts+=$(echo $temp | tr '\t' ' ' | cut -d' ' -f2),$(echo $temp | tr '\t' ' ' | cut -d' ' -f1)' '$(cut -d' ' -f1,2 $SSH_KEY.ecdsa.pub)'\n'
done
echo $autorizedHosts > NFS_OpenMPI/authorized_keys
echo $knownHosts > NFS_OpenMPI/known_hosts
