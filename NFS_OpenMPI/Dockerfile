ARG BASE_CONTAINER=alpine:3.10
FROM $BASE_CONTAINER

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>" \
	  description="Alpine computing Node for OpenMPI with NFS server" \
	  source="https://github.com/kb2623/openmpi-docker"

ARG NODE_ID=0
ARG NFS_DATA_DIR=/mnt/nfs/nfs-data
ARG OPENMPI_VERSION=4.0.2
ARG AUSER=mpiuser
ARG AUSER_ID=1002
ARG AGROUP=mpisers
ARG AGROUP_ID=1002
ARG AHOME=/home/${AUSER}
ARG WORD_DIR=${AHOME}/mpidir

ENV DEBCONF_NOWARNINGS=yes
ENV USPACE_LIBS=/usr/local/lib
ENV USPACE_APPS=/usr/local

USER root
WORKDIR /root
VOLUME ${AHOME}/data
EXPOSE 22
EXPOSE 2049
CMD [${NODE_ID}, ${AUSER}, ${AGROUP}, ${WORD_DIR}]
ENTRYPOINT ["/root/daemon.zsh"]

RUN mkdir -p ${AHOME} && \
    mkdir -p ${AHOME}/.ssh && \
    mkdir -p ${AHOME}/data && \
	mkdir -p /etc/skel
ADD sshd_config /etc/ssh/
ADD daemon.zsh /root
ADD hosts /root 
ADD setup-nfs_server.sh /root
ADD createuser.sh /root
ADD .zshrc /etc/skel
ADD .tmux.config /etc/skel
ADD .basic.tmuxtheme /etc/skel
ADD .profile /etc/skel
ADD .bashrc /etc/skel
ADD .ssh ${AHOME}

# Fix file privilages
RUN chmod a+rx hosts && \
	chmod a+rx setup-nfs_server.sh && \
	chmod a+x daemon.zsh && \
	chmod a+rx createuser.sh && \
	chmod g+w /etc/passwd && \
	chmod -R 755 ${AHOME}/.ssh

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

# Create user
RUN ./createuser.sh $AUSER $AUSER_ID $AGROUP $AGROUP_ID $AHOME && \
	echo "AllowUsers %s" >> /etc/ssh/sshd_config ${AUSER} && \
	ln -s /root/hosts ${AHOME}/hosts && \
	chown ${AUSER}:${AGROUP} ${AHOME}/hosts && \
	chmod a+r ${AHOME}/hosts

# vim: tabstop=4 noexpandtab shiftwidth=3 softtabstop=3
