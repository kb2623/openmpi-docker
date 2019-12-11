#!/bin/zsh

readonly BEXPORTFS='/usr/sbin/exportfs'
readonly BIDMAPD='/usr/sbin/rpc.idmapd'
readonly BMOUNTD='/usr/sbin/rpc.mountd'
readonly BNFSD='/usr/sbin/rpc.nfsd'
readonly BRPCBIND='/sbin/rpcbind'
readonly BRPCINFO='/sbin/rpcinfo'
readonly BRPC_SVCGSSD='/usr/sbin/rpc.svcgssd'
readonly BSTATD='/sbin/rpc.statd'

/usr/sbin/sshd -D -e -f /etc/ssh/sshd_config &
if [ ! ${NODE_ID} = "0" ]; then exit 0; fi

# TODO https://github.com/ehough/docker-nfs-server/blob/develop/entrypoint.sh

$BRPCBIND -w
$BRPCINFO
if $BEXPORTFS -rv; then
	$BEXPORTFS
else
	echo "Export validation failed, exiting..."
	exit 1
fi
$BMOUNTD --debug all --no-udp --no-nfs-version 2 --no-nfs-version 3
$BNFSD --debug 8 --no-udp --no-nfs-version 2 --no-nfs-version 3
