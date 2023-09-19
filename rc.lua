-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Own Libraries
local volume_widget = require("awesome-wm-widgets.volume-widget.volume")
local logout_menu_widget = require("awesome-wm-widgets.logout-menu-widget.logout-menu")
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

-- place naughty notifications in the bottom right corner
naughty.config.defaults.position = "bottom_right"

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
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
            text = tostring(err)
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {awful.layout.suit.tile.left, awful.layout.suit.tile, awful.layout.suit.tile.bottom,
                        awful.layout.suit.tile.top, awful.layout.suit.fair, awful.layout.suit.fair.horizontal,
                        awful.layout.suit.spiral, awful.layout.suit.spiral.dwindle, awful.layout.suit.max,
                        awful.layout.suit.max.fullscreen, awful.layout.suit.magnifier, awful.layout.suit.corner.nw,
                        awful.layout.suit.floating -- awful.layout.suit.corner.ne,
-- awful.layout.suit.corner.sw,
-- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {{"hotkeys", function()
    hotkeys_popup.show_help(nil, awful.screen.focused())
end}, {"manual", terminal .. " -e man awesome"}, {"edit config", editor_cmd .. " " .. awesome.conffile},
                 {"restart", awesome.restart}, {"quit", function()
    awesome.quit()
end}}

local menu_awesome = {"awesome", myawesomemenu, beautiful.awesome_icon}
local menu_terminal = {"open terminal", terminal}

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = {menu_awesome},
        after = {menu_terminal}
    })
else
    mymainmenu = awful.menu({
        items = {menu_awesome, {"Debian", debian.menu.Debian_menu.Debian}, menu_terminal}
    })
end

mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mymainmenu
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
local taglist_buttons = gears.table.join(awful.button({}, 1, function(t)
    t:view_only()
end), awful.button({modkey}, 1, function(t)
    if client.focus then
        client.focus:move_to_tag(t)
    end
end), awful.button({}, 3, awful.tag.viewtoggle), awful.button({modkey}, 3, function(t)
    if client.focus then
        client.focus:toggle_tag(t)
    end
end), awful.button({}, 4, function(t)
    awful.tag.viewnext(t.screen)
end), awful.button({}, 5, function(t)
    awful.tag.viewprev(t.screen)
end))

local tasklist_buttons = gears.table.join(awful.button({}, 1, function(c)
    if c == client.focus then
        c.minimized = true
    else
        c:emit_signal("request::activate", "tasklist", {
            raise = true
        })
    end
end), awful.button({}, 3, function()
    awful.menu.client_list({
        theme = {
            width = 250
        }
    })
end), awful.button({}, 4, function()
    awful.client.focus.byidx(1)
end), awful.button({}, 5, function()
    awful.client.focus.byidx(-1)
end))

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
    awful.tag({"1", "2", "3", "4", "5", "6", "7", "8", "9"}, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(awful.button({}, 1, function()
        awful.layout.inc(1)
    end), awful.button({}, 3, function()
        awful.layout.inc(-1)
    end), awful.button({}, 4, function()
        awful.layout.inc(1)
    end), awful.button({}, 5, function()
        awful.layout.inc(-1)
    end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    })

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    })

    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s
    })

    -- Add widgets to the wibox
    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            volume_widget({
                widget_type = "arc"
            }),
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            logout_menu_widget(),
            s.mylayoutbox
        }
    })
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(awful.button({}, 3, function()
    mymainmenu:toggle()
end), awful.button({}, 4, awful.tag.viewnext), awful.button({}, 5, awful.tag.viewprev)))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join( -- Configure the hotkeys for screenshot
awful.key({}, "Print", function()
    awful.spawn("flameshot gui")
end), -- sudo add-apt-repository ppa:peek-developers/stable
-- sudo apt-get update
-- sudo apt-get install peek
awful.key({modkey}, "Print", function()
    awful.spawn("peek")
end), -- Configure the hotkeys for volume
awful.key({}, "#123", function()
    volume_widget:inc(5)
end), awful.key({}, "#122", function()
    volume_widget:dec(5)
end), awful.key({}, "#121", function()
    volume_widget:toggle()
end), -- Configure the hotkeys for media control
awful.key({}, "XF86AudioPlay", function()
    awful.util.spawn(
        "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause",
        false)
end, {
    description = "play/pause music",
    group = "media"
}), awful.key({}, "XF86AudioNext", function()
    awful.util.spawn(
        "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next",
        false)
end, {
    description = "next track",
    group = "media"
}), awful.key({}, "XF86AudioPrev", function()
    awful.util.spawn(
        "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous",
        false)
end, {
    description = "previous track",
    group = "media"
}), awful.key({}, "XF86AudioStop", function()
    awful.util.spawn(
        "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop",
        false)
end, {
    description = "stop music",
    group = "media"
}), -- run terminal cmd "lock" on keybind mod4 + ctrl + l
awful.key({modkey, "Ctrl"}, "l", function()
    awful.spawn("lock")
end, {
    description = "lock Screen",
    group = "awesome"
}), -- Configure keyboardlayout switcher using setxkbmap us and setxkbmap dk
awful.key({modkey}, "d", function()
    awful.spawn("setxkbmap dk")
end, {
    description = "switch keyboardlayout to Danish DK"
}), awful.key({modkey}, "e", function()
    awful.spawn("setxkbmap us")
end, {
    description = "switch keyboardlayout to English US"
}), -- Configure the hotkeys for alt tab
awful.key({"Mod1"}, "Tab", function()
    switcher.switch(1, "Mod1", "Alt_L", "Shift", "Tab")
end, {
    description = "change windows from left to right",
    group = "awesome"
}), awful.key({"Mod1", "Shift"}, "Tab", function()
    switcher.switch(-1, "Mod1", "Alt_L", "Shift", "Tab")
end, {
    description = "change windows from right to left",
    group = "awesome"
}), -- Configue hotkeys for opening specific applications
-- chrome
awful.key({modkey}, "c", function()
    awful.spawn("google-chrome-stable")
end, {
    description = "open chrome",
    group = "launcher"
}), -- Akiflow (akiflow is installed as a chrome PWA)
awful.key({modkey, "Shift"}, "a", function()
    awful.spawn("google-chrome-stable --app=https://web.akiflow.com/#/planner/today")
end, {
    description = "open akiflow",
    group = "launcher"
}), -- Mail inbox (open not as a PWA)
awful.key({modkey}, "i", function()
    -- current user is named 'anpe'
    local current_user = os.getenv("USER")
    local email_command = current_user == "anpe" and
                              "google-chrome-stable --new-window https://outlook.office.com/mail/inbox" or
                              "google-chrome-stable --new-window https://mail.google.com/mail/u/0/#inbox"
    awful.spawn(email_command)
end, {
    description = "open outlook inbox",
    group = "launcher"
}), -- Toggle showing the desktop
awful.key({modkey, "Control"}, "d", function(c)
    if show_desktop then
        for _, c in ipairs(client.get()) do
            c:emit_signal("request::activate", "key.unminimize", {
                raise = true
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
    group = "client"
}), -- Open discord with shift + super + d
awful.key({modkey, "Shift"}, "d", function()
    awful.spawn(
        "discord --no-sandbox --ignore-gpu-blocklist --disable-features=UseOzonePlatform --enable-features=VaapiVideoDecoder --use-gl=desktop --enable-gpu-rasterization --enable-zero-copy")
end, {
    description = "open discord",
    group = "launcher"
}), -- Open spotify with super + shift + s
awful.key({modkey, "Shift"}, "s", function()
    awful.spawn("spotify")
end, {
    description = "open spotify",
    group = "launcher"
}), -- Open obsidian with super + shift + o
awful.key({modkey, "Shift"}, "o", function()
    awful.spawn("obsidian")
end, {
    description = "open obsidian",
    group = "launcher"
}), -- Open awesome config in Code - Insiders with super + a
awful.key({modkey}, "a", function()
    awful.spawn("bash -c 'code ~/.config/awesome/'")
end, {
    description = "open awesome config",
    group = "launcher"
}), -- Using alt + space run the akiflow-command-bar.sh script
-- Make sure to have xdotool istalled - sudo apt install xdotool
awful.key({'Mod1'}, "space", function()
    awful.util.spawn("bash -c  '~/.config/awesome/launch-files/akiflow-command-bar.sh'")
end, {
    description = "open akiflow command bar",
    group = "awesome"
}), -- default below
--------------------------------------------------------------------
awful.key({modkey}, "s", hotkeys_popup.show_help, {
    description = "show help",
    group = "awesome"
}), awful.key({modkey}, "Left", awful.tag.viewprev, {
    description = "view previous",
    group = "tag"
}), awful.key({modkey}, "Right", awful.tag.viewnext, {
    description = "view next",
    group = "tag"
}), awful.key({modkey, "Mod1"}, "Right", function()
    -- move selected window in current tag to the right tag
    local curr_screen = awful.screen.focused()
    local curr_tag = curr_screen.selected_tag
    local curr_tag_index = curr_tag.index
    local next_tag_index = curr_tag_index + 1
    local next_tag = curr_screen.tags[next_tag_index]
    if next_tag then
        local c = client.focus
        if c then
            c:move_to_tag(next_tag)
        end
    end
    awful.tag.viewnext()
end, {
    description = "move selected window in current tag to the right tag",
    group = "screen"
}), awful.key({modkey, "Mod1"}, "Left", function()
    -- move selected window in current tag to the left tag
    local curr_screen = awful.screen.focused()
    local curr_tag = curr_screen.selected_tag
    local curr_tag_index = curr_tag.index
    local prev_tag_index = curr_tag_index - 1
    local prev_tag = curr_screen.tags[prev_tag_index]
    if prev_tag then
        local c = client.focus
        if c then
            c:move_to_tag(prev_tag)
        end
    end
    awful.tag.viewprev()
end, {
    description = "move selected window in current tag to the left tag",
    group = "screen"
}), awful.key({modkey, "Control", "Mod1"}, "Right", function()
    -- move all windows in current tag to the right tag
    local curr_screen = awful.screen.focused()
    local curr_tag = curr_screen.selected_tag
    local curr_tag_index = curr_tag.index
    local next_tag_index = curr_tag_index + 1
    local next_tag = curr_screen.tags[next_tag_index]
    if next_tag then
        for _, c in ipairs(curr_tag:clients()) do
            c:move_to_tag(next_tag)
        end
    end
    awful.tag.viewnext()
end, {
    description = "move all windows in current tag to the right tag",
    group = "screen"
}), awful.key({modkey, "Control", "Mod1"}, "Left", function()
    -- move all windows in current tag to the left tag
    local curr_screen = awful.screen.focused()
    local curr_tag = curr_screen.selected_tag
    local curr_tag_index = curr_tag.index
    local prev_tag_index = curr_tag_index - 1
    local prev_tag = curr_screen.tags[prev_tag_index]
    if prev_tag then
        for _, c in ipairs(curr_tag:clients()) do
            c:move_to_tag(prev_tag)
        end
    end
    awful.tag.viewprev()
end, {
    description = "move all windows in current tag to the right tag",
    group = "screen"
}), awful.key({modkey, "Shift"}, "Right", function()
    -- move currently selected window to right screen
    local curr_screen = awful.screen.focused()
    local curr_screen_index = curr_screen.index
    local next_screen_index = curr_screen_index + 1
    local next_screen = screen[next_screen_index]
    if next_screen then
        local c = client.focus
        if c then
            c:move_to_screen(next_screen)
        end
    end
end, {
    description = "move currently selected window to right screen",
    group = "screen"
}), awful.key({modkey, "Shift"}, "Left", function()
    -- move currently selected window to left screen
    local curr_screen = awful.screen.focused()
    local curr_screen_index = curr_screen.index
    local prev_screen_index = curr_screen_index - 1
    local prev_screen = screen[prev_screen_index]
    if prev_screen then
        local c = client.focus
        if c then
            c:move_to_screen(prev_screen)
        end
    end
end, {
    description = "move currently selected window to left screen",
    group = "screen"
}), awful.key({modkey, "Control"}, "Left", function()
    for i = 1, screen.count() do
        awful.tag.viewprev(i)
    end
end), awful.key({modkey, "Control"}, "Right", function()
    for i = 1, screen.count() do
        awful.tag.viewnext(i)
    end
end), awful.key({modkey}, "Escape", awful.tag.history.restore, {
    description = "go back",
    group = "tag"
}), awful.key({modkey}, "j", function()
    awful.client.focus.byidx(1)
end, {
    description = "focus next by index",
    group = "client"
}), awful.key({modkey}, "k", function()
    awful.client.focus.byidx(-1)
end, {
    description = "focus previous by index",
    group = "client"
}), awful.key({modkey}, "w", function()
    mymainmenu:show()
end, {
    description = "show main menu",
    group = "awesome"
}), -- Layout manipulation
awful.key({modkey, "Shift"}, "j", function()
    awful.client.swap.byidx(1)
end, {
    description = "swap with next client by index",
    group = "client"
}), awful.key({modkey, "Shift"}, "k", function()
    awful.client.swap.byidx(-1)
end, {
    description = "swap with previous client by index",
    group = "client"
}), awful.key({modkey, "Control"}, "j", function()
    awful.screen.focus_relative(1)
end, {
    description = "focus the next screen",
    group = "screen"
}), awful.key({modkey, "Control"}, "k", function()
    awful.screen.focus_relative(-1)
end, {
    description = "focus the previous screen",
    group = "screen"
}), awful.key({modkey}, "u", awful.client.urgent.jumpto, {
    description = "jump to urgent client",
    group = "client"
}), awful.key({modkey}, "Tab", function()
    awful.client.focus.history.previous()
    if client.focus then
        client.focus:raise()
    end
end, {
    description = "go back",
    group = "client"
}), -- Standard program
awful.key({modkey}, "Return", function()
    awful.spawn(terminal)
end, {
    description = "open a terminal",
    group = "launcher"
}), awful.key({modkey, "Control"}, "r", awesome.restart, {
    description = "reload awesome",
    group = "awesome"
}), awful.key({modkey, "Shift"}, "q", awesome.quit, {
    description = "quit awesome",
    group = "awesome"
}), awful.key({modkey}, "l", function()
    awful.tag.incmwfact(0.05)
end, {
    description = "increase master width factor",
    group = "layout"
}), awful.key({modkey}, "h", function()
    awful.tag.incmwfact(-0.05)
end, {
    description = "decrease master width factor",
    group = "layout"
}), awful.key({modkey, "Shift"}, "h", function()
    awful.tag.incnmaster(1, nil, true)
end, {
    description = "increase the number of master clients",
    group = "layout"
}), awful.key({modkey, "Shift"}, "l", function()
    awful.tag.incnmaster(-1, nil, true)
end, {
    description = "decrease the number of master clients",
    group = "layout"
}), awful.key({modkey, "Control"}, "h", function()
    awful.tag.incncol(1, nil, true)
end, {
    description = "increase the number of columns",
    group = "layout"
}), awful.key({modkey, "Control"}, "l", function()
    awful.tag.incncol(-1, nil, true)
end, {
    description = "decrease the number of columns",
    group = "layout"
}), awful.key({modkey}, "space", function()
    awful.layout.inc(1)
end, {
    description = "select next",
    group = "layout"
}), awful.key({modkey, "Shift"}, "space", function()
    awful.layout.inc(-1)
end, {
    description = "select previous",
    group = "layout"
}), awful.key({modkey, "Control"}, "n", function()
    local c = awful.client.restore()
    -- Focus restored client
    if c then
        c:emit_signal("request::activate", "key.unminimize", {
            raise = true
        })
    end
end, {
    description = "restore minimized",
    group = "client"
}), -- Prompt
awful.key({modkey}, "r", function()
    awful.screen.focused().mypromptbox:run()
end, {
    description = "run prompt",
    group = "launcher"
}), awful.key({modkey}, "x", function()
    awful.prompt.run({
        prompt = "Run Lua code: ",
        textbox = awful.screen.focused().mypromptbox.widget,
        exe_callback = awful.util.eval,
        history_path = awful.util.get_cache_dir() .. "/history_eval"
    })
end, {
    description = "lua execute prompt",
    group = "awesome"
}), -- Menubar
-- awful.key({ modkey }, "p", function()
-- 	menubar.show()
-- end, { description = "show the menubar", group = "launcher" }),
awful.key({modkey}, "p", function()
    awful.spawn("rofi -show drun -show-icons")
end, {
    description = "rofi launcher",
    group = "launcher"
}))

clientkeys = gears.table.join(awful.key({modkey}, "f", function(c)
    c.fullscreen = not c.fullscreen
    c:raise()
end, {
    description = "toggle fullscreen",
    group = "client"
}), awful.key({modkey, "Shift"}, "c", function(c)
    c:kill()
end, {
    description = "close",
    group = "client"
}), awful.key({modkey, "Control"}, "space", awful.client.floating.toggle, {
    description = "toggle floating",
    group = "client"
}), awful.key({modkey, "Control"}, "Return", function(c)
    c:swap(awful.client.getmaster())
end, {
    description = "move to master",
    group = "client"
}), awful.key({modkey}, "o", function(c)
    c:move_to_screen()
end, {
    description = "move to screen",
    group = "client"
}), awful.key({modkey}, "t", function(c)
    c.ontop = not c.ontop
end, {
    description = "toggle keep on top",
    group = "client"
}), awful.key({modkey}, "n", function(c)
    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    c.minimized = true
end, {
    description = "minimize",
    group = "client"
}), awful.key({modkey}, "m", function(c)
    c.maximized = not c.maximized
    c:raise()
end, {
    description = "(un)maximize",
    group = "client"
}), awful.key({modkey, "Control"}, "m", function(c)
    c.maximized_vertical = not c.maximized_vertical
    c:raise()
end, {
    description = "(un)maximize vertically",
    group = "client"
}), awful.key({modkey, "Shift"}, "m", function(c)
    c.maximized_horizontal = not c.maximized_horizontal
    c:raise()
end, {
    description = "(un)maximize horizontally",
    group = "client"
}))

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys, -- View tag only.
    awful.key({modkey}, "#" .. i + 9, function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
            tag:view_only()
        end
    end, {
        description = "view tag #" .. i,
        group = "tag"
    }), -- Toggle tag display.
    awful.key({modkey, "Control"}, "#" .. i + 9, function()
        -- for all screens view tag #i
        for s in screen do
            local tag = s.tags[i]
            if tag then
                tag:view_only()
            end
        end
    end, {
        description = "for all screens view tag #" .. i,
        group = "tag"
    }),
        -- Move every clients from all tags to selected tag (modkey + shift + ctrl + #) on the current screen. No client shold be needed to be focused.
        awful.key({modkey, "Shift", "Control"}, "#" .. i + 9, function()
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
            group = "tag"
        }), -- Toggle tag display.
        awful.key({modkey, "Mod1"}, "#" .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end, {
            description = "toggle tag #" .. i,
            group = "tag"
        }), -- Move client to tag.
        awful.key({modkey, "Shift"}, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end, {
            description = "move focused client to tag #" .. i,
            group = "tag"
        }), -- Toggle tag on focused client.
        awful.key({modkey, "Control", "Shift"}, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end, {
            description = "toggle focused client on tag #" .. i,
            group = "tag"
        }))
end

clientbuttons = gears.table.join(awful.button({}, 1, function(c)
    c:emit_signal("request::activate", "mouse_click", {
        raise = true
    })
end), awful.button({modkey}, 1, function(c)
    c:emit_signal("request::activate", "mouse_click", {
        raise = true
    })
    awful.mouse.client.move(c)
end), awful.button({modkey}, 3, function(c)
    c:emit_signal("request::activate", "mouse_click", {
        raise = true
    })
    awful.mouse.client.resize(c)
end))

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
        size_hints_honor = false
    }
}, -- Floating clients.
{
    rule_any = {
        instance = {"DTA", -- Firefox addon DownThemAll.
        "copyq", -- Includes session name in class.
        "pinentry"},
        class = {"Arandr", "Blueman-manager", "Gpick", "Kruler", "MessageWin", -- kalarm.
        "Sxiv", "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
        "Wpa_gui", "veromix", "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {"Event Tester" -- xev.
        },
        role = {"AlarmWindow", -- Thunderbird's calendar.
        "ConfigManager", -- Thunderbird's about:config.
        "pop-up" -- e.g. Google Chrome's (detached) Developer Tools.
        }
    },
    properties = {
        floating = true
    }
}, -- spotify tile and unminimized
{
    rule_any = {
        class = {"Spotify", "Code - Insiders", "obsidian", "gazebo"},
        name = {"Akiflow", "Messages"}
    },
    properties = {
        floating = false
    }
}, -- if a window has WM_WINDOW_ROLE(STRING) = "pop-up" set it to floating = false
{
    rule = {
        role = "pop-up"
    },
    properties = {
        floating = false
    }
}, -- Add titlebars to normal clients and dialogs
{
    rule_any = {
        type = {"normal", "dialog"}
    },
    properties = {
        titlebars_enabled = true
    }
} -- Set Firefox to always map on the tag named "2" on screen 1.
-- { rule = { class = "Firefox" },
--   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

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
    local buttons = gears.table.join(awful.button({}, 1, function()
        c:emit_signal("request::activate", "titlebar", {
            raise = true
        })
        awful.mouse.client.move(c)
    end), awful.button({}, 3, function()
        c:emit_signal("request::activate", "titlebar", {
            raise = true
        })
        awful.mouse.client.resize(c)
    end))

    awful.titlebar(c, {
        size = 15
    }):setup({
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    })
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {
        raise = false
    })
end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)
-- }}}

-- Enable gaps
beautiful.useless_gap = 5
beautiful.gap_single_client = true

-- Add garbage collection
gears.timer.start_new(10, function()
    collectgarbage("step", 30000)
    return true
end)

-- autostart
awful.spawn.with_shell("~/.config/awesome/autostart.sh")
