#!/bin/bash
# PREVIOUS_VERSION=v1.10.8-mev0.4.0
#  LATEST_VERSION=v1.10.17-mev0.6.1

set -o errexit
set -o nounset

trap '[ "$?" -ne 0 ] && printf "\nAn error occurred\n"' EXIT



VERSION=v1.10.17-mev0.6.1
GIT_COMMIT=9b62e981e98ad44b2f39ece2de605d7fa0e9816a

git clone https://github.com/flashbots/mev-geth --branch v1.10.17-mev0.6.1 --single-branch go-ethereum
cd go-ethereum/
git submodule sync --recursive && git submodule update --init --recursive
echo "building $VERSION"
echo "Docker BuildX Starting..."
#dock#DOCKER_BUILDKIT=1 docker buildx build . -t openmev/mev-geth-alpine:v1.10.17-mev0.6.1
#docker image build --build-arg VCS_REF=`git rev-parse --short HEAD` --build-arg BUILD_DATE=`date -u +”%Y-%m-%dT%H:%M:%SZ”` -t $IMAGE_NAME .
#DOCKER_BUILDKIT=1 docker buildx build . -t openmev/mev-geth-alpine:v1.10.17-mev0.6.1

DOCKER_BUILDKIT=1 docker buildx build go-ethereum/ -t openmev/mev-geth-alpine:v1.10.17-mev0.6.1 --build-arg VCS_REF=`git rev-parse --short HEAD` --build-arg BUILD_DATE=`date -u +”%Y-%m-%dT%H:%M:%SZ”`

