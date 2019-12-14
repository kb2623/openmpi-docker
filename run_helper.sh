#!/bin/zsh

# Generates a command to run docker containter

if [ $# -lt 8 ]; then 
	echo Need 8 arguments
	exit 1
fi

NODE_ID=$1
NETWORK_NAME=$2
HOSTS_FILE=$3
SSH_PORT=$4
NFS_PORT=$5
MPI_DATA_VOLUME=$6
DOCKER_NAME=$7
DOCKER_TAG=$8

hosts=""
cat hosts | while read temp; do
	hosts+="--add-host "$(echo $temp | cut -d' ' -f2)":"$(echo $temp | cut -d' ' -f1)" "
done

command="
docker run --name=node${NODE_ID}_mpi 
	--network=${NETWORK_NAME} 
	--ip=$(cat ${HOSTS_FILE} | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f1 | head -$(echo ${NODE_ID}+1 | bc) | tail -1) 
	${hosts} 
	-p ${SSH_PORT}:22 
	-p ${NFS_PORT}:2049 
	-v ${MPI_DATA_VOLUME}:/mnt/data 
	-d ${DOCKER_NAME}:${DOCKER_TAG}
"
eval $(echo $command | tr -d '\t' | tr '\n' ' ')
