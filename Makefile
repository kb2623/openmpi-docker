DOCKER_NAME:=nfs_mpi_alpine
DOCKER_TAG:=latest
OPENMPI_VERSION:=4.0.2

NODE_ID:=0

HOSTS_FILE:=hosts
NETWORK_SUBNET:=164.8.230.0/24
HOST_INTERFACE:=eno1
NETWORK_GW:=164.8.230.1
NETWORK_NAME:=mpinet

NFS_PORT:=2049

SSH_PORT:=22
SSH_KEY:=mpicluster

MPI_USER:=mpiuser
MPI_USER_ID:=1001
MPI_GROUP:=mpiusers
MPI_GROUP_ID:=1001
MPI_DATA_VOLUME:=/home/mpiuser

# User
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

sshkey:
	ssh-keygen -t rsa -N '' -f ${SSH_KEY}.rsa
	ssh-keygen -t dsa -N '' -f ${SSH_KEY}.dsa
	ssh-keygen -t ecdsa -N '' -f ${SSH_KEY}.ecdsa
	ssh-keygen -t ed25519 -N '' -f ${SSH_KEY}.ed25519
	chmod -R 755 ${SSH_KEY}*

clean_sshkey: ${SSH_KEY}
	-rm ${SSH_KEY}.rsa*
	-rm ${SSH_KEY}.dsa*
	-rm ${SSH_KEY}.ecdsa*
	-rm ${SSH_KEY}.ed25519*

## Final ##############################################################################

build: ${HOSTS_FILE} ${SSH_KEY}.rsa* ${SSH_KEY}.dsa* ${SSH_KEY}.ecdsa* ${SSH_KEY}.ed25519*
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
	./run_helper.sh ${NODE_ID} ${NETWORK_NAME} ${HOSTS_FILE} ${SSH_PORT} ${NFS_PORT} ${MPI_DATA_VOLUME} ${DOCKER_NAME} ${DOCKER_TAG}

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
	-rm NFS_OpenMPI/hosts
	-rm -rf NFS_OpenMPI/.ssh/

