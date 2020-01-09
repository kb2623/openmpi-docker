#!/bin/bash

if [ $# -lt 1 ]; then 
	echo Need 1 arguments
	exit 1
fi

OPERATION=$1

if [ ${OPERATION} -eq 0 ]; then
	rm -f OpenMPI/ssh_host_* OpenMPI/authorized_keys OpenMPI/known_hosts OpenMPI/hosts
	exit 0
fi

if [ $# -lt 5 ]; then 
	echo Need 6 arguments
	exit 1
fi

NODE_ID=$2
AUSER=$3
SSH_KEY=$4
HOSTS_FILE=$5

source helper.sh

nname=$(fHCutFile ${HOSTS_FILE} ${NODE_ID} 2)
# Host SSH keys
cp -f sshkeys/${SSH_KEY}.rsa.${nname} OpenMPI/ssh_host_rsa_key
cp -f sshkeys/${SSH_KEY}.rsa.${nname}.pub OpenMPI/ssh_host_rsa_key.pub
cp -f sshkeys/${SSH_KEY}.dsa.${nname} OpenMPI/ssh_host_dsa_key
cp -f sshkeys/${SSH_KEY}.dsa.${nname}.pub OpenMPI/ssh_host_dsa_key.pub
cp -f sshkeys/${SSH_KEY}.ecdsa.${nname} OpenMPI/ssh_host_ecdsa_key
cp -f sshkeys/${SSH_KEY}.ecdsa.${nname}.pub OpenMPI/ssh_host_ecdsa_key.pub
cp -f sshkeys/${SSH_KEY}.ed25519.${nname} OpenMPI/ssh_host_ed25519_key
cp -f sshkeys/${SSH_KEY}.ed25519.${nname}.pub OpenMPI/ssh_host_ed25519_key.pub

# User SSH key
cp -f sshkeys/${SSH_KEY}.${nname}.${AUSER} OpenMPI/id_key
cp -f sshkeys/${SSH_KEY}.${nname}.${AUSER}.pub OpenMPI/id_key.pub

# Generate known_hosts and authorized_keys files
knownHosts=""
autorizedHosts=""

while IFS= read -r line; do
	tnname=$(fHCutLine "${line}" 2)
	autorizedHosts+=$(cut -d' ' -f1,2 sshkeys/${SSH_KEY}.${tnname}.${AUSER}.pub)' '${AUSER}'@'${tnname}'\n'
	knownHosts+=${tnname},$(fHCutLine "${line}" 1)' '$(cut -d' ' -f1,2 sshkeys/${SSH_KEY}.ecdsa.${tnname}.pub)'\n'
done < ${HOSTS_FILE}

echo -e ${autorizedHosts} > OpenMPI/authorized_keys
echo -e ${knownHosts} > OpenMPI/known_hosts

