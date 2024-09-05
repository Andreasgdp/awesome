-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Own Libraries
local volume_widget = require("awesome-wm-widgets.volume-widget.volume")
local logout_menu_widget = require("awesome-wm-widgets.logout-menu-widget.logout-menu")
local batteryarc_widget = require("awesome-wm-widgets.batteryarc-widget.batteryarc")
local apt_widget = require("awesome-wm-widgets.apt-widget.apt-widget")
local brightness_widget = require("awesome-wm-widgets.brightness-widget.brightness")
local switcher = require("awesome-switcher")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")
local show_desktop = false

-- place naughty notifications in the top right corner
naughty.config.defaults.position = "top_right"

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors,
	})
end

local function move_mouse_onto_focused_client(c)
	if mouse.object_under_pointer() ~= c then
		local geometry = c:geometry()
		local x = geometry.x + geometry.width / 2
		local y = geometry.y + geometry.height / 2
		mouse.coords({ x = x, y = y }, true)
	end
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		-- Make sure we don't go into an endless error loop
		if in_error then
			return
		end
		in_error = true

		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err),
		})
		in_error = false
	end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.init(gears.filesystem.get_configuration_dir() .. "theme.lua")

-- This is used later as the default terminal and editor to run.
-- terminal = "warp-terminal"
terminal = "kitty"
-- terminal = "terminator -p Catppuccin_Mocha"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
	awful.layout.suit.tile,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
	{
		"hotkeys",
		function()
			hotkeys_popup.show_help(nil, awful.screen.focused())
		end,
	},
	{ "manual", terminal .. " -e man awesome" },
	{ "edit config", editor_cmd .. " " .. awesome.conffile },
	{ "restart", awesome.restart },
	{
		"quit",
		function()
			awesome.quit()
		end,
	},
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
	mymainmenu = freedesktop.menu.build({
		before = { menu_awesome },
		after = { menu_terminal },
	})
else
	mymainmenu = awful.menu({
		items = { menu_awesome, { "Debian", debian.menu.Debian_menu.Debian }, menu_terminal },
	})
end

mylauncher = awful.widget.launcher({
	image = beautiful.awesome_icon,
	menu = mymainmenu,
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
	awful.button({}, 1, function(t)
		t:view_only()
	end),
	awful.button({ modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({ modkey }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({}, 4, function(t)
		awful.tag.viewnext(t.screen)
	end),
	awful.button({}, 5, function(t)
		awful.tag.viewprev(t.screen)
	end)
)

local tasklist_buttons = gears.table.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c:emit_signal("request::activate", "tasklist", {
				raise = true,
			})
		end
	end),
	awful.button({}, 3, function()
		awful.menu.client_list({
			theme = {
				width = 250,
			},
		})
	end),
	awful.button({}, 4, function()
		awful.client.focus.byidx(1)
	end),
	awful.button({}, 5, function()
		awful.client.focus.byidx(-1)
	end)
)

local function set_wallpaper(s)
	-- Wallpaper
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		-- If wallpaper is a function, call it with the screen
		if type(wallpaper) == "function" then
			wallpaper = wallpaper(s)
		end
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
	-- Wallpaper
	set_wallpaper(s)

	-- Each screen has its own tag table.
	awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contain an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(gears.table.join(
		awful.button({}, 1, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 3, function()
			awful.layout.inc(-1)
		end),
		awful.button({}, 4, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 5, function()
			awful.layout.inc(-1)
		end)
	))
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist({
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = taglist_buttons,
	})

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist({
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = tasklist_buttons,
	})

	-- Create the wibox
	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
	})

	-- Add widgets to the wibox
	local is_laptop = os.execute("hostnamectl chassis | grep -i laptop")

	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			spacing = 7,
			mylauncher,
			s.mytaglist,
			s.mypromptbox,
		},
		s.mytasklist, -- Middle widget
		{ -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			spacing = 10,
			wibox.widget.systray(),
			volume_widget({
				widget_type = "arc",
			}),
			mykeyboardlayout,
			apt_widget(),
			-- Only add brightness and battery widgets if the system is a laptop
			is_laptop
					and brightness_widget({
						type = "icon_and_text",
						program = "brightnessctl",
						step = 5,
					})
				or nil,
			is_laptop and batteryarc_widget({
				show_current_level = true,
				arc_thickness = 2,
				timeout = 1,
			}) or nil,
			mytextclock,
			logout_menu_widget(),
			s.mylayoutbox,
		},
	})
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
	awful.button({}, 3, function()
		mymainmenu:toggle()
	end),
	awful.button({}, 4, awful.tag.viewnext),
	awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join( -- Configure the hotkeys for screenshot
	awful.key({}, "Print", function()
		awful.spawn("flameshot gui")
	end),
	awful.key({ modkey }, "Print", function()
		awful.spawn("peek")
	end),
	awful.key({}, "#123", function()
		volume_widget:inc(5)
	end),
	awful.key({}, "#122", function()
		volume_widget:dec(5)
	end),
	awful.key({}, "#121", function()
		volume_widget:toggle()
	end),
	awful.key({}, "XF86MonBrightnessUp", function()
		brightness_widget:inc()
	end),
	awful.key({}, "XF86MonBrightnessDown", function()
		brightness_widget:dec()
	end),
	awful.key({}, "XF86AudioPlay", function()
		awful.util.spawn(
			"dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause",
			false
		)
	end, {
		description = "play/pause music",
		group = "media",
	}),
	awful.key({}, "XF86AudioNext", function()
		awful.util.spawn(
			"dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next",
			false
		)
	end, {
		description = "next track",
		group = "media",
	}),
	awful.key({}, "XF86AudioPrev", function()
		awful.util.spawn(
			"dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous",
			false
		)
	end, {
		description = "previous track",
		group = "media",
	}),
	awful.key({}, "XF86AudioStop", function()
		awful.util.spawn(
			"dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop",
			false
		)
	end, {
		description = "stop music",
		group = "media",
	}), -- run terminal cmd "lock" on keybind mod4 + ctrl + l
	awful.key({ modkey }, "Escape", function()
		awful.spawn("lock")
	end, {
		description = "lock Screen",
		group = "awesome",
	}),
	awful.key({ modkey }, "e", function()
		awful.spawn("setxkbmap us altgr-intl")
	end, {
		description = "switch keyboardlayout to English US",
	}), -- Configure the hotkeys for alt tab
	awful.key({ "Mod1" }, "Tab", function()
		switcher.switch(1, "Mod1", "Alt_L", "Shift", "Tab")
	end, {
		description = "change windows from left to right",
		group = "awesome",
	}),
	-- toggle picom with super + shift + p
	awful.key({ modkey, "Shift" }, "p", function()
		awful.spawn("bash -c  '~/.config/awesome/toggle-picom.sh'")
	end, {
		description = "toggle picom",
		group = "awesome",
	}),
	awful.key({ "Mod1", "Shift" }, "Tab", function()
		switcher.switch(-1, "Mod1", "Alt_L", "Shift", "Tab")
	end, {
		description = "change windows from right to left",
		group = "awesome",
	}), -- Configue hotkeys for opening specific applications
	-- chrome
	awful.key({ modkey }, "f", function()
		-- awful.spawn("google-chrome-stable")
		-- awful.spawn("firefox")
		awful.spawn("flatpak run io.github.zen_browser.zen")
	end, {
		description = "open chrome",
		group = "launcher",
	}), -- Akiflow (akiflow is installed as a chrome PWA)
	awful.key({ modkey, "Shift" }, "a", function()
		awful.spawn("google-chrome-stable --app=https://web.akiflow.com/#/planner/today")
	end, {
		description = "open akiflow",
		group = "launcher",
	}), -- Messages
	awful.key({ modkey, "Shift" }, "n", function()
		awful.spawn("google-chrome-stable --app=https://mem.ai/everything")
	end, {
		description = "open mem ai for notes",
		group = "launcher",
	}), -- Messages
	awful.key({ modkey, "Shift" }, "m", function()
		awful.spawn("google-chrome-stable --app=https://messages.google.com/web/conversations")
	end, {
		description = "open google messages",
		group = "launcher",
	}), -- Mail inbox (open not as a PWA)
	awful.key({ modkey }, "i", function()
		-- current user is named 'anpe'
		local current_user = os.getenv("USER")
		local email_command = current_user == "anpe"
				and "google-chrome-stable --new-window https://outlook.office.com/mail/inbox"
			or "google-chrome-stable --new-window https://mail.google.com/mail/u/0/#inbox"
		awful.spawn(email_command)
	end, {
		description = "open outlook inbox",
		group = "launcher",
	}), -- Toggle showing the desktop
	awful.key({ modkey, "Control" }, "d", function(c)
		if show_desktop then
			for _, c in ipairs(client.get()) do
				c:emit_signal("request::activate", "key.unminimize", {
					raise = true,
				})
			end
			show_desktop = false
		else
			for _, c in ipairs(client.get()) do
				c.minimized = true
			end
			show_desktop = true
		end
	end, {
		description = "toggle showing the desktop",
		group = "client",
	}), -- Open discord with shift + super + d
	awful.key({ modkey, "Shift" }, "d", function()
		awful.spawn(
			"discord --no-sandbox --ignore-gpu-blocklist --disable-features=UseOzonePlatform --enable-features=VaapiVideoDecoder --use-gl=desktop --enable-gpu-rasterization --enable-zero-copy"
		)
	end, {
		description = "open discord",
		group = "launcher",
	}), -- Open spotify with super + shift + s
	awful.key({ modkey, "Shift" }, "b", function()
		awful.spawn("bash -c '~/Applications/BambuStudio_linux_ubuntu_v01.08.01.57.AppImage'")
	end, {
		description = "open bambulab slicer",
		group = "launcher",
	}),
	awful.key({ modkey, "Shift" }, "s", function()
		awful.spawn("spotify")
	end, {
		description = "open spotify",
		group = "launcher",
	}), -- Open obsidian with super + shift + o
	awful.key({ modkey, "Shift" }, "o", function()
		awful.spawn("obsidian")
	end, {
		description = "open obsidian",
		group = "launcher",
	}), -- Open awesome config in Code - Insiders with super + a
	awful.key({ modkey }, "space", function()
		awful.util.spawn("bash -c  '~/.config/awesome/launch-files/akiflow-command-bar.sh'")
	end, {
		description = "open akiflow command bar",
		group = "awesome",
	}), -- default below
	--------------------------------------------------------------------
	awful.key({ modkey }, "s", hotkeys_popup.show_help, {
		description = "show help",
		group = "awesome",
	}),
	awful.key({ modkey }, "Left", awful.tag.viewprev, {
		description = "view previous",
		group = "tag",
	}),
	awful.key({ modkey }, "Right", awful.tag.viewnext, {
		description = "view next",
		group = "tag",
	}),
	awful.key({ modkey }, "j", function()
		awful.client.focus.global_bydirection("down")
		if mouse.object_under_pointer() ~= client.focus then
			client.focus = nil
		else
			move_mouse_onto_focused_client(client.focus)
		end
	end, {
		description = "focus next by index",
		group = "client",
	}),
	awful.key({ modkey }, "k", function()
		awful.client.focus.global_bydirection("up")
		if mouse.object_under_pointer() ~= client.focus then
			client.focus = nil
		else
			move_mouse_onto_focused_client(client.focus)
		end
	end, {
		description = "focus previous by index",
		group = "client",
	}),
	awful.key({ modkey }, "h", function()
		awful.client.focus.global_bydirection("left")
		if mouse.object_under_pointer() ~= client.focus then
			client.focus = nil
		else
			move_mouse_onto_focused_client(client.focus)
		end
	end, {
		description = "focus previous by index",
		group = "client",
	}),
	awful.key({ modkey }, "l", function()
		awful.client.focus.global_bydirection("right")
		if mouse.object_under_pointer() ~= client.focus then
			client.focus = nil
		else
			move_mouse_onto_focused_client(client.focus)
		end
	end, {
		description = "focus previous by index",
		group = "client",
	}),
	awful.key({ modkey, "Control" }, "w", function()
		mymainmenu:show()
	end, {
		description = "show main menu",
		group = "awesome",
	}), -- Layout manipulation
	-- hjkl swap by direction
	awful.key({ modkey, "Shift" }, "j", function()
		awful.client.swap.global_bydirection("down")
	end, {
		description = "swap with client below",
		group = "client",
	}),
	awful.key({ modkey, "Shift" }, "k", function()
		awful.client.swap.global_bydirection("up")
	end, {
		description = "swap with client above",
		group = "client",
	}),
	awful.key({ modkey, "Shift" }, "h", function()
		awful.client.swap.global_bydirection("left")
	end, {
		description = "swap with client to the left",
		group = "client",
	}),
	awful.key({ modkey, "Shift" }, "l", function()
		awful.client.swap.global_bydirection("right")
	end, {
		description = "swap with client to the right",
		group = "client",
	}),
	awful.key({ modkey, "Control" }, "j", function()
		awful.screen.focus_relative(1)
	end, {
		description = "focus the next screen",
		group = "screen",
	}),
	awful.key({ modkey, "Control" }, "k", function()
		awful.screen.focus_relative(-1)
	end, {
		description = "focus the previous screen",
		group = "screen",
	}),
	awful.key({ modkey, "Control" }, "Left", function()
		awful.screen.focus_relative(1)
	end, {
		description = "focus the next screen",
		group = "screen",
	}),
	awful.key({ modkey, "Control" }, "Right", function()
		awful.screen.focus_relative(-1)
	end, {
		description = "focus the previous screen",
		group = "screen",
	}),
	awful.key({ modkey }, "u", awful.client.urgent.jumpto, {
		description = "jump to urgent client",
		group = "client",
	}),
	awful.key({ modkey }, "Tab", function()
		awful.client.focus.history.previous()
		if client.focus then
			client.focus:raise()
		end
	end, {
		description = "go back",
		group = "client",
	}), -- Standard program
	awful.key({ modkey }, "Return", function()
		awful.spawn(terminal)
	end, {
		description = "open a terminal",
		group = "launcher",
	}),
	awful.key({ modkey, "Control" }, "r", awesome.restart, {
		description = "reload awesome",
		group = "awesome",
	}),
	awful.key({ modkey, "Shift" }, "delete", awesome.quit, {
		description = "quit awesome",
		group = "awesome",
	}),
	awful.key({ modkey, "Control" }, "l", function()
		awful.tag.incmwfact(0.05)
	end, {
		description = "increase master width factor",
		group = "layout",
	}),
	awful.key({ modkey, "Control" }, "h", function()
		awful.tag.incmwfact(-0.05)
	end, {
		description = "decrease master width factor",
		group = "layout",
	}),
	awful.key({ modkey }, "r", function()
		awful.screen.focused().mypromptbox:run()
	end, {
		description = "run prompt",
		group = "launcher",
	}),
	awful.key({ modkey }, "x", function()
		awful.prompt.run({
			prompt = "Run Lua code: ",
			textbox = awful.screen.focused().mypromptbox.widget,
			exe_callback = awful.util.eval,
			history_path = awful.util.get_cache_dir() .. "/history_eval",
		})
	end, {
		description = "lua execute prompt",
		group = "awesome",
	}), -- Menubar
	-- awful.key({ modkey }, "p", function()
	-- 	menubar.show()
	-- end, { description = "show the menubar", group = "launcher" }),
	awful.key({ modkey }, "p", function()
		awful.spawn("rofi -show drun -show-icons")
	end, {
		description = "rofi launcher",
		group = "launcher",
	})
)

clientkeys = gears.table.join(
	awful.key({ "Mod1" }, "Return", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, {
		description = "toggle fullscreen",
		group = "client",
	}),
	awful.key({ modkey, "Shift" }, "c", function(c)
		c:kill()
	end, {
		description = "close",
		group = "client",
	}),
	awful.key({ modkey }, "q", function(c)
		c:kill()
	end, {
		description = "close",
		group = "client",
	}),
	awful.key({ modkey }, "w", awful.client.floating.toggle, {
		description = "toggle floating",
		group = "client",
	}),
	awful.key({ modkey, "Control" }, "Return", function(c)
		c:swap(awful.client.getmaster())
	end, {
		description = "move to master",
		group = "client",
	}),
	awful.key({ modkey }, "o", function(c)
		c:move_to_screen()
	end, {
		description = "move to screen",
		group = "client",
	}),
	awful.key({ modkey, "Shift" }, "Left", function(c)
		c:move_to_screen(c.screen.index + 1)
	end, {
		description = "move currently selected client to left display",
		group = "client",
	}),
	awful.key({ modkey, "Shift" }, "Right", function(c)
		c:move_to_screen(c.screen.index - 1)
	end, {
		description = "move currently selected client to right display",
		group = "client",
	}),
	awful.key({ modkey }, "t", function(c)
		c.ontop = not c.ontop
	end, {
		description = "toggle keep on top",
		group = "client",
	}),
	awful.key({ modkey }, "n", function(c)
		-- The client currently has the input focus, so it cannot be
		-- minimized, since minimized clients can't have the focus.
		c.minimized = true
	end, {
		description = "minimize",
		group = "client",
	}),
	awful.key({ modkey }, "m", function(c)
		c.maximized = not c.maximized
		c:raise()
	end, {
		description = "(un)maximize",
		group = "client",
	}),
	awful.key({ modkey, "Control" }, "m", function(c)
		c.maximized_vertical = not c.maximized_vertical
		c:raise()
	end, {
		description = "(un)maximize vertically",
		group = "client",
	}),
	awful.key({ modkey, "Shift" }, "m", function(c)
		c.maximized_horizontal = not c.maximized_horizontal
		c:raise()
	end, {
		description = "(un)maximize horizontally",
		group = "client",
	})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = gears.table.join(
		globalkeys, -- View tag only.
		awful.key({ modkey }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, {
			description = "view tag #" .. i,
			group = "tag",
		}), -- Toggle tag display.
		awful.key({ modkey, "Control" }, "#" .. i + 9, function()
			-- for all screens view tag #i
			for s in screen do
				local tag = s.tags[i]
				if tag then
					tag:view_only()
				end
			end
		end, {
			description = "for all screens view tag #" .. i,
			group = "tag",
		}),
		-- Move every clients from all tags to selected tag (modkey + shift + ctrl + #) on the current screen. No client shold be needed to be focused.
		awful.key({ modkey, "Shift", "Control" }, "#" .. i + 9, function()
			for s in screen do
				local tag = s.tags[i]
				if tag then
					tag:view_only()
				end
			end

			local focusedScreen = awful.screen.focused()
			local tag = focusedScreen.tags[i]
			if tag then
				for _, c in ipairs(client.get()) do
					c:move_to_tag(tag)
				end
			end
		end, {
			description = "reset all screens to- and move all clients to tag #" .. i,
			group = "tag",
		}), -- Toggle tag display.
		awful.key({ modkey, "Mod1" }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end, {
			description = "toggle tag #" .. i,
			group = "tag",
		}), -- Move client to tag.
		awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end, {
			description = "move focused client to tag #" .. i,
			group = "tag",
		}), -- Toggle tag on focused client.
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end, {
			description = "toggle focused client on tag #" .. i,
			group = "tag",
		})
	)
end

clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", {
			raise = true,
		})
	end),
	awful.button({ modkey }, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", {
			raise = true,
		})
		awful.mouse.client.move(c)
	end),
	awful.button({ modkey }, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", {
			raise = true,
		})
		awful.mouse.client.resize(c)
	end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = { -- All clients will match this rule.
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
			size_hints_honor = false,
		},
	}, -- Floating clients.
	{
		rule_any = {
			instance = {
				"DTA", -- Firefox addon DownThemAll.
				"copyq", -- Includes session name in class.
				"pinentry",
			},
			class = {
				"Arandr",
				"Blueman-manager",
				"Gpick",
				"Kruler",
				"MessageWin", -- kalarm.
				"Sxiv",
				"Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
				"Wpa_gui",
				"veromix",
				"xtightvncviewer",
			},

			-- Note that the name property shown in xprop might be set slightly after creation of the client
			-- and the name shown there might not match defined rules here.
			name = {
				"Event Tester", -- xev.
			},
			role = {
				"AlarmWindow", -- Thunderbird's calendar.
				"ConfigManager", -- Thunderbird's about:config.
				"pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
			},
		},
		properties = {
			floating = true,
		},
	}, -- spotify tile and unminimized
	{
		rule_any = {
			class = { "Spotify", "Code - Insiders", "obsidian", "gazebo" },
			name = { "Akiflow", "Messages" },
		},
		properties = {
			floating = false,
		},
	}, -- if a window has WM_WINDOW_ROLE(STRING) = "pop-up" set it to floating = false
	{
		rule = {
			role = "pop-up",
		},
		properties = {
			floating = false,
		},
	}, -- Add titlebars to normal clients and dialogs
	{
		rule_any = {
			type = { "normal", "dialog" },
		},
		properties = {
			titlebars_enabled = false,
		},
	},
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
	-- Set the windows at the slave,
	-- i.e. put it at the end of others instead of setting it master.
	-- if not awesome.startup then awful.client.setslave(c) end

	-- Adds rounded corners to the clients
	c.shape = function(cr, w, h)
		gears.shape.rounded_rect(cr, w, h, 5)
	end

	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		-- Prevent clients from being unreachable after screen count changes.
		awful.placement.no_offscreen(c)
	end
end)

client.connect_signal("property::maximized", function(c)
	if c.maximized and c.class == "Code - Insiders" then
		c.maximized = false
	end
	if c.maximized and c.class == "gazebo" then
		c.maximized = false
	end
	if c.maximized and c.class == "Spotify" then
		c.maximized = false
	end
	if c.maximized and c.name == "Akiflow" then
		c.maximized = false
	end
	if c.maximized and c.name == "Messages" then
		c.maximized = false
	end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
	-- buttons for the titlebar
	local buttons = gears.table.join(
		awful.button({}, 1, function()
			c:emit_signal("request::activate", "titlebar", {
				raise = true,
			})
			awful.mouse.client.move(c)
		end),
		awful.button({}, 3, function()
			c:emit_signal("request::activate", "titlebar", {
				raise = true,
			})
			awful.mouse.client.resize(c)
		end)
	)

	awful
		.titlebar(c, {
			size = 15,
		})
		:setup({
			{ -- Left
				awful.titlebar.widget.iconwidget(c),
				buttons = buttons,
				layout = wibox.layout.fixed.horizontal,
			},
			{ -- Middle
				{ -- Title
					align = "center",
					widget = awful.titlebar.widget.titlewidget(c),
				},
				buttons = buttons,
				layout = wibox.layout.flex.horizontal,
			},
			{ -- Right
				awful.titlebar.widget.floatingbutton(c),
				awful.titlebar.widget.maximizedbutton(c),
				awful.titlebar.widget.stickybutton(c),
				awful.titlebar.widget.ontopbutton(c),
				awful.titlebar.widget.closebutton(c),
				layout = wibox.layout.fixed.horizontal(),
			},
			layout = wibox.layout.align.horizontal,
		})
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
	c:emit_signal("request::activate", "mouse_enter", {
		raise = false,
	})
end)

client.connect_signal("swapped", function(c, is_source)
	if is_source then
		move_mouse_onto_focused_client(c)
	end
end)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
	move_mouse_onto_focused_client(c)
end)

client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- }}}

client.connect_signal("property::floating", function(c)
	-- if a client that is fullscreen do nothing
	if c.fullscreen then
		return
	end

	if c.floating then
		c.ontop = true
	else
		c.ontop = false
	end
end)

-- Enable gaps
beautiful.useless_gap = 6
beautiful.gap_single_client = true

local catppuccin_colors = {
	bg = "#1E1E2E", -- Base background
	fg = "#CDD6F4", -- Foreground text
	red = "#F38BA8", -- Red
	green = "#A6E3A1", -- Green
	yellow = "#F9E2AF", -- Yellow
	blue = "#89B4FA", -- Blue
	magenta = "#F5C2E7", -- Magenta
	cyan = "#94E2D5", -- Cyan
	white = "#BAC2DE", -- White
	black = "#11111B", -- Black
}

-- Apply the colors to the theme
beautiful.bg_normal = catppuccin_colors.bg
beautiful.fg_normal = catppuccin_colors.fg
beautiful.bg_focus = catppuccin_colors.blue
beautiful.fg_focus = catppuccin_colors.bg
beautiful.bg_urgent = catppuccin_colors.red
beautiful.fg_urgent = catppuccin_colors.bg
beautiful.border_normal = catppuccin_colors.black
beautiful.border_focus = catppuccin_colors.blue
beautiful.border_marked = catppuccin_colors.green
beautiful.titlebar_bg_focus = catppuccin_colors.bg
beautiful.titlebar_bg_normal = catppuccin_colors.bg
beautiful.titlebar_fg_focus = catppuccin_colors.fg
beautiful.titlebar_fg_normal = catppuccin_colors.fg
beautiful.taglist_bg_occupied = catppuccin_colors.bg

-- Add garbage collection
gears.timer.start_new(10, function()
	collectgarbage("step", 30000)
	return true
end)

-- autostart
awful.spawn.with_shell("~/.config/awesome/autostart.sh")
