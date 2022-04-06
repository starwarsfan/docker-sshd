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
    Helper script to build alpine sshd image for amd64 and arm64.

    Usage:
    ${0} [options]
    Optional parameters:
    -a  Also build ARM images beside AMD64
    -p  Publish image on DockerHub
    -h  Show this help
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
    info "Determining amd64 and arm64 image digests"
    docker manifest inspect "${ALPINE_VERSION}" > /tmp/alpineLinuxManifest.json
    DIGEST_AMD64=$(jq -j '.manifests[] | select(.platform.architecture == "amd64") | .digest' /tmp/alpineLinuxManifest.json)
    DIGEST_ARM64=$(jq -j '.manifests[] | select(.platform.architecture == "arm64") | .digest' /tmp/alpineLinuxManifest.json)
    info " -> amd64: ${DIGEST_AMD64}"
    info " -> arm64: ${DIGEST_ARM64}"
#    rm -f /tmp/alpineLinuxManifest.json
}

tagAlpineImages() {
    info "Taging alpine linux images"
    docker pull "${ALPINE_VERSION}@${DIGEST_AMD64}"
    docker pull "${ALPINE_VERSION}@${DIGEST_ARM64}"
    docker tag "${ALPINE_VERSION}@${DIGEST_AMD64}" "${ALPINE_VERSION}-amd64"
    docker tag "${ALPINE_VERSION}@${DIGEST_ARM64}" "${ALPINE_VERSION}-arm64"
    info " -> Done"
}

buildImage() {
    local _arch=$1
    info "Building starwarsfan/alpine-sshd:manifest-${_arch}"
    docker build -f "${_arch}.Dockerfile" -t "starwarsfan/alpine-sshd:manifest-${_arch}" .
    info " -> Done"
    if ${PUBLISH_IMAGE} ; then
        info "Pushing starwarsfan/alpine-sshd:manifest-${_arch}"
        docker push "starwarsfan/alpine-sshd:manifest-${_arch}"
        info " -> Done"
    fi
}

buildManifest() {
    local _arch1=$1
    local _arch2=$2
    info "Building docker manifest for starwarsfan/alpine-sshd:${IMAGE_VERSION}"
    if [ -z "${_arch2}" ] ; then
        docker manifest create \
            "starwarsfan/alpine-sshd:${IMAGE_VERSION}" \
            --amend "starwarsfan/alpine-sshd:manifest-${_arch1}"
    else
        docker manifest create \
            "starwarsfan/alpine-sshd:${IMAGE_VERSION}" \
            --amend "starwarsfan/alpine-sshd:manifest-${_arch1}" \
            --amend "starwarsfan/alpine-sshd:manifest-${_arch2}"
    fi
    info " -> Done"
    if ${PUBLISH_IMAGE} ; then
        info "Pushing docker manifest starwarsfan/alpine-sshd:${IMAGE_VERSION}"
        docker manifest push "starwarsfan/alpine-sshd:${IMAGE_VERSION}"
        info " -> Done"
    fi
}

PUBLISH_IMAGE=false
BUILD_ARM_IMAGES=false
PULL_ALPINE_IMAGE=true
ALPINE_VERSION=alpine:edge
DIGEST_AMD64=''
DIGEST_ARM64=''
IMAGE_VERSION=latest

while getopts aph? option; do
    case ${option} in
        a) BUILD_ARM_IMAGES=true;;
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
    buildManifest amd64 arm64
else
    buildManifest amd64
fi
