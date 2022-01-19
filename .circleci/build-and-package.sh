#!/bin/bash
set -e

mkdir /tmp/persist
mkdir /tmp/persist/artifacts

echo "Compiling and installing"

meson --buildtype=release -Db_lto=true --prefix=/tmp/prefix /tmp/persist/build
ninja -C /tmp/persist/build -j4
ninja -C /tmp/persist/build install

echo "Creating bundle"

tar -pcvz --transform 's,^,linuxmotehook2/,' --transform 's,/tmp/prefix,,' -f  /tmp/persist/artifacts/linuxmotehook2-amd64.tar.gz \
/tmp/prefix \
README.md LICENSE
