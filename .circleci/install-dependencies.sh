#!/bin/bash
set -e

export DEBIAN_FRONTEND="noninteractive"
export TZ="Europe/London"

apt-get install -y software-properties-common

add-apt-repository -y ppa:vala-team/next

apt-get install -y build-essentials \
    libudev-dev zlib1g-dev \
    valac libgee-0.8-dev \
    meson
