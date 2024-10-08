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

run "setxkbmap us"
run "/home/$USER/.screenlayout/defaultDisplaySetup.sh"

# if nordvpn is installed, connect to us server
run "nordvpn c us"

run "greenclip daemon"

setxkbmap us altgr-intl

feh --bg-fill ~/wallpaper.jpg
