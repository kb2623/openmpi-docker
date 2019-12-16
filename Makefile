DOCKER_NAME:=nfs_mpi_alpine
DOCKER_TAG:=latest

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
RPC_PORT:=111
NFS_PORT:=2049

# User data
MPI_USER:=mpiuser
MPI_USER_ID:=1001
MPI_GROUP:=mpiusers
MPI_GROUP_ID:=1001
# For NFS dir
MPI_DATA_VOLUME:=/home/mpiuser

# User for exec command
EXEC_USER:=${MPI_USER}
# Shell: /bin/zsh /bin/bash /bin/ash /bin/sh
EXEC_SHELL:=/bin/zsh

all:
	-make net
	-make build
	-make run

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
	-chmod a+x sshkey_helper.sh
	./sshkey_helper.sh 1 ${NODE_ID} ${MPI_USER} ${SSH_KEY} ${SSH_ALGO} ${HOSTS_FILE}
	chmod -R 755 sshkeys

clean_sshkey: sshkeys
	-chmod a+x sshkey_helper.sh
	./sshkey_helper.sh 0

## Final ##############################################################################

build: ${HOSTS_FILE} sshkeys
	cp ${HOSTS_FILE} NFS_OpenMPI/hosts
	-chmod a+x build_helper.sh
	./build_helper.sh 1 ${NODE_ID} ${MPI_USER} ${SSH_KEY} ${HOSTS_FILE}
	-chmod -R 755 NFS_OpenMPI
	-docker build \
		-t ${DOCKER_NAME}:${DOCKER_TAG} \
		--build-arg NODE_ID=${NODE_ID} \
		--build-arg AUSER=${MPI_USER} \
		--build-arg AUSER_ID=${MPI_USER_ID} \
		--build-arg AGROUP=${MPI_GROUP} \
		--build-arg AGROUP_ID=${MPI_GROUP_ID} \
		--build-arg OPENMPI_VERSION=${OPENMPI_VERSION} \
		NFS_OpenMPI
	./build_helper.sh 0
	
run: ${HOSTS_FILE}
	-chmod a+x run_helper.sh
	./run_helper.sh ${NODE_ID} ${NETWORK_NAME} ${HOSTS_FILE} ${SSH_PORT} ${RPC_PORT} ${NFS_PORT} ${MPI_DATA_VOLUME} ${DOCKER_NAME} ${DOCKER_TAG}

logs:
	docker logs node${NODE_ID}_mpi

start:
	docker start node${NODE_ID}_mpi

exec:
	docker exec -it -u ${EXEC_USER} node${NODE_ID}_mpi ${EXEC_SHELL}

stop:
	docker stop node${NODE_ID}_mpi

remove:
	-make stop
	docker container rm node${NODE_ID}_mpi
	
clean: 
	-make remove
	-docker image rm ${DOCKER_NAME}:${DOCKER_TAG}
	-make clean_net

