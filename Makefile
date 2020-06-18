SHELL:=/bin/bash # Set default shell
export PATH:=$(shell pwd)/.helpers:$(PATH) # Add .helpers sripts

DOCKER_NAME:=openmpi_alpine
DOCKER_TAG:=latest
DOCKER_VOLUME_SRC=/tmp/${DOCKER_NAME}_${DOCKER_NAME}

NODE_ID:=0
HOSTS_FILE:=hosts

# SSH key name prefix
SSH_KEY:=mpicluster
SSH_ALGO:=rsa

# Network data
NETWORK_SUBNET:=164.8.230.0/24
HOST_INTERFACE:=eno1
NETWORK_GW:=164.8.230.1
NETWORK_NAME:=mpinet

# Used OpenMPI version
OPENMPI_VERSION:=4.0.2

# Used ports for container from outside
SSH_PORT:=22

# User data
MPI_USER:=mpiuser
MPI_USER_ID:=1001
MPI_GROUP:=mpiusers
MPI_GROUP_ID:=1001

# User for exec command
EXEC_USER:=${MPI_USER}
# User working dir
EXEC_WORKINGDIR:=/home/${MPI_USER}
# Shell: /bin/zsh /bin/bash /bin/ash /bin/sh
EXEC_SHELL:=/bin/zsh

# NFS
NFS_SERVER:=164.8.230.33
NFS_SHARE:=/mnt/shared
NFS_OPTS:=rw,vers=4,nfsvers=4
NFS_VOL_NAME:=${DOCKER_NAME}-${DOCKER_TAG}-nfs_volume

all:
	-make net
	-make build
	-make create
	-make start

## Volumens ###########################################################################

volume:
	mkdir -p ${DOCKER_VOLUME_SRC}
	chown ${MPI_USER_ID}:${MPI_GROUP_ID} ${DOCKER_VOLUME_SRC}

clean_volume: ${DOCKER_VOLUME_SRC}
	rm -rf ${DOCKER_VOLUME_SRC}

nfs_volume:
	docker volume create --driver local \
		--opt type=nfs \
		--opt o=addr=${NFS_SERVER},${NFS_OPTS} \
		--opt device=:${NFS_SHARE} \
		${NFS_VOL_NAME}

clean_nfs_volume:
	docker volume rm ${NFS_VOL_NAME}

## Network ############################################################################

net:
	docker network create \
		-d macvlan \
		--subnet=${NETWORK_SUBNET} \
		--gateway=${NETWORK_GW} \
		-o parent=${HOST_INTERFACE} \
		${NETWORK_NAME}

clean_net:
	docker network rm ${NETWORK_NAME}

## SSL ################################################################################

sshkey: ${HOSTS_FILE}
	sshkey_helper.sh 1 ${NODE_ID} ${MPI_USER} ${SSH_KEY} ${SSH_ALGO} ${HOSTS_FILE}
	chmod -R 755 sshkeys

clean_sshkey: sshkeys
	sshkey_helper.sh 0

## Final ##############################################################################

build: ${HOSTS_FILE} sshkeys
	cp -f ${HOSTS_FILE} OpenMPI/hosts
	build_helper.sh 1 ${NODE_ID} ${MPI_USER} ${SSH_KEY} ${HOSTS_FILE}
	-chmod -R 755 OpenMPI
	-docker build \
		-t ${DOCKER_NAME}:${DOCKER_TAG} \
		--build-arg NODE_ID=${NODE_ID} \
		--build-arg AUSER=${MPI_USER} \
		--build-arg AUSER_ID=${MPI_USER_ID} \
		--build-arg AGROUP=${MPI_GROUP} \
		--build-arg AGROUP_ID=${MPI_GROUP_ID} \
		--build-arg OPENMPI_VERSION=${OPENMPI_VERSION} \
		OpenMPI
	build_helper.sh 0
	
create: ${HOSTS_FILE}
	create_helper.sh ${NODE_ID} ${NETWORK_NAME} ${HOSTS_FILE} ${SSH_PORT} ${DOCKER_VOLUME_SRC} ${NFS_VOL_NAME} ${DOCKER_NAME} ${DOCKER_TAG}

logs:
	docker logs ${DOCKER_NAME}-${DOCKER_TAG}-node${NODE_ID}_mpi

start:
	docker start ${DOCKER_NAME}-${DOCKER_TAG}-node${NODE_ID}_mpi

exec:
	docker exec -it -u ${EXEC_USER} -w ${EXEC_WORKINGDIR} ${DOCKER_NAME}-${DOCKER_TAG}-node${NODE_ID}_mpi ${EXEC_SHELL}

stop:
	docker stop ${DOCKER_NAME}-${DOCKER_TAG}-node${NODE_ID}_mpi

remove:
	-make stop
	docker container rm ${DOCKER_NAME}-${DOCKER_TAG}-node${NODE_ID}_mpi
	
clean: 
	-make remove
	-docker image rm ${DOCKER_NAME}:${DOCKER_TAG}
	-make clean_net

