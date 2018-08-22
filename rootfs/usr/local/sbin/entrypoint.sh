#!/bin/bash

TAG="$(basename $0 '.sh')"

serials=/etc/entrypoint.d/serial/*
for serial in ${serials}; do 
    echo "$TAG: running $serial"
    $serial
done

forks=/etc/entrypoint.d/fork/*
for fork in ${forks}; do 
    echo "$TAG: running $fork"
    $fork &
done

exec $@