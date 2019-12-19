#!/bin/sh

# Helper funcions --------------------------------------------------------------------

fHCutLine() {
	if [ $# -lt 2 ]; then exit 1; fi
	echo $1 | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f$2
}

fHCutFile() {
	if [ $# -lt 3 ]; then exit 1; fi
	line=$(cat $1 | head -$(($2+1)) | tail -1)
	fHCutLine $line $3
}

# ------------------------------------------------------------------------------------
