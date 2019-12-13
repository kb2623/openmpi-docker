#!/bin/zsh

# Arguments -----------------------------------------------------------------------------------------------------
NODE_ID=$1
AUSER=$2
AGROUP=$3
WORD_DIR=$4

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
function run_mound_nfs () {
	mkdir -p ${WORD_DIR}
	mount -v -o nolock $(cat /root/hosts | tr ' ' '\t' | tr -d ' ' | cut -d$'\t' -f1 | head -1):/ ${WORD_DIR}
	chown -R ${AUSER}:${AGROUP} ${WORD_DIR}
}

# Services -------------------------------------------------------------------------------------------------------
function run_sshd () {
	nohup $BSSHD -D -e -f $SSH_CONFIG &
	return $!
}

function run_nfsd () {
	$BRPCBIND -w
	$BRPCINFO
	if $BEXPORTFS -rv; then
		$BEXPORTFS
	else
		echo "Export validation failed, exiting..."
		exit 1
	fi
	$BNFSD -u -t -V 4 -N 2 -N 3 8
	nohup $BMOUNTD -F -V 4 -N 2 -N 3 &
	return $!
}

# Type of Nodes ---------------------------------------------------------------------------------------------------
function run_master () {
	sshd_pid=run_sshd
	nfsd_pid=run_nfsd
	run_mound_nfs
	wait $nfsd_pid
	wait $sshd_pid
}

function run_node () {
	sshd_pid=run_sshd
	run_mound_nfs
	wait $sshd_pid
}

# Main ------------------------------------------------------------------------------------------------------------
if [ ! ${NODE_ID} = "0" ]; then
	run_node
else
	run_master
fi

/bin/zsh
