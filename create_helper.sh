#!/bin/bash

# Generates a command to run docker containter

# Parameters ----------------------------------------------------------------------------
if [ $# -lt 8 ]; then 
	echo Need 8 arguments
	exit 1
fi

NODE_ID=$1
NETWORK_NAME=$2
HOSTS_FILE=$3
SSH_PORT=$4
DOCKER_VOLUME_SRC=$5
NFS_VOL_NAME=$6
DOCKER_NAME=$7
DOCKER_TAG=$8

# Helper funcions -----------------------------------------------------------------------
source ./helper.sh

# Main ----------------------------------------------------------------------------------
hosts=""

while IFS= read -r line; do
	hosts+="--add-host "$(fHCutLine "${line}" 2)":"$(fHCutLine "${line}" 1)" "
done < ${HOSTS_FILE}

command="docker create --name=${DOCKER_NAME}-${DOCKER_TAG}-node${NODE_ID}_mpi"
command+=" --network=${NETWORK_NAME}"
command+=" --ip="$(fHCutFile ${HOSTS_FILE} ${NODE_ID} 1)
command+=" --hostname="$(fHCutFile ${HOSTS_FILE} ${NODE_ID} 2)
command+=" ${hosts}"
# command+=" --cap-add SYS_ADMIN" # If some bugs enable
# command+=" --privileged=true"   # If some bugs enable
command+=" -p ${SSH_PORT}:22"
command+=" -v ${DOCKER_VOLUME_SRC}:/mnt/data"
command+=" -v ${NFS_VOL_NAME}:/mnt/nfs"
command+=" ${DOCKER_NAME}:${DOCKER_TAG}"

eval ${command}

