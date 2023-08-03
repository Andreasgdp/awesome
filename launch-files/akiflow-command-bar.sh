#!/bin/bash


# Get window id of akiflow window with name "Akiflow" and class "Google-Chrome"
akiflow_window_id=$(comm -12 \
  <(xdotool search --name  'Akiflow'  | sort) \
  <(xdotool search --class 'Google-Chrome'  | sort))


# If window not open, open it with google-chrome-stable --app=https://web.akiflow.com/#/planner/today and make sure to wait for it to load before focusing it and opening command bar
if [ -z "$akiflow_window_id" ]; then
    google-chrome-stable --app="https://web.akiflow.com/#/planner/today"
    sleep 3
    akiflow_window_id=$(comm -12 \
      <(xdotool search --name  'Akiflow'  | sort) \
      <(xdotool search --class 'Google-Chrome'  | sort))
fi

# Focus akiflow window
xdotool windowactivate $akiflow_window_id

# Wait for window to be focused
sleep 0.1

# Open command bar with ctrl+k in akiflow window
xdotool key --window $akiflow_window_id ctrl+k