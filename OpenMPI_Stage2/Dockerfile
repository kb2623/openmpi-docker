ARG BASE_CONTAINER=openmpidocker_s1:latest
FROM $BASE_CONTAINER

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>"
LABEL description="Final OpenMPI image"

ARG NODE_ID=0
ARG NFS_DATA_DIR=/mnt/nfs/nfs-data
ARG AUSER=mpiuser
ARG AUSER_ID=1002
ARG AGROUP=mpisers
ARG AGROUP_ID=1002
ARG AHOME=/home/mpiuser
ARG WORD_DIR=${AHOME}/mpidir

USER root
WORKDIR /root

ADD createuser.sh /root

RUN chmod a+rx createuser.sh && \
	chmod g+w /etc/passwd

# Create user
RUN ./createuser.sh $AUSER $AUSER_ID $AGROUP $AGROUP_ID $AHOME && \
	echo "AllowUsers %s" >> /etc/ssh/sshd_config ${AUSER}

USER $AUSER_ID
WORKDIR $AHOME

ADD .ssh $AHOME

RUN chmod -R 755 .ssh

# NFS client setup
RUN mkdir -p ${WORD_DIR} && mount $(cat /root/hosts | tr ' ' '\t' | tr -d ' ' | cut -d$'\t' -f1 | head -1)${NFS_DATA_DIR} ${WORD_DIR}
