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

# Step 2 - deb build

printf '%s' "$(LAUNCHPAD_KEY_BASE64)" | base64 --decode | gpg --import

MAIN_VERSION=$(meson introspect /tmp/build --projectinfo | jq -r .version)
DEBFULLNAME=v1993 DEBEMAIL=v19930312@gmail.com dch --create --package=linuxmotehook2 --newversion="${MAIN_VERSION}.$(date -u +%Y%m%d%H%M%S)" --distribution unstable -- 'New upstream commit'

debuild -S -k"$LAUNCHPAD_KEY_ID"

dput ppa:v19930312/linuxmotehook2-nightly ../*.changes
