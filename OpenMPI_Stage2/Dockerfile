ARG BASE_CONTAINER=openmpidocker_s1:latest
FROM $BASE_CONTAINER

LABEL maintainer="Klemen Berkovic <roxor@gmail.com>"
LABEL description="Final OpenMPI image"

ARG AUSER=mpiuser
ARG AUSER_ID=1002
ARG AGROUP=mpisers
ARG AGROUP_ID=1002
ARG AHOME=/home/mpiuser

USER root
WORKDIR /root

# Create user
COPY createuser.sh .
RUN chmod a+rx createuser.sh
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    ./createuser.sh $AUSER $AUSER_ID $AGROUP $AGROUP_ID $AHOME && \
    chmod g+w /etc/passwd && \
    fix-permissions $AHOME
RUN printf "AllowUsers %s" >> /etc/ssh/sshd_config ${AUSER} && systemctl restart sshd.service

USER $AUSER_ID
WORKDIR $AHOME

# TODO NFS client setup

CMD /bin/bash

