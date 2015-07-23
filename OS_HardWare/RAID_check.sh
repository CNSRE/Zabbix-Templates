#!/bin/bash

lspci=`which lspci`

mega=`sudo $lspci | grep RAID |grep -iE "lsi|symbios"  -c`
hpcli=`sudo $lspci | grep RAID |grep -iE "hewlet"  -c`

if [ $mega -eq 1 ]
then
    if [ `sudo /opt/MegaRAID/MegaCli/MegaCli64 ldinfo lall aall|grep Stat|grep -vc Optimal` -eq 0 ] && \
    [ `sudo /opt/MegaRAID/MegaCli/MegaCli64 -pdlist -a0 |grep  "Firmware state"|grep -vcE "Online|Hotspare"` -eq 0 ]
    then
        echo 0
    else
        echo 1
    fi
elif [ $hpcli -eq 1 ]
then
    array_count=`sudo /usr/sbin/hpacucli controller slot=0 logicaldrive all show|grep -c array`
    OK_count=`sudo /usr/sbin/hpacucli controller slot=0 logicaldrive all show|grep -c OK`
    if [ $array_count -eq $OK_count ]
    then
        echo 0
    else
        echo 1
    fi
fi
