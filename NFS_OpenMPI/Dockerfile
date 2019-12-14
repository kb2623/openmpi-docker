## STAGE 0 ###########################################################################

ARG BASE_CONTAINER=alpine:3.10
FROM $BASE_CONTAINER AS nfs4_openmpi_node_base

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>"
LABEL description="Alpine computing Node for OpenMPI with NFS server base image"
LABEL source="https://github.com/kb2623/openmpi-docker"

ARG OPENMPI_VERSION=4.0.2

ENV USPACE_APPS=/usr/local

USER root
WORKDIR /root

RUN mkdir -p /etc/skel
ADD sshd_config /etc/ssh/
ADD ssh_key /etc/ssh/
ADD ssh_key.pub /etc/ssh/
ADD authorized_keys /etc/ssh/
ADD hosts /root 
ADD .zshrc /etc/skel
ADD .profile /etc/skel
ADD .bashrc /etc/skel

# Fix file privilages
RUN chmod a+rx hosts && \
	chmod g+w /etc/passwd

# Add configurations to root user
RUN cp -f /etc/skel/.bashrc /root/.bashrc && \
	cp -f /etc/skel/.zshrc /root/.zshrc && \
	cp -f /etc/skel/.profile /root/.profile

# Update the system and install programs
RUN apk update && \
	apk add zsh bash tmux git build-base perl linux-headers nfs-utils openssh && \
	ssh-keygen -A && \
	rm -rf /var/cache/apk/*

# Install OpenMPI
RUN wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-$OPENMPI_VERSION.tar.bz2 && \
	tar -xvf openmpi-$OPENMPI_VERSION.tar.bz2 && \
	cd openmpi-$OPENMPI_VERSION && \
	./configure --prefix=$USPACE_APPS && \
	make && \
	make install && \
	cd .. && \
	rm openmpi-$OPENMPI_VERSION.tar.bz2 && \
	rm -rf openmpi-$OPENMPI_VERSION

## STAGE 1 ###########################################################################

FROM nfs4_openmpi_node_base

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>"
LABEL description="Alpine computing Node for OpenMPI with NFS server final image"
LABEL source="https://github.com/kb2623/openmpi-docker"

ARG NODE_ID=0
ARG NFS_DATA_DIR=/mnt/nfs/nfs-data
ARG AUSER=mpiuser
ARG AUSER_ID=1000
ARG AGROUP=mpisers
ARG AGROUP_ID=1000
ARG AHOME=/home/$AUSER
ARG WORD_DIR=$AHOME/mpidir

ENV USPACE_APPS_BIN=/usr/local/bin

USER root
WORKDIR /root

ADD dinit.zsh $USPACE_APPS_BIN 
ADD setup-nfs_server.sh /root
ADD createuser.sh /root

RUN chmod a+x $USPACE_APPS_BIN/dinit.zsh && \
	chmod a+x setup-nfs_server.sh && \
	chmod a+x createuser.sh

# NFS server
RUN ./setup-nfs_server.sh $NODE_ID $NFS_DATA_DIR && \
	rm setup-nfs_server.sh

# Create user
RUN ./createuser.sh $AUSER $AUSER_ID $AGROUP $AGROUP_ID $AHOME && \
	echo "AllowUsers ${AUSER}" >> /etc/ssh/sshd_config && \
	ln /root/hosts $AHOME/hosts && \
	chown $AUSER:$AGROUP $AHOME/hosts && \
	chmod a+r $AHOME/hosts && \
	rm createuser.sh

# Create volume
RUN mkdir -p /mnt/data && \
	chmod a+rw /mnt/data && \
	ln -s /mnt/data $AHOME/data && \
	chown $AUSER:$AGROUP $AHOME/data

# Set paramters for daemon.zsh sript
RUN echo "/root/hosts ${NODE_ID} ${AUSER} ${AGROUP} ${WORD_DIR}" > /root/params

## EntryPoint ########################################################################

USER root
WORKDIR /root
VOLUME mnt/data
EXPOSE 22
EXPOSE 2049
CMD ["/root/params"]
ENTRYPOINT ["dinit.zsh"]

# vim: tabstop=4 noexpandtab shiftwidth=4 softtabstop=4
