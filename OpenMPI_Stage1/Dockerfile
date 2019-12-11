ARG BASE_CONTAINER=alpine:3.10
FROM $BASE_CONTAINER

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>"
LABEL description="Alpine computing Node for OpenMPI"
LABEL source="https://github.com/kb2623/openmpi-docker"

ARG NODE_ID=0
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
ADD daemon.zsh /root
ADD hosts /root 
ADD setup-nfs_server.sh /root

RUN mkdir -p /etc/skel
ADD .bashrc /etc/skel
ADD .zshrc /etc/skel
ADD .tmux.config /etc/skel
ADD .basic.tmuxtheme /etc/skel
ADD .profile /etc/skel

CMD [${NODE_ID}]
ENTRYPOINT ["/root/daemon.zsh"]

# Fix file privilages
RUN chmod a+rx hosts && \
	chmod a+rx setup-nfs_server.sh && \
	chmod a+x daemon.zsh

# Add configurations to root user
RUN cp -f /etc/skel/.bashrc /root/.bashrc && \
	cp -f /etc/skel/.zshrc /root/.zshrc && \
	cp -f /etc/skel/.profile /root/.profile && \
	cp -f /etc/skel/.tmux.config /root/.tmux.config && \
	cp -f /etc/skel/.basic.tmuxtheme /root/.basic.tmuxtheme && \
	chown -R root:root /root

# Update the system and install programs
RUN apk update && apk add zsh bash tmux git build-base perl linux-headers nfs-utils openssh && ssh-keygen -A

# Install OpenMPI
RUN wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-${OPENMPI_VERSION}.tar.bz2 && \
	tar -xvf openmpi-${OPENMPI_VERSION}.tar.bz2 && \
	cd openmpi-${OPENMPI_VERSION} && \
	./configure --prefix=${USPACE_APPS} && \
	make && make install

# Add hosts
RUN echo -e "\n# MPI cluster hosts\n" >> /etc/hosts && \
	cat hosts >> /etc/hosts

# NFS server
RUN ./setup-nfs_server.sh ${NFS_DATA_DIR}

