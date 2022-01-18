#!/bin/bash
set -e

export DEBIAN_FRONTEND="noninteractive"
export TZ="Europe/London"

apt-get install build-essentials \
    libudev-dev zlib1g-dev \
    valac libgee-0.8-dev \
    meson
