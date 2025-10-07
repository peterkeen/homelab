#!/bin/sh

# https://github.com/bugst/go-serial/blob/master/enumerator/usb_linux.go#L36

set -e
set -x

ttys=$(ls /sys/class/tty | egrep '(ttyS|ttyHS|ttyUSB|ttyACM|ttyAMA|rfcomm|ttyO|ttymxc)[0-9]{1,3}')

for tty in $ttys; do
    realDevice=$(readlink -f /sys/class/tty/$tty/device)
    subsystem=$(basename $(readlink -f $realDevice/subsystem))

    usbdir=""

    if [[ "$subsystem" == "usb-serial" ]]; then
        usbdir=$(dirname $(dirname $realDevice))
    elif [[ "$subsystem" == "usb" ]]; then
        usbdir=$(dirname $realDevice)
    else
        continue
    fi

    productId=$(cat $usbdir/idProduct)
    vendorId=$(cat $usbdir/idVendor)

    echo "$vendorId:$productId /dev/$tty"

    snippetFile="$vendorId:$productId.yaml"

    if [[ -f "$snippetFile" ]]; then
        echo $snippetFile
        sed "s/DEVNODE/\/dev\/$tty/" $snippetFile
    fi
done
