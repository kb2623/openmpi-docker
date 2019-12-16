#!/bin/zsh

PARAMS_FILE=$1

function fHCutLine {
	if [ $# -lt 2 ]; then exit 1; fi
	echo $1 | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f$2
}

function fHCutFile {
	if [ $# -lt 3 ]; then exit 1; fi
	line=$(cat $1 | head -$(($2+1)) | tail -1)
	fHCutLine $line $3
}

function param {
	cut -d' ' -f$1 $PARAMS_FILE
}

# Arguments -----------------------------------------------------------------------------------------------------
HOST_FILE=$(param 1)
NODE_ID=$(param 2)
AUSER=$(param 3)
AGROUP=$(param 4)
WORD_DIR=$(param 5)

# Constants -----------------------------------------------------------------------------------------------------
readonly SSH_CONFIG='/etc/ssh/sshd_config'

readonly SSHD='/usr/sbin/sshd'
readonly EXPORTFS='/usr/sbin/exportfs'
readonly RPC_MOUNTD='/usr/sbin/rpc.mountd'
readonly RPC_IDMAPD='/usr/sbin/rpc.idmapd'
readonly RPC_SVCGSSD='/usr/sbin/rpc.svcgssd'
readonly RPC_NFSD='/usr/sbin/rpc.nfsd'
readonly RPC_GSSD='/usr/sbin/rpc.gssd'
readonly RPCBIND='/sbin/rpcbind'
readonly RPCINFO='/sbin/rpcinfo'
readonly STATD='/sbin/rpc.statd'

# Mount NFS ------------------------------------------------------------------------------------------------------
function run_mound_nfs {
	mkdir -p $WORD_DIR
	chmod a+wrx $WORD_DIR
	chown -R $AUSER:$AGROUP $WORD_DIR
	mount -v -o nolock $(fHCutFile $HOST_FILE 0 2):/ $WORD_DIR
}

# Services -------------------------------------------------------------------------------------------------------
function run_sshd {
	nohup $SSHD -D -e -f $SSH_CONFIG &
}

function run_nfsd_server {
	$RPCBIND -w
	$RPCINFO
	if $EXPORTFS -rv; then
		$EXPORTFS
	else
		echo "Export validation failed, exiting..."
		exit 1
	fi
	$RPC_MOUNTD -V 4 
	$RPC_IDMAPD
	$RPC_SVCGSSD
	$RPC_NFSD -u -t -V 4 -p 2049 8
}

# Type of Nodes ---------------------------------------------------------------------------------------------------
function run_master {
	run_sshd
	run_nfsd_server
	$RPC_GSSD -M -D
	run_mound_nfs
}

function run_node {
	run_sshd
	$RPC_IDMAPD
	$RPC_GSSD -M -D
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

