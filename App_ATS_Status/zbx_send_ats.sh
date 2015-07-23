#!/bin/sh

zbx_sender="/usr/bin/zabbix_sender"
zbx_conf="/etc/zabbix/zabbix_agentd.conf"
hostname=`hostname`" "
traffic_line=/usr/bin/traffic_line
zbx_file=/tmp/ats_stats_tmp
>${zbx_file}
while read line
do
    result=`${traffic_line} -r ${line}`
    echo ${hostname} ${line} ${result} >> ${zbx_file}
done < ./ats_vars
${zbx_sender} -c ${zbx_conf} -i ${zbx_file}
