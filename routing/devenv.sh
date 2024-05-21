#!/bin/bash
set -ex
cd "$(dirname $0)"

IMAGE="p4tc_devenv:latest"

if [ "X${CONTAINER_NAME}" = "X" ]; then CONTAINER_NAME="p4c";fi

if [ "X${DOCKER_FLAGS}" = "X" ]; then DOCKER_FLAGS="-it --rm";fi

exec docker run \
    ${DOCKER_FLAGS} \
    --privileged \
    --cap-add SYS_ADMIN \
    --net host \
    --name ${CONTAINER_NAME} \
    -v ${PWD}:/project \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w /project "${IMAGE}" \
    "$@"
