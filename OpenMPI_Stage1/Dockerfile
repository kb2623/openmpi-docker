ARG BASE_CONTAINER=alpine:3.10
FROM $BASE_CONTAINER

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>"
LABEL description="Alpine computing Node for OpenMPI"

ARG NODE_ID=1
ARG NFS_DATA_DIR=/mnt/nfs/nfs-data
ARG OPENMPI_VERSION=4.0.2

ENV DEBCONF_NOWARNINGS=yes

ENV USPACE_LIBS=/usr/local/lib
ENV USPACE_APPS=/usr/local

USER root
WORKDIR /root

EXPOSE 22
EXPOSE 2049

ADD sshd_config /etc/ssh/
ADD hosts . 
ADD setup-nfs_server.sh .
ADD .bashrc /etc/skel
ADD .zshrc /etc/skel
ADD .tmux.conf /etc/skel
ADD .basic.tmuxtheme /etc/skel
ADD .profile /etc/skel
ADD daemon.zsh .

ENTRYPOINT ["daemon.zsh"]

# Update the system and install programs
RUN apk update && apk add zsh bash tmux git build-base perl linux-headers nfs-utils openssh && ssh-keygen -A

# Install OpenMPI
RUN wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-${OPENMPI_VERSION}.tar.bz2 && \
	tar -xvf openmpi-${OPENMPI_VERSION}.tar.bz2 && \
	cd openmpi-${OPENMPI_VERSION} && \
	./configure --prefix=${USPACE_APPS} && \
	make && make install

# Add hosts
RUN chmod a+r hosts
RUN printf "\n# MPI cluster hosts\n" >> /etc/hosts
RUN cat hosts >> /etc/hosts

# Setup SSH servcie
RUN printf "\nAllowUsers $s\n" ${AUSER} >> /etc/ssh/sshd_config

# NFS server
RUN chmod a+rx setup-nfs_server.sh
RUN ./setup-nfs_server.sh ${NFS_DATA_DIR}

# Fix file privilages
RUN chmod a+x daemon.zsh
