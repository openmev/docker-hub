#!/bin/sh

VERSION=v1.10.8-mev0.4.0

git clone https://github.com/flashbots/mev-geth --branch v1.10.8-mev0.4.0 --single-branch go-ethereum
cd go-ethereum/
echo "building $VERSION"
echo "Docker BuildX Starting..."
DOCKER_BUILDKIT=1 docker buildx build go-ethereum/ -t openmev/mev-geth-alpine:v1.10.8-mev0.4.0
#DOCKER_BUILDKIT=1 docker buildx build . -t openmev/mev-geth-alpine:v1.10.8-mev0.4.0
