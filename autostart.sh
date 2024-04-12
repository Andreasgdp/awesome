#!/bin/sh

run() {
	if ! pgrep $1 >/dev/null; then
		$@ &
	fi
}

# run streamdeck only if comand exists
if command -v streamdeck >/dev/null 2>&1; then
	run "streamdeck -n"
fi

killall picom
run "setxkbmap us"
# run "picom --backend glx --experimental-backends"
run "/home/$USER/.screenlayout/defaultDisplaySetup.sh"

# if nordvpn is installed, connect to us server
run "nordvpn c us"

setxkbmap us intl

feh --bg-fill ~/wallpaper.jpg
