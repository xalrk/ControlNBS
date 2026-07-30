#!/bin/bash
# This launcher.sh is a base template for you to use to customize your MIDI Controller Experience

trap 'kill $(jobs -p) 2>/dev/null' EXIT

# Function to click at certain coordinates and then move the mouse back to the initial position
# Use this to press the on screen button when the control you want doesn't have a keyboard shortcut
# click_target x y
click_target() {
    local target_x=$1
    local target_y=$2

    local location=$(kdotool getmouselocation)
    local orig_x=$(echo "$location" | grep -oP 'x:\K[0-9]+')
    local orig_y=$(echo "$location" | grep -oP 'y:\K[0-9]+')

    if [[ -z "$orig_x" || -z "$orig_y" ]]; then
        return 1
    fi

    local move_x=$((target_x - orig_x))
    local move_y=$((target_y - orig_y))
    
    local return_x=$((orig_x - target_x))
    local return_y=$((orig_y - target_y))

    ydotool mousemove -- "$move_x" "$move_y"
    sleep 0.05 # Increase this delay if clicks aren't registering in the correct spot
    
    ydotool click 0xC0
    
    ydotool mousemove -- "$return_x" "$return_y"
}


client_id=$(aseqdump -l | grep -i "$midi_controller_name" | awk '{print $1}' | cut -d: -f1 | head -n 1) # $midi_controller_name should be replaced with the name outputted from aseqdump -l

if [ -z "$client_id" ]; then
    echo "Error: MIDI Controller not found. Please ensure it is connected." >&2
    exit 1
fi

midi_port="${client_id}:$port_id" # $port_id should be replaced with the desired port (the second number in client:port)

aseqdump -p "$midi_port" | {

    while :; do
        if IFS=" ," read -t 0.05 -r src ev1 ev2 ch label1 data1 label2 data2 rest; then
            if [ "$ev1" = "Control" ] && [ "$ev2" = "change" ]; then
                case "$data1" in

                    # Put events which would be under Control change here

                    # Events should generally follow this template, with $id being the specific midi event number:
                    # Blue button for ctrl+z
                    $id)
                        ydotool key 29:1 44:1 44:0 29:0 & # Use ydotool to turn ctrl and z on and then off
                        ;;

                esac
            elif [ "$ev1" = "Note" ] && [ "$ev2" = "on" ]; then
                case "$data1" in
                    
                    # Put events that would be considered a Note here
                    
                esac
            fi
        fi
    done
} &

/path/to/Minecraft.Note.Block.Studio.appimage # Replace with the path to the .appimage of Note Block Studio