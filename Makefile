DOCKER_NAME:=openmpidocker
DOCKER_TAG:=latest

NODE_ID:=0
HOSTS_FILE:=hosts
NETWORK_SUBNET:=192.168.1.0/24
HOST_INTERFACE:=eth0
NETWORK_GW:=192.168.1.1
NETWORK_NAME:=mpinet
SORCE_PORT:=22
DESTINATION_PORT:=22

SSL_PROTECTION=dsa
SSL_KEY:=id_dsa.mpi
SSL_PASSPHRASE:=mpiuser

MPI_USER:=mpiuser
MPI_USER_ID:=1002
MPI_GROUP:=mpiusers
MPI_GROUP_ID:=1002

all: build run

sslkey:
	echo "creting ${SSL_KEY} key"
	ssh-keygen -t ${SSL_PROTECTION} -N ${SSL_PASSPHRASE} -f ${SSL_KEY}
	chmod -R 757 ${SSL_KEY} ${SSL_KEY}.pub

createnet:
	echo "creating network"
	docker network create \
		-d macvlan \
		--subnet=${NETWORK_SUBNET} \
		--gateway=${NETWORK_GW} \
		-o parent=${HOST_INTERFACE} \
		${NETWORK_NAME}

buildS1:
	echo "Build node"
	cp ${HOSTS_FILE} OpenMPI_Stage1/hosts
ifdef MASTER
	docker build -t ${DOCKER_NAME}_s1:${DOCKER_TAG} --build-arg MASTER_NODE=true OpenMPI_Stage1
else
	docker build -t ${DOCKER_NAME}_s1:${DOCKER_TAG} OpenMPI_Stage1
endif

build: ${HOSTS_FILE} ${SSL_KEY} ${SSL_KEY}.pub
	echo "BUILDING"
	-make buildS1
	-chmod -R 755 /OpenMPI_Stage1
	-rm -rf OpenMPI_Stage2/.ssh
	mkdir -p OpenMPI_Stage2/.ssh
	cp ${SSL_KEY} OpenMPI_Stage2/.ssh/${SSL_KEY}
	cp ${SSL_KEY}.pub OpenMPI_Stage2/.ssh/${SSL_KEY}.pub
	cp ${SSL_KEY}.pub OpenMPI_Stage2/.ssh/authorized_keys
ifdef MASTER
	docker build -t ${DOCKER_NAME}:${DOCKER_TAG} --build-arg BASE_CONTAINER=${DOCKER_NAME}_s1:${DOCKER_TAG} --build-arg MASTER_NODE=true OpenMPI_Stage2
else
	docker build -t ${DOCKER_NAME}:${DOCKER_TAG} --build-arg BASE_CONTAINER=${DOCKER_NAME}_s1:${DOCKER_TAG} --build-arg MASTER_NODE=false OpenMPI_Stage2
endif
		
run:
	# TODO
	
runnet: ${HOSTS_FILE}
	-make build
	-make makenet
	docker run --name=niapyorg-server \
		--network=${NETWORK_NAME} \
		--ip=$(cat ${HOSTS_FILE} | tr ' ' '\t' | tr -d ' ' | cut -d$'\t' -f1 | head -${NODE_ID} | tail -1) \
		-p ${SORCE_PORT}:${DESTINATION_PORT} \
		-d niapyorg:${NIAORG_TAG}

clean_sslkey: ${SSL_KEY} ${SSL_KEY}.pub
	rm ${SSL_KEY} ${SSL_KEY}.pub

clean: 
	-docker image rm ${DOCKER_NAME}_s1:${DOCKER_TAG}
	-rm OpenMPI_Stage1/hosts
	-rm -rf OpenMPI_Stage2/.ssh/
