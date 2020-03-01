#!/bin/bash
IP=192.168.1.A
CMD="bgapi originate sofia/external/service@$IP:5080 &eccho"

for f in `seq 1 10`; do
	for f in `seq 1 30`; do
	   fs_cli -x $CMD
	done
	sleep 1
done
