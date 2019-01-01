---
page: https://idle.run/baby-raspi
title: "GStreamer RTSP Raspberry Pi Camera"
tags: raspberry gstreamer pi stream rtsp
date: 2018-12-26
---

## Overview

This is a new route using gstreamer to get a working secure RTSP server running on a Raspberry Pi. Uses the `gst-rtsp-server` project with a simple wrapper.

The previous attempt using the v4l2-rtsp-server project wasn't reliable or customizable enough (IE no options to do any server-side processing of video).


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
- Set secure password and setup public key based SSH auth (`~/.ssh/authorized_keys`)

## Requirements

Install Docker as described here: https://www.raspberrypi.org/blog/docker-comes-to-raspberry-pi/

```
curl -sSL https://get.docker.com | sh
```



## GStreamer Build

Checkout this repo to `/opt/raspi-rtsp`

GStreamer 1.14 build process is encapsulated in a Docker environment.

Run [`build-gst.sh`] to compile the GStreamer binaries into `/opt/gstreamer`


## Server App

- Customize `server.c` to configure password and port
- Build server with `./build.sh`

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
  -rtsp_transport udp \
  -sync ext \
  -fflags nobuffer \
  -framedrop \
  rtsp://user:wjJcr4DO0V5OzIrz20@192.168.56.18:8554/stream
```


## References:
- https://www.stev.org/post/raspberrypisimplertspserver
- https://raspberrypi.stackexchange.com/a/57023