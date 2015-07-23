#!/bin/bash
##################################
# Zabbix monitoring script
#
# nginx:
#  - anything available via nginx stub-status module
#
##################################
# Contact:
# 
##################################
# ChangeLog:
#
##################################

URL="http://127.0.0.1:9876/nginx-status"
TMP_FILE="/tmp/nginx_status_zabbix_sender_file"
NUM=`whereis wget|awk '{print NF}'`
if [ $NUM -eq 1 ]
then 
    echo "there is no wget command"
    exit 2
else
    WGET=`whereis wget|awk '{print $2}'`
fi

STATUS_INFO=`${WGET} -q ${URL}  -O - `

if [ $? -ne 0 ]
then
    echo "wget error"
    exit 3
fi

active_connections=`echo ${STATUS_INFO}|awk '{print $3}'`
accepted_connections=`echo ${STATUS_INFO}|awk '{print $8}'`
handled_connections=`echo ${STATUS_INFO}|awk '{print $9}'`
handled_requests=`echo ${STATUS_INFO}|awk '{print $10}'`
reading=`echo ${STATUS_INFO}|awk '{print $12}'`
writing=`echo ${STATUS_INFO}|awk '{print $14}'`
waiting=`echo ${STATUS_INFO}|awk '{print $16}'`

AGENT_NAME=`hostname`

/bin/cat > ${TMP_FILE}<<EOF
${AGENT_NAME} ngx_active_connections ${active_connections}
${AGENT_NAME} ngx_accepted_connections ${accepted_connections}
${AGENT_NAME} ngx_handled_connections ${handled_connections}
${AGENT_NAME} ngx_handled_requests ${handled_requests}
${AGENT_NAME} ngx_reading ${reading}
${AGENT_NAME} ngx_writing ${writing}
${AGENT_NAME} ngx_waiting ${waiting}
EOF
/usr/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -i ${TMP_FILE}
