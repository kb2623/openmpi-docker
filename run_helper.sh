#!/bin/zsh

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
MPI_DATA_VOLUME=$5
DOCKER_NAME=$6
DOCKER_TAG=$7

# Helper funcions -----------------------------------------------------------------------
source helper.sh

# Main ----------------------------------------------------------------------------------
hosts=""
cat $HOSTS_FILE | while read temp; do
	hosts+="--add-host "$(fHCutLine $temp 2)":"$(fHCutLine $temp 1)" "
done

command="docker run --name=node${NODE_ID}_mpi"
command+=" --network=${NETWORK_NAME}"
command+=" --ip=$(funHosts ${NODE_ID} 1)"
command+=" --hostname=$(funHosts ${NODE_ID} 2)"
command+=" ${hosts}"
command+=" -p ${SSH_PORT}:22"
command+=" -v ${MPI_DATA_VOLUME}:/mnt/data"
command+=" -d ${DOCKER_NAME}:${DOCKER_TAG}"

eval $command

