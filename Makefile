DOCKER_NAME:=nfs_mpi_alpine
DOCKER_TAG:=latest

NODE_ID:=0

HOSTS_FILE:=hosts
NETWORK_SUBNET:=164.8.230.0/24
HOST_INTERFACE:=eth0
NETWORK_GW:=164.8.230.1
NETWORK_NAME:=mpinet

SSH_PORT:=22
NFS_PORT:=2049

SSL_PROTECTION=dsa
SSL_KEY:=id_dsa.mpi
SSL_PASSPHRASE:=mpiuser

MPI_USER:=mpiuser
MPI_USER_ID:=1002
MPI_GROUP:=mpiusers
MPI_GROUP_ID:=1002

# User
EXEC_UESR:=${MPI_USER}
# Shell: /bin/zsh /bin/bash /bin/ash /bin/sh
EXEC_SHELL:=/bin/zsh

## Network ############################################################################

net:
	echo -e "\nDocker network->create=>${NETWORK_NAME}\n"
	docker network create \
		-d macvlan \
		--subnet=${NETWORK_SUBNET} \
		--gateway=${NETWORK_GW} \
		-o parent=${HOST_INTERFACE} \
		${NETWORK_NAME}

clean_net:
	echo -e "\nDocker network->clean=>${NETWORK_NAME}\n"
	docker network rm ${NETWORK_NAME}

## SSL ################################################################################

sslkey:
	echo -e "\ncreting ${SSL_KEY} key\n"
	ssh-keygen -t ${SSL_PROTECTION} -N ${SSL_PASSPHRASE} -f ${SSL_KEY}
	chmod -R 757 ${SSL_KEY} ${SSL_KEY}.pub

clean_sslkey: ${SSL_KEY} ${SSL_KEY}.pub
	echo -e "\nDelitin ${SSL_KEY}\n"
	rm ${SSL_KEY} ${SSL_KEY}.pub

## Final ##############################################################################

build: ${HOSTS_FILE} ${SSL_KEY} ${SSL_KEY}.pub
	echo -e "\nDocker build=>${DOCKER_NAME}:${DOCKER_TAG}\n"
	cp ${HOSTS_FILE} NFS_OpenMPI/hosts
	-chmod -R 755 NFS_OpenMPI
	-rm -rf NFS_OpenMPI/.ssh
	mkdir -p NFS_OpenMPI/.ssh
	cp ${SSL_KEY} NFS_OpenMPI/.ssh/${SSL_KEY}
	cp ${SSL_KEY}.pub NFS_OpenMPI/.ssh/${SSL_KEY}.pub
	cp ${SSL_KEY}.pub NFS_OpenMPI/.ssh/authorized_keys
	docker build -t ${DOCKER_NAME}:${DOCKER_TAG} --build-arg NODE_ID=${NODE_ID} NFS_OpenMPI
	
run:
	echo -e "\nDocker run=>${DOCKER_NAME}:${DOCKER_TAG}\n"
	-make build
	docker run --name=node${NODE_ID}_mpi \
		-p ${SSH_SOURCE_PORT}:22 \
		-p ${NFS_SOURCE_PORT}:2049 \
		-d ${DOCKER_NAME}:${DOCKER_TAG}

runnet:
	echo -e "\nDocker run=>${DOCKER_NAME}:${DOCKER_TAG}@${NETWORK_NAME}\n"
	-make net
	-make build
	docker run --name=node${NODE_ID}_mpi \
		--network=${NETWORK_NAME} \
		--ip=$(cat ${HOSTS_FILE} | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f1 | head -${NODE_ID} | tail -1) \
		-p ${SSH_PORT}:22 \
		-p ${NFS_PORT}:2049 \
		-d ${DOCKER_NAME}:${DOCKER_TAG}

exec:
	echo -e "\nDocker exec->/bin/zsh@${DOCKER_NAME}:${DOCKER_TAG}@${EXEC_UESR}\n"
	docker exec -it -u ${EXEC_UESR} node${NODE_ID}_mpi ${EXEC_SHELL}

stop:
	echo -e "\nDocker stop ${DOCKER_NAME}:${DOCKER_TAG}\n"
	docker stop ${DOCKER_NAME}:${DOCKER_TAG}
	
clean: 
	echo -e "\nDocker rm=>${DOCKER_NAME}:${DOCKER_TAG}\n"
	-make stop
	-rm NFS_OpenMPI/hosts
	-rm -rf NFS_OpenMPI/.ssh/

