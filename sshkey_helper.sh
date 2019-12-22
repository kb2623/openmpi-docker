#!/bin/bash

if [ $# -lt 1 ]; then 
	echo Need 1 arguments
	exit 1
fi

OPERATION=$1

if [ ${OPERATION} -eq 0 ]; then
	rm -rf sshkeys
	exit 0
fi

if [ $# -lt 5 ]; then 
	echo Need 5 arguments
	exit 1
fi

NODE_ID=$2
AUSER=$3
SSH_KEY=$4
SSH_ALGO=$5
HOSTS_FILE=$6

source ./helper.sh

mkdir sshkeys
while IFS= read -r line; do
	nname=$(fHCutLine ${line} 2)
	ssh-keygen -t rsa -N '' -C $(echo 'root@'${nname}) -f sshkeys/${SSH_KEY}.rsa.${nname}
	ssh-keygen -t dsa -N '' -C $(echo 'root@'${nname}) -f sshkeys/${SSH_KEY}.dsa.${nname}
	ssh-keygen -t ecdsa -N '' -C $(echo 'root@'${nname}) -f sshkeys/${SSH_KEY}.ecdsa.${nname}
	ssh-keygen -t ed25519 -N '' -C $(echo 'root@'${nname}) -f sshkeys/${SSH_KEY}.ed25519.${nname}
	ssh-keygen -t ${SSH_ALGO} -N '' -C $(echo ${AUSER}'@'${nname}) -f sshkeys/${SSH_KEY}.${nname}.${AUSER}
done < ${HOSTS_FILE}
