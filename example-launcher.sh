#!/bin/bash
# This launcher.sh is for my specific setup with an AKAI MPK Mini IV

trap 'kill $(jobs -p) 2>/dev/null' EXIT

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
    sleep 0.05
    
    ydotool click 0xC0
    
    ydotool mousemove -- "$return_x" "$return_y"
}


client_id=$(aseqdump -l | grep -i "mpk mini" | awk '{print $1}' | cut -d: -f1 | head -n 1)

if [ -z "$client_id" ]; then
    echo "Error: MIDI Controller not found. Please ensure it is connected." >&2
    exit 1
fi

midi_port="${client_id}:1"

aseqdump -p "$midi_port" | {
    
    instrument_x=470
    pending_instrument_click=0

    while :; do
        if IFS=" ," read -t 0.05 -r src ev1 ev2 ch label1 data1 label2 data2 rest; then
            if [ "$ev1" = "Control" ] && [ "$ev2" = "change" ]; then
                case "$data1" in

                    # Clicky Knob for switching instruments
                    14)
                        if [ "$data2" -eq 1 ]; then 
                            instrument_x=$((instrument_x + 30))
                        elif [ "$data2" -eq 127 ]; then 
                            instrument_x=$((instrument_x - 30))
                            
                            if [ "$instrument_x" -lt 470 ]; then
                                instrument_x=470
                            fi
                        fi
                        
                        pending_instrument_click=1
                        ;;

                    # Smooth knob for left/right arrows
                    28)
                        if [ "$data2" -eq 1 ]; then 
                            ydotool key 106:1 106:0 &
                        elif [ "$data2" -eq 127 ]; then 
                            ydotool key 105:1 105:0 &
                        fi
                        ;;
                    
                    # Undo button for ctrl+z
                    73)
                        ydotool key 29:1 44:1 44:0 29:0 &
                        ;;

                    # Loop button for loop
                    74)
                        click_target 270 40 
                        ;;

                    # Play button for space
                    76)
                        ydotool key 57:1 57:0 &
                        ;;
                    
                    # Record button for stop
                    77)
                        click_target 155 40 
                        ;;
                    
                    # Plus button for ctrl+s
                    78)
                        ydotool key 29:1 31:1 31:0 29:0 &
                        ;;

                    # Minus Button for left 1 desktop (ctrl+super+left)
                    15)
                        if [ "$data2" -eq 127 ]; then
                            ydotool key 29:1 125:1 105:1 105:0 125:0 29:0 &
                        fi
                        ;;

                    # Plus button for right 1 desktop (ctrl+super+right)
                    16)
                        if [ "$data2" -eq 127 ]; then
                            ydotool key 29:1 125:1 106:1 106:0 125:0 29:0 &
                        fi
                        ;;
                esac
            elif [ "$ev1" = "Note" ] && [ "$ev2" = "on" ]; then
                case "$data1" in
                    
                    # Upper left pad for ctrl+e
                    55)
                        ydotool key 29:1 18:1 18:0 29:0 &
                        ;;

                    # Upper left right pad for ctrl+r
                    56)
                        ydotool key 29:1 19:1 19:0 29:0 &
                        ;;
                    
                    # Lower left pad for ctrl+d
                    48)
                        ydotool key 29:1 32:1 32:0 29:0 &
                        ;;
                    
                    # Lower left right pad for ctrl+f
                    50)
                        ydotool key 29:1 33:1 33:0 29:0 &
                        ;;

                    # Upper right left pad for ctrl+c
                    58)
                        ydotool key 29:1 46:1 46:0 29:0 &
                        ;;
                    
                    # Lower right left pad for ctrl+v
                    51)
                        ydotool key 29:1 47:1 47:0 29:0 &
                        ;;

                    # Upper right pad for delete
                    60)
                        ydotool key 111:1 111:0 &
                        ;;

                    # Lower right pad for pause/play
                    53)
                        ydotool key 57:1 57:0 &
                        ;;
                esac
            fi
        else

            exit_code=$?
            if [ $exit_code -gt 128 ]; then
                if [ "$pending_instrument_click" -eq 1 ]; then
                    click_target "$instrument_x" 40
                    pending_instrument_click=0
                fi
            else
                break
            fi
        fi
    done
} &

/home/xalrk/Applications/Minecraft.Note.Block.Studio/Minecraft.Note.Block.Studio.appimage