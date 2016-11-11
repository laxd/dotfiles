#!/usr/bin/env bash
icon=$HOME/.config/i3/lock.png
text="Locked"
scale=10

blur() {
    transformation="$transformation -blur 0x$(($scale)) "
}

pixelate() {
    transformation="$transformation -scale $((100/scale))% -scale $((100*scale))% "
}

lock() {
    image=$1
    if [[ -f $icon ]]
    then
        # get lockscreen image info
        R=$(identify $icon | grep -o ' [0-9]*x[0-9]* ')
        icon_X=$(echo $R | cut -d'x' -f 1)
        icon_Y=$(echo $R | cut -d'x' -f 2)

        # Get attached monitor resolutions and offsets
        # in 1920x1080 @ 0,0 format
        screens=$(xdpyinfo -ext XINERAMA | sed -n 's/^  head #[0-9]*: //p')

        locks=""

        # For each monitor, find the resolution and offset and
        # calculate the location of the lock icon.
        IFS=$'\n'
        for screen in $screens
        do
            IFS=' x@,' read X Y dX dY <<< $screen

            PX=$(($dX + $X/2 - $icon_X/2))
            PY=$(($dY + $Y/2 - $icon_Y/2))

            locks="$locks $icon -geometry +$PX+$PY -composite"
        done
        # TODO: Add Text

    fi

    unset IFS

    lockscreen=$(mktemp $dir/tmpXXXXXXXXXX.png)
    echo "convert $image $transformation $locks $lockscreen"
    convert $image $transformation $locks $lockscreen

    i3lock -i $lockscreen -t
}

usage() {
    echo "\
Usage: $0 [-hpb] [-s scale] [-o icon] [-t text]
            
-h, --help
    Show this help message

-s <scale>, --scale <scale>
    Scale the blur/pixelation of the lock screen. Higher values indicate more blur/pixelation, default 10

-o <file>, --overlay <file>
    File to overlay on to the lock screen, default $HOME/.config/i3/lock.jpg

-t <text>, --text <text>
    Text to overlay on the lock screen, default "Locked"

-p, --pixelate
    Pixelate current desktop, takes precendence over --blur

-b, --blur
    Blur current desktop, is overridden by --pixelate"
}

main() {
    while (( $# )); do
        case "$1" in
            --help|-h) usage; exit 0;;
            --scale|-s) scale=$2; shift;;
            --overlay|-o) icon=$2; shift;;
            --image|-i) image=$2; shift;;
            --text|-t) text=$2; shift;;
            --pixelate|-p) f_pixelate=1; shift;;
            --blur|-b) f_blur=1; shift;;
            *) break;;
        esac
    done

    dir=$(mktemp --tmpdir tmpXXXXXXXXXXX -d)
    trap 'rm -rf "$dir"' EXIT

    # image modification should only happen
    # after all options have been set e.g. scale
    if [[ $f_pixelate -eq 1 ]]; then
        pixelate
    elif [[ $f_blur -eq 1 ]]; then
        blur
    fi
  
    if [[ -z $image ]]; then
        image=$(mktemp $dir/tmpXXXXXXXXXX.jpeg)
        scrot $image
    fi

    lock $image
}

main "$@"
