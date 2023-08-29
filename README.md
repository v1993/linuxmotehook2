# Cemuhook UDP server for WiiMotes on Linux - successor to original linuxmotehook

![GitHub Actions - Build Status](https://img.shields.io/github/actions/workflow/status/v1993/linuxmotehook2/meson.yml)
[![Ko-Fi](https://img.shields.io/badge/support-Ko--Fi-brightgreen)](https://ko-fi.com/v19930312)

[![AUR git package](https://img.shields.io/badge/aur-linuxmotehook2--git-blue)](https://aur.archlinux.org/packages/linuxmotehook2-git)

**PPAs are not updated for the time being - old workflow got broken by Circle CI and I'm not very interested in recreating it with GitHub actions due to moving to Manjaro myself. Feel free to indicate that there's demand by starting a discussion.**

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
meson setup --buildtype=release -Db_lto=true --prefix=/usr build
meson compile -C build
# Optional
meson install -C build
```

### Updating
```bash
cd linuxmotehook2
git pull
git submodule update --recursive --init
meson compile -C build
# Optional
meson install -C build
```

## Dependencies
* libudev
* GLib 2.50+
* zlib
* Vala 0.56+ and libgee-0.8
* meson
* GCC/Clang

On Ubuntu and derivative the following should do:

```bash
sudo apt-get install build-essential \
    libudev-dev zlib1g-dev \
    valac libgee-0.8-dev \  
    meson
```

## Configuration

Check out [wiki](https://github.com/v1993/linuxmotehook2/wiki) for information on how to write configuration file.
