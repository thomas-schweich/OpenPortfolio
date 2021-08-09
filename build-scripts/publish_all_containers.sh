#!/bin/bash
# Publishes all tags to Docker hub.

TAGS=(op-base op-py-build op-minimal op-dev op-gitpod)
DOCKER_REPO=thomasschweich/open-portfolio

for tag in ${TAGS[@]}; do
    docker push ${DOCKER_REPO}:${tag}
done
