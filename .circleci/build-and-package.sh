#!/bin/bash
set -e

# Step 1 - standalone build
meson --buildtype=release -Db_lto=true --prefix=/tmp/prefix /tmp/build
ninja -C /tmp/build -j4
ninja -C /tmp/build install

mkdir /tmp/artifacts

tar -pcvz --transform 's,^,linuxmotehook2/,' --transform 's,/tmp/prefix,,' -f  /tmp/artifacts/linuxmotehook2-amd64.tar.gz \
/tmp/prefix \
README.md LICENSE
