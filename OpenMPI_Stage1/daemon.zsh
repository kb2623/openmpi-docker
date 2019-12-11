#!/bin/zsh

/usr/sbin/sshd -D -e -f /etc/ssh/sshd_config &
if [ ! ${NODE_ID} = "0" ]; then exit 0; fi

/sbin/rpcbind -w
/sbin/rpcinfo
/usr/sbin/rpc.nfsd --debug 8 --no-udp --no-nfs-version 2 --no-nfs-version 3
if /usr/sbin/exportfs -rv; then
	/usr/sbin/exportfs
else
	echo "Export validation failed, exiting..."
	exit 1
fi
/usr/sbin/rpc.mountd --debug all --no-udp --no-nfs-version 2 --no-nfs-version 3
