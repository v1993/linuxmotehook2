# Cemuhook UDP server for WiiMotes on Linux - successor to original linuxmotehook

[![Ko-Fi](https://img.shields.io/badge/support-Ko--Fi-brightgreen)](https://ko-fi.com/v19930312)

## Current features

* Support for Wiimotes and Nunchucks
* Support for calibration of gyro and nunchuck stick
* Support for buttons/sticks as well as motion

### Planned features - short-term

* Support changing device orientation
* GUI application to assist with calibration and configuration
* Documentation for configuration files

### Planned features - mid-term

* CI for testing and deployment
* PPA for easy installation and updates

### Planned features - long-term

* Support for reporting IR as touch (potentially useful with dolphin)
* Support for more Wiimote extensions - if requested

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
