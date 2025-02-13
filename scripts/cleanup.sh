#!/bin/bash

# Script to cleanup some of the generated resources

BASEDIR=$(dirname $0)
rm -rf ${BASEDIR}/../src/chat-app/lib/its_a_rag

for i in $(docker images --filter=reference="*/*chat-app*" -q)
do
    docker rmi -f $i
done
for i in $(docker images --filter=reference="*/*mockstock-app*" -q)
do
    docker rmi -f $i
done
