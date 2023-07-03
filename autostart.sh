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
