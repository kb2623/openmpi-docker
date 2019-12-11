DOCKER_NAME:=nfs_mpi_alpine
DOCKER_TAG:=latest

NODE_ID:=1

HOSTS_FILE:=hosts
NETWORK_SUBNET:=164.8.230.0/24
HOST_INTERFACE:=eth0
NETWORK_GW:=164.8.230.1
NETWORK_NAME:=mpinet

SSH_SOURCE_PORT:=22
NFS_SOURCE_PORT:=2049

SSL_PROTECTION=dsa
SSL_KEY:=id_dsa.mpi
SSL_PASSPHRASE:=mpiuser

MPI_USER:=mpiuser
MPI_USER_ID:=1002
MPI_GROUP:=mpiusers
MPI_GROUP_ID:=1002

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

## Stage1 #############################################################################

build_s1:
	echo -e "\nDocker build=>${DOCKER_NAME}_s1:${DOCKER_TAG}\n"
	-chmod -R 755 /OpenMPI_Stage1
	cp ${HOSTS_FILE} OpenMPI_Stage1/hosts
	docker build -t ${DOCKER_NAME}_s1:${DOCKER_TAG} --build-arg NODE_ID=${NODE_ID} OpenMPI_Stage1
	
run_s1:
	echo -e "\nDocker run=>${DOCKER_NAME}_s1:${DOCKER_TAG}\n"
	docker run --name=node${NODE_ID}_mpi_s1 \
		-p ${SSH_SOURCE_PORT}:22 \
		-p ${NFS_SOURCE_PORT}:2049 \
		-d ${DOCKER_NAME}_s1:${DOCKER_TAG}

runnet_s1:
	echo -e "\nDocker run=>${DOCKER_NAME}_s:${DOCKER_TAG}@${NETWORK_NAME}\n"
	-make net
	-make build_s1
	docker run --name=node${NODE_ID}_mpi_s1 \
		--network=${NETWORK_NAME} \
		--ip=$(cat ${HOSTS_FILE} | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f1 | head -${NODE_ID} | tail -1) \
		-p ${SSH_SOURCE_PORT}:22 \
		-p ${NFS_SOURCE_PORT}:2049 \
		-d ${DOCKER_NAME}_s1:${DOCKER_TAG}

exec_zsh_s1:
	echo -e "\nDocker exec->/bin/zsh@${DOCKER_NAME}_s1:${DOCKER_TAG}\n"
	docker exec -it node${NODE_ID}_mpi_s1 /bin/zsh

stop_s1:
	echo -e "\nDocker stop ${DOCKER_NAME}_s1:${DOCKER_TAG}\n"
	docker stop ${DOCKER_NAME}_s1:${DOCKER_TAG}

clean_s1:
	echo -e "\nDocker rm=>${DOCKER_NAME}_s1:${DOCKER_TAG}\n"
	-make stop_s1
	docker image rm ${DOCKER_NAME}_s1:${DOCKER_TAG}

## Final ##############################################################################

build: ${HOSTS_FILE} ${SSL_KEY} ${SSL_KEY}.pub
	echo -e "\nDocker build=>${DOCKER_NAME}:${DOCKER_TAG}\n"
	-make build_s1
	-chmod -R 755 /OpenMPI_Stage2
	-rm -rf OpenMPI_Stage2/.ssh
	mkdir -p OpenMPI_Stage2/.ssh
	cp ${SSL_KEY} OpenMPI_Stage2/.ssh/${SSL_KEY}
	cp ${SSL_KEY}.pub OpenMPI_Stage2/.ssh/${SSL_KEY}.pub
	cp ${SSL_KEY}.pub OpenMPI_Stage2/.ssh/authorized_keys
	docker build -t ${DOCKER_NAME}:${DOCKER_TAG} --build-arg BASE_CONTAINER=${DOCKER_NAME}_s1:${DOCKER_TAG} --build-arg NODE_ID=${NODE_ID} OpenMPI_Stage2
	
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
		-p ${SSH_SOURCE_PORT}:22 \
		-p ${NFS_SOURCE_PORT}:2049 \
		-d ${DOCKER_NAME}:${DOCKER_TAG}

exec_zsh:
	echo -e "\nDocker exec->/bin/zsh@${DOCKER_NAME}:${DOCKER_TAG}\n"
	docker exec -it node${NODE_ID}_mpi /bin/zsh

stop:
	echo -e "\nDocker stop ${DOCKER_NAME}_s1:${DOCKER_TAG}\n"
	docker stop ${DOCKER_NAME}_s1:${DOCKER_TAG}
	
clean: 
	echo -e "\nDocker rm=>${DOCKER_NAME}:${DOCKER_TAG}\n"
	-make stop
	-make clean_s1
	-rm OpenMPI_Stage1/hosts
	-rm -rf OpenMPI_Stage2/.ssh/

