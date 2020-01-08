#!/bin/bash

# Generates a command to run docker containter

# Parameters ----------------------------------------------------------------------------
if [ $# -lt 7 ]; then 
	echo Need 7 arguments
	exit 1
fi

NODE_ID=$1
NETWORK_NAME=$2
HOSTS_FILE=$3
SSH_PORT=$4
DOCKER_VOLUME_SRC=$5
DOCKER_NAME=$6
DOCKER_TAG=$7

# Helper funcions -----------------------------------------------------------------------
source ./helper.sh

# Main ----------------------------------------------------------------------------------
hosts=""

while IFS= read -r line; do
	hosts+="--add-host "$(fHCutLine "${line}" 2)":"$(fHCutLine "${line}" 1)" "
done < ${HOSTS_FILE}

command="docker run --name=node${NODE_ID}_mpi"
command+=" --network=${NETWORK_NAME}"
command+=" --ip="$(fHCutFile ${HOSTS_FILE} ${NODE_ID} 1)
command+=" --hostname="$(fHCutFile ${HOSTS_FILE} ${NODE_ID} 2)
command+=" --cap-add SYS_ADMIN"
command+=" ${hosts}"
command+=" -p ${SSH_PORT}:22"
command+=" -p 2049:2049"
command+=" -v ${DOCKER_VOLUME_SRC}:/mnt/data"
command+=" -d ${DOCKER_NAME}:${DOCKER_TAG}"

eval ${command}

