#!/bin/bash

# Arguments: [ppa] [version] [changelog entry]

set -e

rm -f debian/changelog
rm -f ../linuxmotehook2_*

printf '%s' "$LAUNCHPAD_KEY_BASE64" | base64 --decode | gpg --import --batch

DISTRO=$(lsb_release -cs)
DEBFULLNAME=v1993 DEBEMAIL=v19930312@gmail.com dch --create --package=linuxmotehook2 --newversion="${2}~${DISTRO}" --distribution $DISTRO -- "$3"

printf '%s' "$LAUNCHPAD_KEY_PASSWORD_BASE64" | base64 --decode > /tmp/key_password
debuild -S -p"gpg --batch --pinentry-mode=loopback --passphrase-file=/tmp/key_password" -k"$LAUNCHPAD_KEY_ID" 
rm -f /tmp/key_password

dput "$1" ../*.changes 
