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
ADD hosts /root 
ADD .zshrc /etc/skel
ADD .tmux.config /etc/skel
ADD .basic.tmuxtheme /etc/skel
ADD .profile /etc/skel
ADD .bashrc /etc/skel

# Fix file privilages
RUN chmod a+rx hosts && \
	chmod g+w /etc/passwd

# Add configurations to root user
RUN cp -f /etc/skel/.bashrc /root/.bashrc && \
	cp -f /etc/skel/.zshrc /root/.zshrc && \
	cp -f /etc/skel/.profile /root/.profile && \
	cp -f /etc/skel/.tmux.config /root/.tmux.config && \
	cp -f /etc/skel/.basic.tmuxtheme /root/.basic.tmuxtheme

# Update the system and install programs
RUN apk update && \
	apk add zsh bash tmux git build-base perl linux-headers nfs-utils openssh && \
	ssh-keygen -A

# Install OpenMPI
RUN wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-$OPENMPI_VERSION.tar.bz2 && \
	tar -xvf openmpi-$OPENMPI_VERSION.tar.bz2 && \
	cd openmpi-$OPENMPI_VERSION && \
	./configure --prefix=$USPACE_APPS && \
	make && \
	make install

## STAGE 1 ###########################################################################

FROM nfs4_openmpi_node_base

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>"
LABEL description="Alpine computing Node for OpenMPI with NFS server final image"
LABEL source="https://github.com/kb2623/openmpi-docker"

ARG NODE_ID=0
ARG NFS_DATA_DIR=/mnt/nfs/nfs-data
ARG AUSER=mpiuser
ARG AUSER_ID=1002
ARG AGROUP=mpisers
ARG AGROUP_ID=1002
ARG AHOME=/home/$AUSER
ARG WORD_DIR=$AHOME/mpidir

USER root
WORKDIR /root

ADD daemon.zsh /root
ADD setup-nfs_server.sh /root
ADD createuser.sh /root

RUN chmod a+x setup-nfs_server.sh && \
	chmod a+x daemon.zsh && \
	chmod a+x createuser.sh

# Add hosts
RUN printf "\n# MPI cluster hosts\n" >> /etc/hosts && \
	cat hosts >> /etc/hosts

# NFS server
RUN ./setup-nfs_server.sh $NODE_ID $NFS_DATA_DIR

# Create user
RUN ./createuser.sh $AUSER $AUSER_ID $AGROUP $AGROUP_ID $AHOME && \
	echo "AllowUsers ${AUSER}" >> /etc/ssh/sshd_config && \
	ln /root/hosts $AHOME/hosts && \
	chown $AUSER:$AGROUP $AHOME/hosts && \
	chmod a+r $AHOME/hosts && \
	mkdir -p /mnt/data && \
	chown nobody:nogroup /mnt/data && \
	chmod a+rw /mnt/data
COPY .ssh $AHOME/.ssh
RUN chmod -R 755 $AHOME/.ssh

## EntryPoint ########################################################################

USER root
WORKDIR /root
VOLUME mnt/data
EXPOSE 22
EXPOSE 2049
CMD ["$(echo /root/hosts ${NODE_ID} ${AUSER} ${AGROUP} ${WORD_DIR})"]
ENTRYPOINT ["/root/daemon.zsh"]

# vim: tabstop=4 noexpandtab shiftwidth=4 softtabstop=4
