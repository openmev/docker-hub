#!/bin/sh

VERSION=v1.10.8-eden1.1.0

git clone https://github.com/eden-network/eden-geth --branch v1.10.8-eden1.1.0 --single-branch go-ethereum
cd go-ethereum/
echo "building $VERSION"
echo "Docker BuildX Starting..."
DOCKER_BUILDKIT=1 docker buildx build go-ethereum/ -t openmev/eden-client:v1.10.8-eden1.1.0
#DOCKER_BUILDKIT=1 docker buildx build . -t openmev/eden-client:v1.10.8-eden1.1.0
