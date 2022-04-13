#!/usr/bin/env bash
# ===========================================================================
#
# Created: 2022-04-06 Y. Schumann
#
# Helper script to build and push alpine sshd image for amd64 and arm64
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
    Helper script to build Alpine sshd image for amd64 and arm64,
    based on Alpine Edge.

    Usage:
    ${0} [options]

    Available options:
    -a .. Also build ARM image beside AMD64
    -n <name>
       .. Name of the image. Default: ${IMAGE_NAME}
    -p .. Push image to DockerHub
    -h .. Show this help
    "
}

pullAlpine() {
    if [[ $PULL_ALPINE_IMAGE ]] ; then
        info "Pulling ${ALPINE_VERSION}"
        docker pull "${ALPINE_VERSION}"
        info " -> Done"
    else
        info "Skipping pull of ${ALPINE_VERSION}"
    fi
}

getDigests() {
    info "Getting manifest for ${ALPINE_VERSION}"
    docker manifest inspect "${ALPINE_VERSION}" > /tmp/alpineLinuxManifest.json
    info " -> Done"

    info "Determining image digests"
    DIGEST_AMD64=$(jq -j '.manifests[] | select(.platform.architecture == "amd64") | .digest' /tmp/alpineLinuxManifest.json)
    DIGEST_ARM64=$(jq -j '.manifests[] | select(.platform.architecture == "arm64") | .digest' /tmp/alpineLinuxManifest.json)
    DIGEST_ARMv7=$(jq -j '.manifests[] | select((.platform.architecture == "arm") and (.platform.variant == "v7")) | .digest' /tmp/alpineLinuxManifest.json)
    info " -> amd64: ${DIGEST_AMD64}"
    info " -> arm64: ${DIGEST_ARM64}"
    info " -> armv7: ${DIGEST_ARMv7}"
#    rm -f /tmp/alpineLinuxManifest.json
}

tagAlpineImages() {
    info "Pulling dedicated architecture images"
    docker pull "${ALPINE_VERSION}@${DIGEST_AMD64}"
    docker pull "${ALPINE_VERSION}@${DIGEST_ARM64}"
    docker pull "${ALPINE_VERSION}@${DIGEST_ARMv7}"
    info " -> Done"

    info "Taging images"
    docker tag "${ALPINE_VERSION}@${DIGEST_AMD64}" "${ALPINE_VERSION}-amd64"
    docker tag "${ALPINE_VERSION}@${DIGEST_ARM64}" "${ALPINE_VERSION}-arm64"
    docker tag "${ALPINE_VERSION}@${DIGEST_ARMv7}" "${ALPINE_VERSION}-armv7"
    info " -> Done"
}

buildImage() {
    local _arch=$1
    info "Building ${IMAGE_NAME}:manifest-${_arch}"
    docker build -f "${_arch}.Dockerfile" -t "${IMAGE_NAME}:manifest-${_arch}" .
    info " -> Done"
    if ${PUBLISH_IMAGE} ; then
        info "Pushing ${IMAGE_NAME}:manifest-${_arch}"
        docker push "${IMAGE_NAME}:manifest-${_arch}"
        info " -> Done"
    fi
}

buildManifest() {
    local _arch1=$1
    local _arch2=$2
    local _arch3=$3
    info "Building Docker manifest for ${IMAGE_NAME}:${IMAGE_VERSION}"
    docker manifest rm "${IMAGE_NAME}:${IMAGE_VERSION}" &>/dev/null || true
    if [ -z "${_arch2}" ] ; then
        docker manifest create \
            "${IMAGE_NAME}:${IMAGE_VERSION}" \
            --amend "${IMAGE_NAME}:manifest-${_arch1}"
    else
        docker manifest create \
            "${IMAGE_NAME}:${IMAGE_VERSION}" \
            --amend "${IMAGE_NAME}:manifest-${_arch1}" \
            --amend "${IMAGE_NAME}:manifest-${_arch2}" \
            --amend "${IMAGE_NAME}:manifest-${_arch3}"
    fi
    info " -> Done"
    if ${PUBLISH_IMAGE} ; then
        info "Pushing Docker manifest ${IMAGE_NAME}:${IMAGE_VERSION}"
        docker manifest push "${IMAGE_NAME}:${IMAGE_VERSION}"
        info " -> Done"
    fi
}

PUBLISH_IMAGE=false
BUILD_ARM_IMAGES=false
PULL_ALPINE_IMAGE=true
ALPINE_VERSION=alpine:edge
IMAGE_NAME=starwarsfan/alpine-sshd
DIGEST_AMD64=''
DIGEST_ARM64=''
DIGEST_ARMv7=''
IMAGE_VERSION=latest

while getopts an:ph? option; do
    case ${option} in
        a) BUILD_ARM_IMAGES=true;;
        n) IMAGE_NAME="${OPTARG}";;
        p) PUBLISH_IMAGE=true;;
        h|?) helpMe && exit 0;;
        *) die 90 "invalid option \"${OPTARG}\"";;
    esac
done

info "Disabling buildkit etc. pp."
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0
info " -> Done"

pullAlpine
getDigests
tagAlpineImages
buildImage amd64
if ${BUILD_ARM_IMAGES} ; then
    buildImage arm64
    buildImage armv7
    buildManifest amd64 arm64 armv7
else
    buildManifest amd64
fi
