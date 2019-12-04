DOCKER_NAME:=openmpidocker
DOCKER_TAG:=latest

NETWORK_SUBNET:=192.168.1.0/24
NETWORK_IP:=192.168.1.101
HOST_INTERFACE:=eth0
NETWORK_GW:=192.168.1.1
NETWORK_NAME:=mpinet
SORCE_PORT:=22
DESTINATION_PORT:=22

SSH_PROTECTION=dsa
SSH_KEY:=id_dsa.mpi
SSH_PASSPHRASE:=mpiuser

HOSTS_FILE:=hosts

MPI_USER:=mpiuser
MPI_USER_ID:=1002
MPI_GROUP:=mpiusers
MPI_GROUP_ID:=1002

all: build run

sshkey:
	ssh-keygen -t ${SSH_PROTECTION} -N ${SSH_PASSPHRASE} -f ${SSH_KEY}
	
createnet:
	docker network create \
		-d macvlan \
		--subnet=${NETWORK_SUBNET} \
		--gateway=${NETWORK_GW} \
		-o parent=${HOST_INTERFACE} \
		${NETWORK_NAME}

buildS1: ${SSH_KEY} ${SSH_KEY}.pub ${HOSTS_FILE}
	-cp ${SSH_KEY} OpenMPI_Stage1/.ssh
	-cp ${SSH_KEY}.pub OpenMPI_Stage1/.ssh
	-cp ${SSH_KEY}.pub OpenMPI_Stage1/.ssh/authorized_keys
	-cp ${HOSTS_FILE} OpenMPI_Stage1/hosts
ifdef MASTER
		docker build -t ${DOCKER_NAME}_s1:${DOCKER_TAG} --build-arg MASTER_NODE=true OpenMPI_Stage1
else
		docker build -t ${DOCKER_NAME}_s1:${DOCKER_TAG} OpenMPI_Stage1
endif

build:
	-make buildS1
ifdef MASTER
	docker build -t ${DOCKER_NAME}:${DOCKER_TAG} --build-arg BASE_CONTAINER=${DOCKER_NAME}_s1:${DOCKER_TAG} --build-arg MASTER_NODE=true OpenMPI_Stage2
else
	docker build -t ${DOCKER_NAME}:${DOCKER_TAG} --build-arg BASE_CONTAINER=${DOCKER_NAME}_s1:${DOCKER_TAG} --build-arg MASTER_NODE=false OpenMPI_Stage2
endif
		
run:
	# TODO
	
runnet:
	-make build
	-make makenet
	docker run --name=niapyorg-server \
		--network=${NETWORK_NAME} \
		--ip=${NETWORK_IP} \
		-p ${SORCE_PORT}:${DESTINATION_PORT} \
		-d niapyorg:${NIAORG_TAG}

cleansslkey: ${SSH_KEY} ${SSH_KEY}.pub
	rm ${SSH_KEY}
	rm ${SSH_KEY}.pub

cleanM:
	# TODO
	
cleanN:
	# TODO
	
clean:
	-make cleanM
	-make cleanN
