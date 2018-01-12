#!/bin/bash
# Script that tries to connect to google.com 
curl -s --connect-timeout 52 http://google.com  > /dev/null
if [[ $? != 0 ]]; then
    echo "Internet connection seems down, restarting device"
    # Reset USB
    echo 0 > /sys/devices/platform/soc/3f980000.usb/buspower;
    sleep 5
    echo 1 > /sys/devices/platform/soc/3f980000.usb/buspower;
    sleep 5
    # Resin SUPERVISOR call to reboot the device
    curl -X POST --header "Content-Type:application/json" "$RESIN_SUPERVISOR_ADDRESS/v1/reboot?apikey=$RESIN_SUPERVISOR_API_KEY"
else
	echo "Internet connection is working"
fi
