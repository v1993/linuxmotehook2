#!/bin/bash
set -e

mkdir /tmp/persist
mkdir /tmp/persist/artifacts

# Step 1 - standalone build
echo "Compiling and installing"

meson --buildtype=release -Db_lto=true --prefix=/tmp/prefix /tmp/persist/build
ninja -C /tmp/persist/build -j4
ninja -C /tmp/persist/build install

echo "Creating bundle"

tar -pcvz --transform 's,^,linuxmotehook2/,' --transform 's,/tmp/prefix,,' -f  /tmp/persist/artifacts/linuxmotehook2-amd64.tar.gz \
/tmp/prefix \
README.md LICENSE

# Stop if we're not on main branch

[[ $CIRCLE_BRANCH == main ]] || exit

# Step 2 - deb build

echo "Importing launchpad key"

printf '%s' "$LAUNCHPAD_KEY_BASE64" | base64 --decode | gpg --import --batch

echo "Creating changelog"

MAIN_VERSION=$(meson introspect /tmp/persist/build --projectinfo | jq -r .version)
DEBFULLNAME=v1993 DEBEMAIL=v19930312@gmail.com dch --create --package=linuxmotehook2 --newversion="${MAIN_VERSION}.$(date -u +%Y%m%d%H%M%S)" --distribution $(lsb_release -cs) -- 'New upstream commit'

echo "Building deb package"

printf '%s' "$LAUNCHPAD_KEY_PASSWORD_BASE64" | base64 --decode > key_password

debuild -S -p"gpg --batch -v --pinentry-mode=loopback --passphrase-file=$(realpath key_password)" -k"$LAUNCHPAD_KEY_ID" 

rm -f key_password

echo "Uploading to launchpad"

dput ppa:v19930312/linuxmotehook2-nightly ../*.changes
