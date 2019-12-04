#!/bin/bash

NODE_ID=$1

cat /root/hosts | tr ' ' '\t' | cut -d$'\t' -f1 | head -${NODE_ID} | tail -1