#!/bin/bash
# Builds all containers from the Dockerfile, tagging them with their names.
# Must be run from the repo's root directory.

CONTAINERS=(op-base op-py-build op-minimal op-dev)
ADDITIONAL=(op-gitpod)
A_TGTS=(op-dev)
A_ARGS=('--build-arg OP_USER=gitpod --build-arg OP_UID=33333')
DOCKER_REPO=thomasschweich/open-portfolio

for container in ${CONTAINERS[@]}; do
    docker build --target ${container} -t ${DOCKER_REPO}:${container} .
done

for (( i=0; i<${#ADDITIONAL[@]}; ++i)); do
    docker build --target ${A_TGTS[$i]} $(echo ${A_ARGS[$i]}) -t ${DOCKER_REPO}:${ADDITIONAL[$i]} .
done
