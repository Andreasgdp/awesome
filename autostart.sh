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

pkill picom
run "setxkbmap us"
run "picom --backend glx"
run "/home/$USER/.screenlayout/defaultDisplaySetup.sh"
feh --bg-fill ~/wallpaper.jpg
