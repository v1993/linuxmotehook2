# Cemuhook UDP server for WiiMotes on Linux - successor to original linuxmotehook

[![Ko-Fi](https://img.shields.io/badge/support-Ko--Fi-brightgreen)](https://ko-fi.com/v19930312)

**PPAs are not updated for the time being due to Circle CI ceasing all operations in Russia (including free plan). I'll probably move to GitHub Actions if I'll ever get to it.**

## Current features

* Support for Wiimotes, Nunchucks, Classic and Pro Controllers
* Support for calibration of gyro and sticks
* Support for buttons/sticks as well as motion
* Support for changing device orientation

### Planned features - short-term

* GUI application to assist with calibration and configuration
* Documentation for configuration files

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
sudo apt-get install build-essential \
    libudev-dev zlib1g-dev \
    valac libgee-0.8-dev \  
    meson
```

## Configuration

Check out [wiki](https://github.com/v1993/linuxmotehook2/wiki) for information on how to write configuration file.
