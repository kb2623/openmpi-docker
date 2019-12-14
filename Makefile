DOCKER_NAME:=nfs_mpi_alpine
DOCKER_TAG:=latest

NODE_ID:=0

HOSTS_FILE:=hosts
NETWORK_SUBNET:=164.8.230.0/24
HOST_INTERFACE:=eno1
NETWORK_GW:=164.8.230.1
NETWORK_NAME:=mpinet

SSH_PORT:=22
NFS_PORT:=2049

SSL_PROTECTION=dsa
SSL_KEY:=id_dsa.mpi
SSL_PASSPHRASE:=mpiuser

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

sslkey:
	ssh-keygen -t ${SSL_PROTECTION} -N ${SSL_PASSPHRASE} -f ${SSL_KEY}
	chmod -R 757 ${SSL_KEY} ${SSL_KEY}.pub

clean_sslkey: ${SSL_KEY} ${SSL_KEY}.pub
	rm ${SSL_KEY} ${SSL_KEY}.pub

## Final ##############################################################################

build: ${HOSTS_FILE} ${SSL_KEY} ${SSL_KEY}.pub
	cp ${HOSTS_FILE} NFS_OpenMPI/hosts
	-chmod -R 755 NFS_OpenMPI
	-rm -rf NFS_OpenMPI/.ssh
	mkdir -p NFS_OpenMPI/.ssh
	cp ${SSL_KEY} NFS_OpenMPI/.ssh/${SSL_KEY}
	cp ${SSL_KEY}.pub NFS_OpenMPI/.ssh/${SSL_KEY}.pub
	cp ${SSL_KEY}.pub NFS_OpenMPI/.ssh/authorized_keys
	docker build \
		-t ${DOCKER_NAME}:${DOCKER_TAG} \
		--build-arg NODE_ID=${NODE_ID} \
		--build-arg AUSER=${MPI_USER} \
		--build-arg AUSER_ID=${MPI_USER_ID} \
		--build-arg AGROUP=${MPI_GROUP} \
		--build-arg AGROUP_ID=${MPI_GROUP_ID} \
		NFS_OpenMPI
	
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

