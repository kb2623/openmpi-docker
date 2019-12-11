ARG BASE_CONTAINER=openmpidocker_s1:latest
FROM $BASE_CONTAINER

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>"
LABEL description="Final OpenMPI image"
LABEL source="https://github.com/kb2623/openmpi-docker"

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
	echo "AllowUsers %s" >> /etc/ssh/sshd_config ${AUSER} && \
	cp /root/hosts ${AHOME}/hosts && \
	chown ${AUSER}:${AGROUP} ${AHOME}/hosts && \
	chmod a+r ${AHOME}/hosts

USER $AUSER
WORKDIR $AHOME

RUN mkdir -p ${AHOME}/.ssh
ADD .ssh ${AHOME}

CMD [${AUSER}, ${AGROUP}, ${WORD_DIR}]

# Fix premissions
RUN chmod -R 755 .ssh
