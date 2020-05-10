#!/bin/bash

# use script location as the working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

# check log file size first, if greater than 128k then delete file
filesize=$(wc -c log | cut -d' ' -f1)
if [ $filesize -gt "128000" ]; then
    rm log
fi

# log time, cpu temperature and throttle
echo "$(date)" >> log
vcgencmd measure_temp >> log
vcgencmd get_throttled >> log

# get old and new IP
oldip=$(cat lastip.txt)
echo "Old IP: $oldip" >> log
newip=$(curl http://api.ipify.org)
echo "New IP: $newip" >> log
if [[ -z $newip ]]; then
    # if newip is empty, there's a high chance that wifi is down. Re-connect
    echo "Restarting wlan0 interface..." >> log
    sudo ip link set wlan0 down >> log
    sleep 5
    sudo ip link set wlan0 up >> log
    exit 0
fi
pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
if ! [[ $newip =~ $pattern ]]; then
    # when the ipify service has problem, newip string will contain error message instead of ip
    echo "Can not get current ip. Skip." >> log
    exit 0
fi

if [ "$oldip" == "$newip" ]; then
    echo "IP has not changed." >> log
else
    echo "IP changed!" >> log
    echo $newip > lastip.txt
#    curl -X POST -H 'Content-Type: application/json' Slack-Web-Hook -d "{\"text\":\"$newip\"}"
fi
