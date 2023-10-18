# Cemuhook UDP server for WiiMotes on Linux - successor to original linuxmotehook

![GitHub Actions - Build Status](https://img.shields.io/github/actions/workflow/status/v1993/linuxmotehook2/meson.yml)
[![Ko-Fi](https://img.shields.io/badge/support-Ko--Fi-brightgreen)](https://ko-fi.com/v19930312)

[![AUR git package](https://img.shields.io/badge/aur-linuxmotehook2--git-blue)](https://aur.archlinux.org/packages/linuxmotehook2-git)

## Current features

* Support for Wiimotes, Nunchucks, Classic and Pro Controllers
* Support for calibration of gyro and sticks
* Support for buttons/sticks as well as motion
* Support for changing device orientation

### Planned features

* GUI application to assist with calibration and configuration
* Support for reporting IR as touch (potentially useful with dolphin)
* Support for more Wiimote extensions - if requested

## Configuration

No configuration file is required to get started - just run without any arguments to expose all Wiimotes with default settings.
However, you may want one for changing port, controller orientation, or something else.
Check out [wiki](https://github.com/v1993/linuxmotehook2/wiki) for information on how to write a configuration file.

## Quick build guide

```bash
git clone https://github.com/v1993/linuxmotehook2.git
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
meson subprojects update
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

