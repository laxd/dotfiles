#!/bin/bash
scrot /tmp/screenshot.png
ffmpeg -loglevel quiet -y -i /tmp/screenshot.png -vf "gblur=sigma=20" /tmp/screenshot_blur.png
i3lock -i /tmp/screenshot_blur.png
rm /tmp/screenshot.png /tmp/screenshot_blur.png
