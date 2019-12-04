#!/bin/bash

# This script creates a user for runing jupyter lab
# First script checks if group exists based on GID on GROUP if that is true the the group is deleted
# Second script checks if user exists based on UID on USER if that is true the the user is deleted
# Third group is created based on GID and GROUP
# Fhour user is created based on UID and USER and added to a group based on GID and home is created in HOME
# Fix skeleten is copyed if skeleton won't work based on user add and the owneship is set to user and group
# CALL: creeateuser.sh USER UID GROUP GID HOME

aUSER=$1
aUID=$2
aGROUP=$3
aGID=$4
aHOME=$5

if id -u "$aUSER" >/dev/null 2>&1; then userdel -r $aUSER; fi
if id -u "$aUID" >/dev/null 2>&1; then userdel -r $aUID; fi
if id -g "$aGROUP" >/dev/null 2>&1; then groupdel $aGROUP; fi
if id -g "$aGID" >/dev/null 2>&1; then groupdel $aGID; fi

groupadd -g $aGID $aGROUP
useradd -m -u $aUID -g $aGID -s /bin/bash -d $aHOME -k /etc/skel -c 'MPI cluster node user' $aUSER 

cp -n /etc/skel/.bashrc $aHOME && chown $aUSER:$aGROUP $aHOME/.bashrc
cp -n /etc/skel/.profile $aHOME && chown $aUSER:$aGROUP $aHOME/.profile
cp -n /etc/skel/.tmux.conf $aHOME && chown $aUSER:$aGROUP $aHOME/.tmux.conf
cp -n /etc/skel/.basic.tmuxtheme $aHOME && chown $aUSER:$aGROUP $aHOME/.basic.tmuxtheme
