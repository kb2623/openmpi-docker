#!/bin/zsh

if [ $# -lt 2 ]; then 
	echo Need 2 arguments
	exit 1
fi

NODE_ID=$1
AUSER=$2
SSL_KEY=$3
HOSTS_FILE=$4

function funHosts {
	cat ${HOSTS_FILE} | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f$2 | head -$(echo $1+1 | bc) | tail -1
}

rm -f NFS_OpenMPI/ssh_key
rm -f NFS_OpenMPI/ssh_key.pub
cp -f ${SSL_KEY} NFS_OpenMPI/ssh_key
cut -d' ' -f1,2 ${SSL_KEY}.pub > NFS_OpenMPI/ssh_key.pub
echo ${AUSER}@$(funHosts $NODE_ID 2) >> NFS_OpenMPI/ssh_key.pub

# TODO create authorized_keys file

