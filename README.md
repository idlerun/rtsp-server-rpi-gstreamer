---
page: https://idle.run/baby-raspi
title: "GStreamer RTSP Raspberry Pi Camera"
tags: raspberry gstreamer pi stream rtsp
date: 2018-12-26
---

## Overview

The previous v4l2-rtsp-server project wasn't reliable or customizable enough (IE no options to do any server-side processing of video). This is a new route using gstreamer to get a working secure RTSP server running on a Raspberry Pi.


## Setup

- Download Raspian image
- Flash with Etcher

### Prep Headless Config

- Open /boot partition on host
- Create empty file `ssh` to enable ssh
- Create file `wpa_supplicant.conf` to enable wifi

```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=CA

network={
    ssid="«your_SSID»"
    psk="«your_PSK»"
    key_mgmt=WPA-PSK
}
```

- Edit `config.txt` to enable camera

```
start_x=1
gpu_mem=256
disable_camera_led=1
```


- Put the sd card into pi and boot
- SSH to pi



## Dependencies

```
sudo apt update

# gstreamer
sudo apt install -y gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-tools libgstreamer1.0-dev libgstreamer1.0-0-dbg libgstreamer-plugins-base1.0-dev gtk-doc-tools

# omx encoder
sudo apt install -y gstreamer1.0-omx gstreamer1.0-omx-bellagio-config gstreamer1.0-omx-generic gstreamer1.0-omx-generic-config gstreamer1.0-omx-rpi gstreamer1.0-omx-rpi-config

# build deps
sudo apt-get install -y \
    wget git libtool autoconf cmake \
    build-essential pkg-config unzip git-core \
    gtk-doc-tools libglib2.0-dev

```

## Gstreamer Raspberry Pi Camera Source

```
git clone https://github.com/thaytan/gst-rpicamsrc.git
(
cd gst-rpicamsrc
./autogen.sh
make
sudo make install
)
```

## RTSP Server Library

Build project gst-rtsp-server

```
git clone https://github.com/GStreamer/gst-rtsp-server.git
(
cd gst-rtsp-server
git checkout 1.4
./autogen.sh
make
sudo make install
)
```


## Server App

- Add [`server.c`] to `/opt/raspi-rtsp/`
- Customize `server.c` to configure password and port
- Build with `./build.sh`

### Service

Add [`rtsp-server.service`] to `/etc/systemd/system/rtsp-server.service`

Load the SystemD module

```
sudo systemctl enable rtsp-server
sudo systemctl daemon-reload
sudo systemctl start rtsp-server
sudo systemctl status rtsp-server
```

Check logs with

```
sudo journalctl -u rtsp-server
```

## Client

Play with ffplay or other client

```
ffplay \
  -vf "drawtext=fontfile=/Library/Fonts/Arial.ttf: text='%{frame_num}': start_number=1: x=(w-tw)/2: y=h-(2*lh): fontcolor=white: fontsize=20: box=1: boxcolor=black: boxborderw=2" \
  -rtsp_transport udp \
  -sync ext \
  -fflags nobuffer \
  -framedrop \
  rtsp://user:wjJcr4DO0V5OzIrz20@192.168.56.18:8554/stream
```

## References:
- https://www.stev.org/post/raspberrypisimplertspserver
- https://raspberrypi.stackexchange.com/a/57023