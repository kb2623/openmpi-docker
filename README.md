# Custome OpenMPI build for docker
![image one](openmpi-docker.svg)

* [OpenMPI](https://www.open-mpi.org/)
* [OpenMPI GitHub](https://github.com/open-mpi/ompi)

## Hosts
### Example of Hosts file
```
192.168.1.2 node1
192.168.1.3 node2
192.168.1.4 node3
192.168.1.5 node4
```

## Installation
You have to have a `hosts` file for `make build` to run.
You have to have a SSL key for `make build` to run.

### Prerequisites
Programs: `make docker bash ssh-keygen`

### Installation
Installation should be performed on all docker hosts, but some part of the installation process is executed only on one machine.

To start the installation you have to first create `hosts` file based on [Hosts](#Hosts).
Then create ssh keys for all hosts in mpi cluster.
For this task use `make sshkey`, which will create a directory `sshkeys` with all keys for all nodes.
Now copy `hosts` file and `sshkeys` directory to all docker hosts.
Files should be copied to directory where the cloned repository is located.

On all docker hosts a docker network should be created.
For this task update `Makefile` or to all `make net` commands supply proper values for variables `NETWORK_SUBNET`, `HOST_INTERFACE` and `NETWORK_GW`.
Now on all hosts run next `make` commands in next sequence:
1. `make net`
2. `make build NODE_ID=[Index of a row in host file]`
3. `make run NODE_ID=[Index of a row in host file]`

## Uninstall
`make clean`
