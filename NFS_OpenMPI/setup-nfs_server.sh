#!/bin/zsh

NFS_DATA_DIR=$1

if [ ! ${NODE_ID} = "0" ]; then exit 0; fi

# Create NFS Server
mkdir -p ${NFS_DATA_DIR} && chown -R nobody:nogroup ${NFS_DATA_DIR} && chmod -R 755 ${NFS_DATA_DIR}
printf "\n# NFS server\n%s *(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)\n" ${NFS_DATA_DIR} >> /etc/exports
mkdir -p /var/lib/nfs/rpc_pipefs
mkdir -p /var/lib/nfs/v4recovery
echo "rpc_pipefs  /var/lib/nfs/rpc_pipefs  rpc_pipefs  defaults  0  0" >> /etc/fstab
echo "nfsd        /proc/fs/nfsd            nfsd        defaults  0  0" >> /etc/fstab