#!/bin/zsh

# Arguments -----------------------------------------------------------------------------------------------------
function param {
	return $(cut -d' ' -f$1 /root/params)
}

HOST_FILE=$(param 1)
NODE_ID=$(param 2)
AUSER=$(param 3)
AGROUP=$(param 4)
WORD_DIR=$(param 5)

echo $HOST_FILE $NODE_ID $AUSER $AGROUP $WORD_DIR

# Constants -----------------------------------------------------------------------------------------------------
readonly SSH_CONFIG='/etc/ssh/sshd_config'

readonly BSSHD='/usr/sbin/sshd'
readonly BEXPORTFS='/usr/sbin/exportfs'
readonly BIDMAPD='/usr/sbin/rpc.idmapd'
readonly BMOUNTD='/usr/sbin/rpc.mountd'
readonly BNFSD='/usr/sbin/rpc.nfsd'
readonly BRPCBIND='/sbin/rpcbind'
readonly BRPCINFO='/sbin/rpcinfo'
readonly BRPC_SVCGSSD='/usr/sbin/rpc.svcgssd'
readonly BSTATD='/sbin/rpc.statd'

# Mount NFS ------------------------------------------------------------------------------------------------------
function run_mound_nfs {
	mkdir -p $WORD_DIR
	chmod a+wrx $WORD_DIR
	chown -R $AUSER:$AGROUP $WORD_DIR
	mount -v -o nolock $(cat $HOST_FILE | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f1 | head -1 | tail -1):/ $WORD_DIR
}

# Services -------------------------------------------------------------------------------------------------------
function run_sshd {
	nohup $BSSHD -D -e -f $SSH_CONFIG &
	return $!
}

function run_nfsd {
	$BRPCBIND -w
	$BRPCINFO
	if $BEXPORTFS -rv; then
		$BEXPORTFS
	else
		echo "Export validation failed, exiting..."
		exit 1
	fi
	$BNFSD -u -t -V 4 -p 2049 8
	nohup $BMOUNTD -V 4 -p 2049 &
	return $!
}

# Type of Nodes ---------------------------------------------------------------------------------------------------
function run_master {
	run_sshd
	run_nfsd
	run_mound_nfs
}

function run_node {
	run_sshd
	run_mound_nfs
}

# Main ------------------------------------------------------------------------------------------------------------
if [ ! ${NODE_ID} = "0" ]; then
	run_node
else
	run_master
fi

# main loop
while true; do
	echo "Press [CTRL+C] to stop.."
   sleep 1000
done

