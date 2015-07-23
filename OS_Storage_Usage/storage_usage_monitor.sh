#!/bin/bash 
df -lm  |grep 'weibo_img'|awk '
    BEGIN{
        total=0;
        free=0;
        used=0;
        pfree=0;
        ("hostname" | getline hostname);
    }{
        total+=$2;
        used+=$3
        free+=$4;
    }END{
        print hostname,"storage_usage_total",total/1024/1024;
        print hostname,"storage_usage_used",used/1024/1024;
        print hostname,"storage_usage_free",free/1024/1024;
        print hostname,"storage_usage_pused",100*used/total;
        print hostname,"storage_usage_pfree",100*free/total;}'>/tmp/.storage_usage_monitor
/usr/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -i /tmp/.storage_usage_monitor 
