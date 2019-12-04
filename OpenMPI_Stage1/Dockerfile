ARG BASE_CONTAINER=debian:latest
FROM $BASE_CONTAINER

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>"
LABEL description="Base image with pipenv and jupyterlab"

ARG NODE_ID=0
ARG NFS_DATA_DIR=/mnt/nfs/nfs-data

USER root
WORKDIR /root

# Update the system
RUN apt update -y
# Install NFS client
RUN apt install -y nfs-common
# Install SSH server
RUN apt install -y openssh-server
# Install OpenMPI
RUN apt install -y openmpi-bin
# Install C++ compiler
RUN apt install -y g++
# Install user programs
RUN apt install -y git make vim vifm tmux

# Add scripts
ADD fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Add hosts
ADD hosts . && fix-permissions hosts
RUN printf "\n# MPI cluster hosts\n" >> /etc/hosts
RUN cat hosts >> /etc/hosts && fix-permissions /etc/hosts

# Setup SSH servcie
ADD sshd_config /etc/ssh/ && printf "\nAllowUsers $s\n" ${AUSER} >> /etc/ssh/sshd_config && fix-permissions /etc/ssh/sshd_config
RUN systemctl enable sshd.service && systemctl start sshd.service

# Enable prompt color in the skeleton .bashrc
RUN [ -e /etc/skel/.bashrc ] && rm /etc/skel/.bashrc
ADD .bashrc /etc/skel
ADD .tmux.conf /etc/skel
ADD .basic.tmuxtheme /etc/skel
RUN [ -e /etc/skel/.profile ] && rm /etc/skel/.profile
ADD .profile /etc/skel

# Add ssh keys for users
RUN [ -e /etc/skel/.ssh ] && rm /etc/skel/.ssh
ADD .ssh /etc/skel

# NFS server
ADD setup-nfs_server.sh . && fix-permissions setup-nfs_server.sh && chmod a+rx setup-nfs_server.sh
RUN if (( ${NODE_ID} == 0 )); then ./setup-nfs_server.sh ${NFS_DATA_DIR} ${NFS_NETWORK} ${NFS_NETWORK_MASK}; fi

USER root
WORKDIR /root

EXPOSE 22
EXPOSE 2049

CMD /bin/bash
