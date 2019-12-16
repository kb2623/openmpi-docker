#!/bin/zsh

# Generates a command to run docker containter

if [ $# -lt 9 ]; then 
	echo Need 9 arguments
	exit 1
fi

NODE_ID=$1
NETWORK_NAME=$2
HOSTS_FILE=$3
SSH_PORT=$4
RPC_PORT=$5
NFS_PORT=$6
MPI_DATA_VOLUME=$7
DOCKER_NAME=$8
DOCKER_TAG=$9

function funHosts {
	cat ${HOSTS_FILE} | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f$2 | head -$(echo $1+1 | bc) | tail -1
}

hosts=""
cat hosts | while read temp; do
	hosts+="--add-host "$(echo $temp | cut -d' ' -f2)":"$(echo $temp | cut -d' ' -f1)" "
done

command="
docker run --name=node${NODE_ID}_mpi 
	--network=${NETWORK_NAME} 
	--ip=$(funHosts ${NODE_ID} 1)
	--hostname=$(funHosts ${NODE_ID} 2)
	${hosts} 
	-p ${SSH_PORT}:22 
	-p ${RPC_PORT}:111
	-p ${NFS_PORT}:2049 
	-v ${MPI_DATA_VOLUME}:/mnt/data 
	-d ${DOCKER_NAME}:${DOCKER_TAG}
"
eval $(echo $command | tr -d '\t' | tr '\n' ' ')
