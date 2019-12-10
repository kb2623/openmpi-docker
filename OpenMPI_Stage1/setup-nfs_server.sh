#!/bin/zsh

NFS_DATA_DIR=$1

if [ ! ${NODE_ID} -eq "0" ]; then exit 0; fi

# Create NFS Server
mkdir -p ${NFS_DATA_DIR} && chown -R nobody:nogroup ${NFS_DATA_DIR} && chmod -R 755 ${NFS_DATA_DIR}
printf "\n# NFS server\n" >> /etc/exports
for e in $(cat /root/hosts | tr ' ' '\t' | tr -d ' ' | cut -d$'\t' -f1); do
   printf "%s %s(rw,sync,no_subtree_check)\n" ${NFS_DATA_DIR} ${e} >> /etc/exports
done
mkdir -p /var/lib/nfs/rpc_pipefs /var/lib/nfs/v4recovery
echo "rpc_pipefs    /var/lib/nfs/rpc_pipefs rpc_pipefs      defaults        0       0" >> /etc/fstab
echo "nfsd  /proc/fs/nfsd   nfsd    defaults        0       0" >> /etc/fstab
