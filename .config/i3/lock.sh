#!/bin/bash
LOCK_SCREEN=/tmp/screenshot.png
ICON=$HOME/.config/i3/lock.png

scrot $LOCK_SCREEN

if [[ -f $ICON ]]
then
    # lockscreen image info
    R=$(file $ICON | grep -o '[0-9]* x [0-9]*')
    ICON_X=$(echo $R | cut -d' ' -f 1)
    ICON_Y=$(echo $R | cut -d' ' -f 3)

    SCREENS=$(xdpyinfo -ext XINERAMA | sed -n 's/^  head #[0-9]*: //p')

    LOCKS=""
    IFS=$'\n'
    for SCREEN in $SCREENS
    do
        IFS=' x@,' read X Y dX dY <<< $SCREEN

        PX=$(($dX + $X/2 - $ICON_X/2))
        PY=$(($dY + $Y/2 - $ICON_Y/2))

        LOCKS="$LOCKS $ICON -geometry +$PX+$PY -composite"
    done

    unset IFS

    convert $LOCK_SCREEN -scale 10% -scale 1000% $LOCKS $LOCK_SCREEN
fi

i3lock -i $LOCK_SCREEN
rm $LOCK_SCREEN
