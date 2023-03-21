#!/usr/bin/env bash
# ===========================================================================
#
# Created: 2022-04-06 Y. Schumann
#
# Helper script to build and push alpine sshd image
# for AMD64, ARMv8 and ARMv7
#
# ===========================================================================

# Store path from where script was called, determine own location
# and source helper content from there
callDir=$(pwd)
ownLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${ownLocation}
. ./include/helpers_console.sh
_init

helpMe() {
    echo "
    Helper script to build Alpine sshd image for AMD64, ARMv7 and ARMv8,
    based on Alpine Edge.

    Usage:
    ${0} [options]
    Optional parameters:
    -7 .. Also build ARMv7 image beside AMD64
    -8 .. Also build ARMv8 image beside AMD64
    -p .. Push image to DockerHub
    -v <version>
       .. Version with which the image should be tagged
    -h .. Show this help
    "
}


PUSH_IMAGE=''
ALPINE_VERSION='edge'
BUILD_ARMv7_IMAGE=false
BUILD_ARMv8_IMAGE=false
PLATFORM='linux/amd64'
IMAGE_VERSION='latest'

while getopts 78pv:h? option; do
    case ${option} in
        7) BUILD_ARMv7_IMAGE=true;;
        8) BUILD_ARMv8_IMAGE=true;;
        p) PUSH_IMAGE=--push;;
        v) IMAGE_VERSION="${OPTARG}" ;;
        h|?) helpMe && exit 0;;
        *) die 90 "invalid option \"${OPTARG}\"";;
    esac
done

if ${BUILD_ARMv7_IMAGE} ; then
    PLATFORM=${PLATFORM},linux/armhf
    info "Building AMD64 and ARMv7"
else
    info "Building AMD64 only"
fi
if ${BUILD_ARMv8_IMAGE} ; then
    PLATFORM=${PLATFORM},linux/arm64
    info "Building AMD64 and ARMv8"
else
    info "Building AMD64 only"
fi

info "Building sshd image"
docker buildx \
    build \
    --platform=${PLATFORM} \
    "--tag=starwarsfan/alpine-sshd:${IMAGE_VERSION}" \
    --build-arg ALPINE_VERSION=${ALPINE_VERSION} \
    ${PUSH_IMAGE} \
    .
info " -> Done"
