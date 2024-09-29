#!/bin/sh

if pgrep -x "picom" >/dev/null; then
	killall picom
else
	picom --backend glx --experimental-backends -b
fi
