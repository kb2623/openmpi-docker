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
	echo Need 1 arguments
	exit 1
fi

NODE_ID=$2
AUSER=$3
SSH_KEY=$4
HOSTS_FILE=$5

function funHosts {
	cat ${HOSTS_FILE} | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f$2 | head -$(echo $1+1 | bc) | tail -1
}

cp -f $SSH_KEY.rsa NFS_OpenMPI/ssh_host_rsa_key
echo -e $(cut -d' ' -f1,2 $SSH_KEY.rsa.pub)$AUSER'@'$(funHosts $NODE_ID 2) > NFS_OpenMPI/ssh_host_rsa_key.pub
cp -f $SSH_KEY.dsa NFS_OpenMPI/ssh_host_dsa_key
echo -e $(cut -d' ' -f1,2 $SSH_KEY.dsa.pub)$AUSER'@'$(funHosts $NODE_ID 2) > NFS_OpenMPI/ssh_host_dsa_key.pub
cp -f $SSH_KEY.ecdsa NFS_OpenMPI/ssh_host_ecdsa_key
echo -e $(cut -d' ' -f1,2 $SSH_KEY.ecdsa.pub)$AUSER'@'$(funHosts $NODE_ID 2) > NFS_OpenMPI/ssh_host_ecdsa_key.pub
cp -f $SSH_KEY.ed25519 NFS_OpenMPI/ssh_host_ed25519_key
echo -e $(cut -d' ' -f1,2 $SSH_KEY.ed25519.pub)$AUSER'@'$(funHosts $NODE_ID 2) > NFS_OpenMPI/ssh_host_ed25519_key.pub

knownHosts=""
autorizedHosts=""
cat hosts | while read temp; do
	autorizedHosts+=$(cut -d' ' -f1,2 $SSH_KEY.ecdsa.pub)' '$AUSER'@'$(echo $temp | cut -d' ' -f2)'\n'
	knownHosts+=$(echo $temp | cut -d' ' -f2),$(echo $temp | cut -d' ' -f1)' '$(cut -d' ' -f1,2 $SSH_KEY.ecdsa.pub)'\n'
done
echo $autorizedHosts > NFS_OpenMPI/authorized_keys
echo $knownHosts > NFS_OpenMPI/known_hosts
