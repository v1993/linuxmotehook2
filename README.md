# Cemuhook UDP server for WiiMotes on Linux - successor to original linuxmotehook

## This application is still in alpha state and has known issues as well as unfinished parts! Bug reports are not accepted.

## Quick build guide

```bash
git clone --recursive https://github.com/v1993/linuxmotehook2.git
cd linuxmotehook2
meson --buildtype=release -Db_lto=true --prefix=/usr build
ninja -C build
# Optional
ninja -C build install
```

### Updating
```bash
cd linuxmotehook2
git pull
git submodule update --recursive --init
ninja -C build
# Optional
ninja -C build install
```

## Dependencies
* libudev
* GLib 2.50+
* zlib
* Vala 0.54+ and libgee-0.8 (Ubuntu and derivatives should use [Vala Next PPA](https://launchpad.net/~vala-team/+archive/ubuntu/next))
* meson and ninja
* GCC/Clang

On Ubuntu and derivative the following should do:

```bash
sudo add-apt-repository ppa:vala-team/next
sudo apt-get install build-essentials \
    libudev-dev zlib1g-dev \
    valac libgee-0.8-dev \  
    meson
```
